//
//  JXRuntimeInterface.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 19/11/17.
//  Copyright © 2017 Kabir Oberai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import "JXTrampInfo.h"
#import "JXJSInterop.h"
#import "JXRuntimeInterface.h"
#import "JXFFITypes.h"
#import "Block.h"

@interface NSInvocation (hacks)
- (void)invokeUsingIMP:(IMP)imp;
@end

// Push callContext onto ctx like a stack, call `block`, and then pop them
static void withCallContext(NSDictionary *items, JSContext *ctx, void (^block)(void)) {
	NSMutableDictionary<NSString *, JSValue *> *oldItems = [NSMutableDictionary dictionaryWithCapacity:items.count];
	// Push callContext onto stack, saving old values
	for (NSString *key in items) {
		oldItems[key] = ctx[key];
		ctx[key] = items[key];
	}
	// Call block
	block();
	// Pop newly placed items from stack
	for (NSString *key in items) {
		ctx[key] = oldItems[key];
	}
}

static JSValue *callFunc(JSValue *func, id self, Class cls, id orig, NSMutableArray<JSValue *> *methodArgs) {
	JSContext *ctx = func.context;
	JSValue *selfJS = JXConvertToJSValue(&self, @encode(id), ctx, JXMemoryModeNone);
	
#define COALESCE(val) ((val) ? : [NSNull null])
	
	NSString *clsName = cls ? NSStringFromClass(cls) : nil;
	
	NSDictionary *callContext = @{
		@"self"    : COALESCE(selfJS),
		@"orig"    : COALESCE(orig),
		@"clsName" : COALESCE(clsName)
	};
	
	__block JSValue *ret;
	withCallContext(callContext, ctx, ^{
		ret = [func callWithArguments:methodArgs];
	});
	
	return ret;
}

// Loop through the passed in args array and call `block` with each element, bridged to objc
static void parseArgs(JSValue *args, NSMethodSignature *sig, void (^block)(int, void *)) {
	if (args.isUndefined) return;
	int length = [args[@"length"] toUInt32];
	for (int i = 0; i < length; i++) {
		JSValue *arg = args[i];
		const char *type = [sig getArgumentTypeAtIndex:2+i];
		JXConvertFromJSValue(arg, type, ^(void *ptr) {
			// Pass in 2+i because each JSValue arg corresponds to the
			// actual arg 2 indices further down (as 0 & 1 are self & _cmd)
			block(2+i, ptr);
		});
	}
}

// cls indicates the class from which the method search should start
JSValue *JXMsgSend(Class cls, JSContext *ctx, id obj, NSString *selName, JSValue *args) {
	JX_DEBUG(@"Method %@ is being called on %@", selName, obj);
	
	if ([selName isEqualToString:@"Symbol.toPrimitive:"]) { // called by JS during type coercion
//		NSString *hint = [args[0] toString]; // number, string, or default
		return [JSValue valueWithObject:[obj description] inContext:ctx];
	}
	
	SEL sel = NSSelectorFromString(selName);
	if (!sel || !obj) return [JSValue valueWithUndefinedInContext:ctx];
	NSMethodSignature *sig = [obj methodSignatureForSelector:sel];
	if (!sig) return [JSValue valueWithUndefinedInContext:ctx];
	NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
	inv.target = obj;
	inv.selector = sel;
	
	// Set the args of the NSInvocation to the passed in ones
	parseArgs(args, sig, ^(int i, void *val) {
		[inv setArgument:val atIndex:i];
	});
	
	IMP imp;
	if (object_isClass(obj)) {
		Method m = class_getClassMethod(cls, sel);
		imp = method_getImplementation(m);
	} else {
		// faster than method_getImplementation(class_getInstanceMethod(cls, sel))
		imp = class_getMethodImplementation(cls, sel);
	}
	
	// invoke the imp corresponding with the method
	[inv invokeUsingIMP:imp];
	
	// https://github.com/bang590/JSPatch/wiki/How-JSPatch-works#ii-memery-leak (sic)
	// http://clang.llvm.org/docs/AutomaticReferenceCounting.html#method-families
	NSArray<NSString *> *transferOwnershipSels = @[@"alloc", @"new", @"copy", @"mutableCopy"];
	// remove leading underscores. trailing underscores won't affect this so there's no harm in removing them too.
	NSString *sanitisedSel = [selName stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"_"]];
	BOOL transferOwnership = NO;
	for (NSString *testSel in transferOwnershipSels) {
		// if sanitisedSel begins with testSel
		// and
		//    the two are exactly equal
		//    or
		//    the next character is special or uppercase
		if ([sanitisedSel hasPrefix:testSel] && (sanitisedSel.length == testSel.length || ![NSCharacterSet.lowercaseLetterCharacterSet characterIsMember:[sanitisedSel characterAtIndex:testSel.length]])) {
			transferOwnership = YES;
			break;
		}
	}
	
	JSValue *parsed;
	
	const char *returnType = sig.methodReturnType;
	
	if (is(returnType, void)) {
		parsed = [JSValue valueWithUndefinedInContext:ctx];
	} else {
		void *ret = malloc(sig.methodReturnLength);
		[inv getReturnValue:ret];
		
		JXMemoryMode mode = transferOwnership ? JXMemoryModeTransfer : JXMemoryModeStrong;
		parsed = JXConvertToJSValue(ret, returnType, ctx, mode);
		
		free(ret);
	}
	
	JX_DEBUG(@"Returning: %@", parsed);
	
	return parsed;
}

void objc_msgSendSuper2(struct objc_super *super, SEL op, ...);

// the generic implementation to use for js funcs
static void tramp(ffi_cif *cif, void *ret, void **args, void *user_info) {
	JXTrampInfo *info = (__bridge JXTrampInfo *)user_info;
	
	NSMethodSignature *sig = info.sig;
	JSValue *func = info.func;
	JSContext *ctx = func.context;
	
	// __unsafe_unretained ensures that arc won't try to mess with self during dealloc calls
	id __unsafe_unretained self = *(id __unsafe_unretained *)args[0];
	SEL _cmd = *(SEL *)args[1];
	NSString *sel = NSStringFromSelector(_cmd);
	
	id origFunc = nil;
	
	IMP orig = info.orig;
	// If this is a swizzled method, create a function that JS can call, to call the original method
	if (orig) {
		origFunc = ^JSValue *(JSValue *argsJS) {
			// Parse the args passed into origJS and populate the args array accordingly
			parseArgs(argsJS, sig, ^(int i, void *val) {
				memcpy(args[i], val, cif->arg_types[i]->size);
			});
			
			size_t size = cif->rtype->size;
			
			void *rval = malloc(size);
			@try {
				ffi_call(cif, orig, rval, args);
			} @catch (NSException *e) {
				JSContext *ctx = [JSContext currentContext];
				ctx.exception = JXConvertToError(e, ctx);
			}
			JSValue *parsedRet = JXConvertToJSValue(rval, sig.methodReturnType, ctx, JXMemoryModeStrong);
			free(rval);
			
			return parsedRet;
		};
	}
	
	BOOL isBlock = is([info.sig getArgumentTypeAtIndex:0], Block);
	// The number of args from the start to ignore
	int ignored = isBlock ? 1 : 2;
	
	// Construct an array of JSValue arguments to pass to the JS method,
	// based on the original arguments passed by the callee
	NSUInteger argc = sig.numberOfArguments;
	NSMutableArray<JSValue *> *methodArgs = [NSMutableArray arrayWithCapacity:argc-ignored];
	// set args to the original args that the method was called with
	for (int i = ignored; i < argc; i++) {
		const char *type = [sig getArgumentTypeAtIndex:i];
		methodArgs[i-ignored] = JXConvertToJSValue(args[i], type, ctx, JXMemoryModeNone);
	}
	
	JSValue *jsRet = callFunc(func, self, info.cls, origFunc, methodArgs);
	
	// if dealloc, then don't handle the return value (since sig will be nil)
	// also, call super at end of dealloc
	if ([sel isEqualToString:@"dealloc"]) {
		// objc_msgSendSuper2 accepts the class itself as the second
		// arg, rather than its superclass
		objc_msgSendSuper2(&(struct objc_super) { self, info.cls }, _cmd);
		return;
	}
	
	// Set the original invocation's return to the modified return
	JXConvertFromJSValue(jsRet, sig.methodReturnType, ^(void *val) {
		memcpy(ret, val, cif->rtype->size);
	});
}

// Create a trampoline given the required ffi types
static void createTrampWithFFITypes(ffi_type *ret, unsigned int nargs, ffi_type **args, JXTrampInfo *info) {
	void *imp;
	
	ffi_cif *cif = malloc(sizeof(ffi_cif));
	if (ffi_prep_cif(cif, FFI_DEFAULT_ABI, nargs, ret, args) != FFI_OK) return;
	
	ffi_closure *closure = ffi_closure_alloc(sizeof(ffi_closure), &imp);
	if (!closure) return;
	// weak ref to info
	if (ffi_prep_closure_loc(closure, cif, tramp, (__bridge void *)info, imp) != FFI_OK) return;
	
	info.closure = closure;
	info.tramp = imp;
}

// Create a trampoline given a func and an encoding
JXTrampInfo *JXCreateTramp(JSValue *func, const char *types, Class cls) {
	JXTrampInfo *info = [[JXTrampInfo alloc] initWithFunc:func types:types cls:cls];
	
	NSMethodSignature *sig = info.sig;
	
	unsigned int nargs = (unsigned int)sig.numberOfArguments;
	ffi_type *ret = JXFFITypeForEncoding(sig.methodReturnType);
	
	ffi_type **args = malloc(sig.numberOfArguments * sizeof(ffi_type *));
	for (NSUInteger i = 0; i < sig.numberOfArguments; i++) {
		args[i] = JXFFITypeForEncoding([sig getArgumentTypeAtIndex:i]);
	}
	
	createTrampWithFFITypes(ret, nargs, args, info);
	return info;
}

// swizzle sel if it exists, otherwise create a new method using fallbackTypes
void JXSwizzle(JSValue *func, Class cls, BOOL isClassMethod, SEL sel, NSString *fallbackTypes) {
	// Get the original method, encoding, and imp
	Method m = (isClassMethod ? class_getClassMethod : class_getInstanceMethod)(cls, sel);
	const char *types = m ? method_getTypeEncoding(m) : fallbackTypes.UTF8String;
	
	// Create a new IMP with `func` and the correct signature
	JXTrampInfo *info = JXCreateTramp(func, types, cls);
	[info retainForever];
	
	// if the specified method already exists,
	if (m) {
		// set orig to the old implementation of `m`
		info.orig = method_getImplementation(m);
	}
	
	// If the method is from a superclass (or if it's new), try adding the new tramp directly to the subclass
	// Otherwise if it's directly on the subclass, replace the method's imp with the tramp one
	if (!class_addMethod(cls, sel, info.tramp, types) && m) {
		method_setImplementation(m, info.tramp);
	}
}