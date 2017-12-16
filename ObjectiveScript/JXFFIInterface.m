//
//  JXFFIInterface.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 19/11/17.
//  Copyright © 2017 Kabir Oberai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <objc/runtime.h>
#import "JXHookInfo.h"
#import "JXJSInterop.h"
#import "JXFFIInterface.h"
#import "JXFFITypes.h"

@interface NSInvocation (hacks)
- (void)invokeUsingIMP:(IMP)imp;
@end

// the generic implementation to swizzle using
static void swizzleTramp(ffi_cif *cif, void *ret, void** args, void *user_info) {
	JXHookInfo *info = (__bridge JXHookInfo *)(user_info);
	
	size_t size = cif->rtype->size;
	// Create this outside so that it may be freed after SwizzleBlock runs
	void *rval = malloc(size);
	
	info.block(cif, ret, args, ^void * {
		ffi_call(cif, info.orig, rval, args);
		return rval;
	});
	
	free(rval);
}

// the generic implementation to create JS methods using
static void jsTramp(ffi_cif *cif, void *ret, void** args, void *user_info) {
	id self = *(__weak id *)args[0];
	SEL _cmd = *(SEL *)args[1];
	
	// Get the func via the passed in JSValue
	JSValue *func = (__bridge JSValue *)(user_info);
	JSContext *ctx = func.context;
	
	NSMethodSignature *sig = [self methodSignatureForSelector:_cmd];
	// Construct an array of JSValue arguments to pass to the JS method,
	// based on the function's args
	NSUInteger argc = sig.numberOfArguments;
	NSMutableArray<JSValue *> *methodArgs = [NSMutableArray arrayWithCapacity:argc];
	// first arg is self
	methodArgs[0] = [JSValue valueWithObject:self inContext:ctx];
	// the rest (methodArg[1] onwards) are the same as the args that the method was called with
	for (int i = 2; i < argc; i++) {
		const char *type = [sig getArgumentTypeAtIndex:i];
		// i starts with 2, methodArgs starts regular args at 1
		methodArgs[i-1] = JXConvertToJSValue(args[i], type, ctx);
	}
	JSValue *jsRet = [func callWithArguments:methodArgs];
	JXConvertFromJSValue(jsRet, sig.methodReturnType, ^(void *val) {
		// memcpy is used to copy the entire buffer, not just the first byte (which *(void **)val would've done)
		memcpy(ret, val, cif->rtype->size);
	});
}

// Create a trampoline given the required ffi types
static IMP createTrampWithTypes(ffi_type *ret, unsigned int nargs, ffi_type **args, void *user_info,
								   void (*fun)(ffi_cif *, void *, void **, void *)) {
	void *imp;
	
	// cif must not be freed, as it has to last throughout the program's execution
	ffi_cif *cif = calloc(1, sizeof(ffi_cif));
	if (ffi_prep_cif(cif, FFI_DEFAULT_ABI, nargs, ret, args) != FFI_OK) return NULL;
	
	ffi_closure *closure = ffi_closure_alloc(sizeof(ffi_closure), &imp);
	if (!closure) return NULL;
	
	if (ffi_prep_closure_loc(closure, cif, fun, user_info, imp) != FFI_OK) return NULL;
	
	return imp;
}

// Create a trampoline given an encoding
static IMP createTrampWithEnc(const char *raw_enc, void *user_info,
							  void (*fun)(ffi_cif *, void *, void **, void *)) {
	NSMethodSignature *sig = [NSMethodSignature signatureWithObjCTypes:raw_enc];
	
	unsigned int nargs = (unsigned int)sig.numberOfArguments;
	ffi_type *ret = JXFFITypeForEncoding(sig.methodReturnType);
	
	// `args` must not be freed, as it has to last throughout the program's execution
	ffi_type **args = malloc(sig.numberOfArguments * sizeof(ffi_type *));
	for (NSUInteger i = 0; i < sig.numberOfArguments; i++) {
		args[i] = JXFFITypeForEncoding([sig getArgumentTypeAtIndex:i]);
	}
	
	return createTrampWithTypes(ret, nargs, args, user_info, fun);
}

void JXSwizzle(Class cls, BOOL isClassMethod, SEL sel, SwizzleBlock block) {
	// Get the original method, encoding, and imp
	Method m = (isClassMethod ? class_getClassMethod : class_getInstanceMethod)(cls, sel);
	const char *enc = method_getTypeEncoding(m);
	IMP origImp = method_getImplementation(m);
	
	// Create a swizzle trampoline with the encoding and hookInfo
	JXHookInfo *info = [[JXHookInfo alloc] initWithOrig:origImp block:block];
	IMP tramp = createTrampWithEnc(enc, (__bridge_retained void *)(info), swizzleTramp);
	
	// If the method is from a superclass, try adding the new tramp directly to the subclass
	// Otherwise if it's directly on the subclass, replace the method's imp with the tramp one
	if (!class_addMethod(cls, sel, tramp, enc)) {
		method_setImplementation(m, tramp);
	}
}

IMP JXCreateImpFromJS(JSValue *func, const char *enc) {
	return createTrampWithEnc(enc, (__bridge_retained void *)(func), jsTramp);
}
