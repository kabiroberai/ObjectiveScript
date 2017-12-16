//
//  Hooking.m
//  FFITesting
//
//  Created by Kabir Oberai on 13/12/17.
//  Copyright © 2017 Kabir Oberai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <objc/runtime.h>
#import "JXFFIInterface.h"
#import "JXJSInterop.h"

@interface NSInvocation (Hax)

- (void)invokeUsingIMP:(IMP)imp;

@end

// [class : [ivar : key]]
static NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, NSString *> *> *allAssociatedObjects;

// Loop through the passed in args array and call `block` with each element, bridged to objc
static void parseJSArgs(JSValue *args, NSMethodSignature *sig, void (^block)(int, void *)) {
	if ([args isUndefined]) return;
	int length = [args[@"length"] toUInt32];
	for (int i = 0; i < length; i++) {
		JSValue *arg = [args objectAtIndexedSubscript:i];
		const char *type = [sig getArgumentTypeAtIndex:2+i];
		JXConvertFromJSValue(arg, type, ^(void *ptr) {
			// Pass in 2+i because each JSValue arg corresponds to the
			// actual arg 2 indices further down (as 0 & 1 are self & _cmd)
			block(2+i, ptr);
		});
	}
}

// Note: ret is lazily evaluated (i.e. if the ret val is void then it's not called)
static JSValue *parseRet(NSMethodSignature *sig, JSContext *ctx, BOOL transferOwnership, void *(^ret)(void)) {
	// If return type is void, return undefined
	const char *returnType = sig.methodReturnType;
	if (is(returnType, void)) return [JSValue valueWithUndefinedInContext:ctx];
	
	// Otherwise return a JSValue-wrapped ret
	return _JXConvertToJSValue(ret(), returnType, ctx, transferOwnership);
}

// iterate through the methods of JS dict `obj`
static void iterateMethods(JSValue *dict, void (^iter)(JSValue *func, BOOL isClassMethod, SEL sel, NSString *sig)) {
	// .context returns the JSContext of the JSValue
	NSArray *methodNames = [[dict.context[@"Object"][@"keys"] callWithArguments:@[dict]] toArray];
	// Loop through all names
	for (NSString *methodName in methodNames) {
		// Get the func associated with methodName
		JSValue *func = dict[methodName];
		
		// eg. v@:-viewDidload will result in isClassMethod=NO, components=["v@:", "viewDidLoad"]
		BOOL isClassMethod = [methodName containsString:@"+"];
		NSArray<NSString *> *components = [methodName componentsSeparatedByString:(isClassMethod ? @"+" : @"-")];
		NSString *methodName;
		NSString *sig = nil;
		if (components.count == 1) { // no method signature (eg. -viewDidLoad)
			methodName = components[0];
		} else { // has method signature at start (eg. v@:-viewDidLoad)
			sig = components[0];
			methodName = components[1];
		}
		
		SEL sel = NSSelectorFromString(methodName);
		iter(func, isClassMethod, sel, sig);
	}
}

static void registerAssociatedObjects(NSDictionary<NSString *, NSString *> *associatedObjects, NSString *clsName) {
	// Add associated object keys
	// Get the existing keys for this class
	NSMutableDictionary *dict = allAssociatedObjects[clsName];
	if (!dict) {
		dict = [NSMutableDictionary new];
		allAssociatedObjects[clsName] = dict;
	}
	[dict addEntriesFromDictionary:associatedObjects];
}

// Use a single VM to support concurrency
static JSVirtualMachine *vm;

JSContext *JXCreateContext(void) {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		vm = [[JSVirtualMachine alloc] init];
		allAssociatedObjects = [NSMutableDictionary new];
	});
	
	JSContext *ctx = [[JSContext alloc] initWithVirtualMachine:vm];
	ctx.exceptionHandler = ^(JSContext *ctx, JSValue *exception) {
		NSLog(@"%@", exception);
	};
	
	// For logging messages
	ctx[@"NSLog"] = ^(JSValue *msg) {
		NSLog(@"%@", JXObjectFromJSValue(msg));
	};
	
	// Create a weak reference to ctx for use in the block
	__weak JSContext *weakCtx = ctx;
	
	// Create the JS method hookClass(name: String, hooks: { String : Function })
	ctx[@"hookClass"] = ^(NSString *clsName, NSDictionary<NSString *, NSString *> *associatedObjects, JSValue *hooks) {
		Class cls = NSClassFromString(clsName);
		registerAssociatedObjects(associatedObjects, clsName);
		iterateMethods(hooks, ^(JSValue *func, BOOL isClassMethod, SEL sel, NSString *nilTypeSig) {
			// (nilTypeSig will always be `nil`, so ignore it)
			
			// Get the method signature for interop to/from JSValue
			NSMethodSignature *sig;
			if (isClassMethod) {
				sig = [cls methodSignatureForSelector:sel];
			} else {
				sig = [cls instanceMethodSignatureForSelector:sel];
			}
			
			JXSwizzle(cls, isClassMethod, sel, ^(ffi_cif *cif, void *ret, void **args, OrigBlock orig) {
				// First arg is self
				id self = *(__unsafe_unretained id *)args[0];
				
				// Create a function that JS can call, to call the original method
				id origJS = ^JSValue *(JSValue *argsJS) {
					// Parse the args passed into origJS and populate the args array accordingly
					parseJSArgs(argsJS, sig, ^(int i, void *val) {
						memcpy(args[i], val, cif->arg_types[i]->size);
					});
					
					// Call orig to and return a bridged return value
					return parseRet(sig, weakCtx, NO, orig);
				};
				
				// Construct an array of JSValue arguments to pass to the JS method,
				// based on the original arguments passed by the callee
				NSUInteger argc = sig.numberOfArguments;
				NSMutableArray<JSValue *> *methodArgs = [NSMutableArray arrayWithCapacity:argc];
				// first arg is the origJS function that we just made
				methodArgs[0] = [JSValue valueWithObject:origJS inContext:weakCtx];
				// second is self
				methodArgs[1] = [JSValue valueWithObject:self inContext:weakCtx];
				// the rest are the same as the original args that the method was called with
				for (int i = 2; i < argc; i++) {
					const char *type = [sig getArgumentTypeAtIndex:i];
					methodArgs[i] = JXConvertToJSValue(args[i], type, weakCtx);
				}
				
				// Call the method and get the modified return value
				JSValue *jsRet = [func callWithArguments:methodArgs];
				
				// Set the original invocation's return to the modified return
				JXConvertFromJSValue(jsRet, sig.methodReturnType, ^(void *val) {
					memcpy(ret, val, cif->rtype->size);
				});
			});
		});
	};
	
	ctx[@"defineClass"] = ^(NSString *clsName, NSString *superclsName,
							NSArray<NSString *> *protoList, NSDictionary<NSString *, NSString *> *associatedObjects,
							JSValue *methods) {
		// Allocate class
		Class superclass = NSClassFromString(superclsName);
		Class cls = objc_allocateClassPair(superclass, clsName.UTF8String, 0);
		
		// Add protocols
		for (NSString *proto in protoList) {
			Protocol *protocol = objc_getProtocol(proto.UTF8String);
			class_addProtocol(cls, protocol);
		}
		
		// Register associated objects
		registerAssociatedObjects(associatedObjects, clsName);
		
		// Add methods
		iterateMethods(methods, ^(JSValue *func, BOOL isClassMethod, SEL sel, NSString *sig) {
			const char *types = sig.UTF8String;
			IMP imp = JXCreateImpFromJS(func, types);
			class_addMethod(cls, sel, imp, types);
		});
		
		// Register class
		objc_registerClassPair(cls);
	};
	
	ctx[@"_msgSend"] = ^JSValue *(BOOL callSuper, JSValue *jsObj, NSString *selName, JSValue *args) {
		// Get the info required to construct an NSInvocation
		id obj = JXObjectFromJSValue(jsObj);
		SEL sel = NSSelectorFromString(selName);
		if (!sel || !obj) return [JSValue valueWithUndefinedInContext:weakCtx];
		NSMethodSignature *sig = [obj methodSignatureForSelector:sel];
		NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
		inv.target = obj;
		
		// Set the args of the NSInvocation to the passed in ones
		parseJSArgs(args, sig, ^(int i, void *val) {
			[inv setArgument:val atIndex:i];
		});
		
		// Handle `super` calls separately (start method search from superclass)
		if (callSuper) {
			// Get the superclass' implementation for the method
			Method m = (object_isClass(obj) ? class_getClassMethod : class_getInstanceMethod)([obj superclass], sel);
			IMP imp = method_getImplementation(m);
			// Invoke inv using that imp
			[inv invokeUsingIMP:imp];
		} else {
			// Otherwise, invoke using the regular imp
			inv.selector = sel;
			[inv invoke];
		}
		
		void *ret = malloc(sig.methodReturnLength);
		
		// https://github.com/bang590/JSPatch/wiki/How-JSPatch-works#ii-memery-leak (sic)
		// (not sure exactly what this does, might have to figure out if it actually works)
		BOOL transferOwnership =
		[selName isEqualToString:@"alloc"] ||
		[selName isEqualToString:@"new"] ||
		[selName isEqualToString:@"copy"] ||
		[selName isEqualToString:@"mutableCopy"];
		
		JSValue *parsed = parseRet(sig, weakCtx, transferOwnership, ^void * {
			[inv getReturnValue:ret];
			return ret;
		});
		
		free(ret);
		
		return parsed;
	};
	
	ctx[@"cls"] = ^id(NSString *cls) {
		return NSClassFromString(cls);
	};
	
	ctx[@"associatedObject"] = ^JSValue *(id obj, NSString *name, /* optional */ JSValue *value) {
		NSString *type = allAssociatedObjects[NSStringFromClass([obj class])][name];
		const void *key = (__bridge const void *)type;
		if (!value.isUndefined) {
			// If `ivar` is called with `value`, then set the associated object
			objc_setAssociatedObject(obj, key, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
			return [JSValue valueWithUndefinedInContext:weakCtx];
		} else {
			// If called without `value`, return the value of the ivar
			return objc_getAssociatedObject(obj, key);
		}
		// Note: associated objects are stored directly as JSValues, because
		// there isn't much point in converting them back and forth
	};
	
	[ctx evaluateScript:@"msgSend=(obj,sel,...args)=>_msgSend(false,obj,sel,args)"];
	[ctx evaluateScript:@"msgSendSuper=(obj,sel,...args)=>_msgSend(true,obj,sel,args)"];
	
	return ctx;
}
