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
#import <dlfcn.h>
#import "JXRuntimeInterface.h"
#import "JXStruct.h"
#import "JXSymbol.h"
#import "JXJSInterop.h"
#import "JXBlockInterop.h"
#import "JXAssociatedObjects.h"
#import "JXType+FFI.h"
#import "JXPointer.h"

@interface NSInvocation (Hax)

- (void)invokeUsingIMP:(IMP)imp;

@end

static JSClassRef JXGlobalClass;
static JSClassRef JXMethodClass;
static JSClassRef JXFunctionClass;
JSClassRef JXObjectClass;
JSClassRef JXAutoreleasingObjectClass;

// iterate through the methods of JS dict `obj`
static void iterateMethods(JSValue *dict, void (^iter)(JSValue *func, BOOL isClassMethod, SEL sel, NSString *sig)) {
	// .context returns the JSContext of the JSValue
	NSArray *methodNames = JXKeysOfDict(dict);
	// Loop through all names
	for (NSString *methodName in methodNames) {
		// Get the func associated with methodName
		JSValue *func = dict[methodName];
		
		// eg. v@:-viewDidload will result in isClassMethod=NO, components=["v@:", "viewDidLoad"]
		BOOL isClassMethod = [methodName containsString:@"+"];
		NSArray<NSString *> *components = [methodName componentsSeparatedByString:(isClassMethod ? @"+" : @"-")];
		NSString *sig = components[0];
		NSString *methodName = components[1];
		
		SEL sel = NSSelectorFromString(methodName);
		iter(func, isClassMethod, sel, sig);
	}
}

static NSString *stringFromJSStringRef(JSStringRef ref) {
	CFStringRef cfName = JSStringCopyCFString(kCFAllocatorDefault, ref);
	return (__bridge_transfer NSString *)cfName;
}

static JSContext *contextFromJSContextRef(JSContextRef ref) {
	JSGlobalContextRef global = JSContextGetGlobalContext(ref);
	return [JSContext contextWithJSGlobalContextRef:global];
}

// TODO: Fix ivar memory management (allow different OBJC_ASSOCIATIONs)

// Intercept global getProperty calls to return a class with the name propertyName if there isn't an object by the same name
static JSValueRef globalGetProperty(JSContextRef ctxRef, JSObjectRef object, JSStringRef propertyNameJS, JSValueRef *exception) {
	NSString *propertyName = stringFromJSStringRef(propertyNameJS);
	
	// Skip any blacklisted properties to let JS handle them by returning NULL
	// self is blacklisted to avoid unwanted recursion due to the currSelfJS statement below
	NSArray<NSString *> *blacklist = @[@"Object", @"self", @"JXPointer"];
	if ([blacklist containsObject:propertyName]) return NULL;

	JX_DEBUG(@"Searching for class %@", propertyName);
	
	JSContext *ctx = contextFromJSContextRef(ctxRef);
	JSValue *currSelfJS = ctx[@"self"];
	id currSelf = JXObjectFromJSValue(currSelfJS);
	// can't check for currSelfJS.isUndefined because that's true when using JXObject
	if (currSelf) {
		id obj = JXGetAssociatedObject(propertyName, currSelf);
		if (obj) return JXObjectToJSValue(obj, ctx).JSValueRef;
	}
	
	// Otherwise return the ObjC class named propertyName (if any)
	Class cls = NSClassFromString(propertyName);
	if (!cls) return NULL;
	return JXObjectToJSValue(cls, ctx).JSValueRef;
}

static bool globalSetProperty(JSContextRef ctxRef, JSObjectRef object, JSStringRef propertyNameJS,
							  JSValueRef valueRef, JSValueRef *exception) {
	NSString *propertyName = stringFromJSStringRef(propertyNameJS);
	
	// Skip any blacklisted properties to let JS handle them by returning NULL
	NSArray<NSString *> *blacklist = @[@"Object"];
	if ([blacklist containsObject:propertyName]) return false;
	
	JSContext *ctx = contextFromJSContextRef(ctxRef);
	JSValue *currSelfJS = ctx[@"self"];
	if (currSelfJS.isUndefined) return false;
	JSValue *valueJS = [JSValue valueWithJSValueRef:valueRef inContext:ctx];
	// otherwise treat propertyName as an ivar on currentSelf
	id currSelf = JXObjectFromJSValue(currSelfJS);
	id value = JXObjectFromJSValue(valueJS);
	return JXSetAssociatedObject(propertyName, currSelf, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// Returns a JXMethodClass that holds the selector that was specified as propertyName
// When JXMethodClass is called as a function, it passes the selector, `this` (i.e. the JXObjectClass), and arguments to msgSend
static JSValueRef objectGetProperty(JSContextRef ctxRef, JSObjectRef object, JSStringRef propertyNameJS, JSValueRef *exception) {
	NSString *propertyName = stringFromJSStringRef(propertyNameJS);
	
	id __unsafe_unretained private = (__bridge id __unsafe_unretained)JSObjectGetPrivate(object);
    // if the object implements custom JS KVC behaviour (eg a JXStruct for withType), forward the request to it
    if ([private conformsToProtocol:@protocol(JXKVC)]) {
        JSContext *ctx = contextFromJSContextRef(ctxRef);
        JSValue *val = [private jsPropertyForKey:propertyName ctx:ctx];
        if (val) return val.JSValueRef;
        else return [JSValue valueWithUndefinedInContext:ctx].JSValueRef;
    }
	
	return JSObjectMake(ctxRef, JXMethodClass, (__bridge_retained void *)propertyName);
}

static bool objectSetProperty(JSContextRef ctxRef, JSObjectRef object, JSStringRef propertyNameJS,
                              JSValueRef valueRef, JSValueRef *exception) {
    NSString *propertyName = stringFromJSStringRef(propertyNameJS);

    id __unsafe_unretained private = (__bridge id __unsafe_unretained)JSObjectGetPrivate(object);
    if ([private conformsToProtocol:@protocol(JXKVC)] && [private respondsToSelector:@selector(setJSProperty:forKey:ctx:)]) {
        JSContext *ctx = contextFromJSContextRef(ctxRef);
        JSValue *property = [JSValue valueWithJSValueRef:valueRef inContext:ctx];
        [private setJSProperty:property forKey:propertyName ctx:ctx];
        return true;
    }

    return false;
}

static void releasePrivate(JSObjectRef object) {
	// We can't retrieve objects directly during finalize, so get the
	// private val of the object and then call dealloc later, on the main queue
	// TODO: Figure out if this causes any threading issues
	void *private = JSObjectGetPrivate(object);
	JX_DEBUG(@"Releasing %@", (__bridge id)private);
	dispatch_async(dispatch_get_main_queue(), ^{
		CFRelease(private);
	});
}

static JSValueRef methodCall(JSContextRef jsCtx, JSObjectRef function, JSObjectRef objRef,
						  size_t argumentCount, const JSValueRef arguments[], JSValueRef *exception) {
    // cleans up selector name, and then calls JXCallMethod

	JSContext *ctx = contextFromJSContextRef(jsCtx);

	JSValue *objJS = [JSValue valueWithJSValueRef:objRef inContext:ctx];
	id obj = JXObjectFromJSValue(objJS);
	
	NSString *selName = (__bridge id)JSObjectGetPrivate(function);

	JSValue *args = [JSValue valueWithNewArrayInContext:ctx];
	for (size_t i = 0; i < argumentCount; i++) {
		args[i] = [JSValue valueWithJSValueRef:arguments[i] inContext:ctx];
	}
	
	BOOL isSuper = NO;
	if ([selName hasPrefix:@"^"]) {
		selName = [selName substringFromIndex:1];
		isSuper = YES;
	}
	
	// TODO: Add varargs support if possible (although even Swift-ObjC interop doesn't have it)
	
	size_t implicitArgs = argumentCount; // the number of trailing colons to add
	// decrement the number of implicit colons every time we see one explicitly added
	for (int i = 0; i < [selName lengthOfBytesUsingEncoding:NSUTF8StringEncoding]; i++) {
		if ([selName characterAtIndex:i] == ':') implicitArgs--;
	}
	// add the final num of implicit colons to the end
	selName = [selName stringByPaddingToLength:selName.length+implicitArgs withString:@":" startingAtIndex:0];
	
	Class cls = isSuper ? [NSClassFromString([ctx[@"clsName"] toString]) superclass] : [obj class];
	
	JSValue *jsVal;
	@try {
		jsVal = JXCallMethod(cls, ctx, obj, selName, args);
	} @catch (NSException *e) {
		*exception = JXConvertToError(e, ctx).JSValueRef;
	}
	return jsVal.JSValueRef;
}

static JSValueRef functionCall(JSContextRef ctxRef, JSObjectRef function, JSObjectRef objRef,
							   size_t nargs, const JSValueRef arguments[], JSValueRef *exception) {
	JSContext *ctx = contextFromJSContextRef(ctxRef);
	
	JXSymbol *private = (__bridge id)JSObjectGetPrivate(function);
	
	return JXCallFunction(private.symbol, private.types, (uint32_t)nargs, arguments, ctx).JSValueRef;
}

static JSClassRef createClass(const char *name, void (^configure)(JSClassDefinition *)) {
	JSClassDefinition def = kJSClassDefinitionEmpty;
	def.className = name;
	configure(&def);
	return JSClassCreate(&def);
}

static void setup() {
	// https://code.google.com/archive/p/jscocoa/wikis/JavascriptCore.wiki
	JXGlobalClass = createClass("OBJS", ^(JSClassDefinition *def) {
		def->getProperty = globalGetProperty;
		def->setProperty = globalSetProperty;
	});
	
	JXMethodClass = createClass("JXMethod", ^(JSClassDefinition *def) {
		def->callAsFunction = methodCall;
		def->finalize = releasePrivate;
	});
	
	JXFunctionClass = createClass("JXFunction", ^(JSClassDefinition *def) {
		def->callAsFunction = functionCall;
		def->finalize = releasePrivate;
	});
	
	JXObjectClass = createClass("JXObject", ^(JSClassDefinition *def) {
		def->getProperty = objectGetProperty;
        def->setProperty = objectSetProperty;
	});
	
	JXAutoreleasingObjectClass = createClass("JXAutoreleasingObject", ^(JSClassDefinition *def) {
		def->parentClass = JXObjectClass;
		def->finalize = releasePrivate;
	});
}

static void configureContext(JSContext *ctx) {
	ctx.exceptionHandler = ^(JSContext *ctx, JSValue *error) {
		JXThrow(JXConvertFromError(error));
	};
	
	// For logging messages
	ctx[@"NSLog"] = ^(JSValue *msg) {
		NSLog(@"%@", [msg toString]);
	};
	
	// Create the JS method hookClass(name: String, hooks: { String : Function })
	ctx[@"hookClass"] = ^(NSString *clsName, NSDictionary<NSString *, NSString *> *associatedObjects, JSValue *hooks) {
		Class cls = NSClassFromString(clsName);
		JXRegisterAssociatedObjects(associatedObjects, clsName);
		@try {
			iterateMethods(hooks, ^(JSValue *func, BOOL isClassMethod, SEL sel, NSString *sig) {
				JXSwizzle(func, cls, isClassMethod, sel, sig);
			});
		} @catch (NSException *e) {
			JSContext *ctx = [JSContext currentContext];
			ctx.exception = JXConvertToError(e, ctx);
		}
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
		
		// Add methods
		iterateMethods(methods, ^(JSValue *func, BOOL isClassMethod, SEL sel, NSString *sig) {
			const char *types = sig.UTF8String;
			JXTrampInfo *info = JXCreateTramp(func, types, cls);
			[info retainForever];
			class_addMethod(cls, sel, info.tramp, types);
		});
		
		// Register class
		objc_registerClassPair(cls);
		
		// Register associated objects
		JXRegisterAssociatedObjects(associatedObjects, clsName);
	};
	
	ctx[@"defineBlock"] = ^JSValue *(NSString *sig, JSValue *func) {
		return JXCreateBlock(sig, func);
	};
	
	ctx[@"box"] = ^JSValue *(JSValue *val) {
		// takes advantage of the fact that JXObjectFromJSValue deep-converts native JS types
		id obj = JXObjectFromJSValue(val);
		// once the type has been turned into its objc counterpart, simply wrap
		return JXObjectToJSValue(obj, [JSContext currentContext]);
	};
	
	ctx[@"unbox"] = ^JSValue *(JSValue *val) {
		id obj = JXObjectFromJSValue(val);
		return JXUnboxValue(obj, [JSContext currentContext]);
	};
	
	ctx[@"loadFunc"] = ^JSValue *(NSString *name, NSString *types, BOOL returnOnly, JSValue *library) {
		JSContext *ctx = [JSContext currentContext];
		JSContextRef ctxRef = ctx.JSGlobalContextRef;
		
#define raiseExceptionIfNULL(val) if (!val) { \
	NSException *e = JXCreateException(@(dlerror())); \
	ctx.exception = JXConvertToError(e, ctx); \
	return [JSValue valueWithUndefinedInContext:ctx]; \
}

		void *handle;
		if (library.isString) {
			const char *path = [library toString].UTF8String;
			// only allow the executable to be searched via `handle` (RTLD_LOCAL),
			// and when searching don't check other images (RTLD_FIRST)
			handle = dlopen(path, RTLD_LOCAL | RTLD_FIRST);
			raiseExceptionIfNULL(handle)
		} else {
			handle = RTLD_DEFAULT;
		}
		
		void *sym = dlsym(handle, name.UTF8String);
		raiseExceptionIfNULL(sym)
		
#undef raiseExceptionIfNULL
		
		JXSymbol *symbol = [[JXSymbol alloc] initWithSymbol:sym types:types];
		JSObjectRef obj = JSObjectMake(ctxRef, JXFunctionClass, (__bridge_retained void *)symbol);
		
		JSValue *func = [JSValue valueWithJSValueRef:obj inContext:ctx];
		if (!returnOnly) ctx[name] = func;
		return func;
	};

    ctx[@"Pointer"] = ^JSValue *(NSString *enc) {
        // equivalent to loadFunc("malloc", "^vQ", false)(loadFunc("JXSizeForEncoding", "Q*", false)(enc)).withType(enc);
        void *ptr = malloc(JXSizeForEncoding(enc.UTF8String));
        const char *fullType = [@"^" stringByAppendingString:enc].UTF8String;
        return JXConvertToJSValue(&ptr, fullType, [JSContext currentContext], JXInteropOptionRetain | JXInteropOptionAutorelease);
    };

}

// non-static so that it can be tested
JSContext *JXCreateContext() {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{ setup(); });
	
	JSGlobalContextRef ctxRef = JSGlobalContextCreate(JXGlobalClass);
	JSContext *ctx = [JSContext contextWithJSGlobalContextRef:ctxRef];
	// ctx retains ctxRef, so we can release our ownership
	JSGlobalContextRelease(ctxRef);
	
	configureContext(ctx);
	
	return ctx;
}

void JXRunScript(NSString *script, NSString *resourcesPath) {
	JSContext *ctx = JXCreateContext();
	ctx[@"resourcesPath"] = JXObjectToJSValue(resourcesPath, ctx);
	[ctx evaluateScript:script];
}

