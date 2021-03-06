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
#import <dlfcn.h>
#import "JXTrampInfo.h"
#import "JXJSInterop.h"
#import "JXRuntimeInterface.h"
#import "JXType+FFI.h"
#import "JXTypeBasic+FFI.h"
#import "JXTypeID.h"
#import "JXBlockInterop.h"

@interface NSInvocation (hacks)
- (void)invokeUsingIMP:(IMP)imp;
@end

// Push callContext onto ctx like a stack, call `block`, and then pop them
static void withCallContext(NSDictionary *items, JSContext *ctx, void (^block)(void)) {
    // prevent race conditions with @synchronized
    @synchronized (ctx) {
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
}

static JSValue *callFunc(JSValue *func, id self, Class cls, id orig, NSMutableArray<JSValue *> *methodArgs) {
	JSContext *ctx = func.context;
    // JXInteropOptionNone is needed because the method may be deinit where we can't retain/release self
	JSValue *selfJS = JXConvertToJSValue(&self, @encode(id), ctx, JXInteropOptionNone);
	
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
static void parseArgs(JSValue *args, JXMethodSignature *sig, void (^block)(int, void *)) {
	if (args.isUndefined) return;
	int length = [args[@"length"] toUInt32];
	for (int i = 0; i < length; i++) {
		JSValue *arg = args[i];
		const char *type = sig.argumentTypes[2+i].encoding.UTF8String;
		JXConvertFromJSValue(arg, type, ^(void *ptr) {
			// Pass in 2+i because each JSValue arg corresponds to the
			// actual arg 2 indices further down (as 0 & 1 are self & _cmd)
			block(2+i, ptr);
		});
	}
}

// cls indicates the class from which the method search should start
JSValue *JXCallMethod(Class cls, JSContext *ctx, id obj, NSString *selName, JSValue *args) {
	JX_DEBUG(@"Method %@ is being called on %@", selName, obj);
	
	SEL sel = NSSelectorFromString(selName);
	if (!sel || !obj) return [JSValue valueWithUndefinedInContext:ctx];
    BOOL isClassMethod = object_isClass(obj);

	NSMethodSignature *sig = [obj methodSignatureForSelector:sel];
    if (!sig) {
        @throw JXCreateExceptionFormat(@"%@[%@ %@]: Attempted to send unrecognized selector to instance %p",
                                       isClassMethod ? @"+" : @"-", NSStringFromClass(cls), selName, obj);
    }
	NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
	inv.target = obj;
	inv.selector = sel;
	
	// Set the args of the NSInvocation to the passed in ones
	parseArgs(args, [JXMethodSignature signatureWithNSMethodSignature:sig], ^(int i, void *val) {
		[inv setArgument:val atIndex:i];
	});
	
	IMP imp;
	if (isClassMethod) {
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

        JXInteropOptions options = JXInteropOptionAutorelease | JXInteropOptionCopyStructs;
        if (!transferOwnership) options |= JXInteropOptionRetain;
		parsed = JXConvertToJSValue(ret, returnType, ctx, options);
		
		free(ret);
	}
	
	JX_DEBUG(@"Returning: %p", parsed);
	
	return parsed;
}

JSValue *JXCallFunction(void *sym, NSString *types, uint32_t nargs, const JSValueRef jsArgs[], JSContext *ctx) {
	// Just checking if (nargs > nfixedargs) won't suffice because
	// sometimes a variadic call may be made with no additional args.
	// So if types ends with "...", let it indicate that it's variadic.
	NSString *varSuffix = @"...";
	BOOL isVariadic = [types hasSuffix:varSuffix];
	if (isVariadic) {
		// remove "..." from the end
		types = [types substringToIndex:types.length-varSuffix.length];
	}
	
	// Create a JXMethodSignature from `types`, and get its metadata.
	JXMethodSignature *sig = [JXMethodSignature signatureWithObjCTypes:types];
    ffi_type *rtype = [sig.returnType ffiType];
	// `numberOfArguments` will be num of fixed args here because `types` only contains fixed arg types even if variadic
	uint32_t nfixedargs = (uint32_t)sig.argumentTypes.count;
    uint32_t nvarargs = nargs - nfixedargs;

	// if variadic, append the rest of the types to `sig`
	if (isVariadic) {
		NSMutableString *var = [NSMutableString stringWithCapacity:nvarargs];
		for (uint32_t i = nfixedargs; i < nargs; i++) {
            JSValue *val = [JSValue valueWithJSValueRef:jsArgs[i] inContext:ctx];
			[var appendString:JXGuessEncoding(val)];
		}
		NSString *fullTypes = [types stringByAppendingString:var];
        sig = [JXMethodSignature signatureWithObjCTypes:fullTypes];

        // set nargs to the real number of args (subtract the number of type indicators)
        nargs = nfixedargs + nvarargs;
    }

    ffi_type *args[nargs];
    for (uint32_t i = 0; i < nargs; i++) {
        args[i] = [sig.argumentTypes[i] ffiType];
    }

    // prepare cif
    ffi_cif cif;
	if (isVariadic) {
		ffi_prep_cif_var(&cif, FFI_DEFAULT_ABI, nfixedargs, nargs, rtype, args);
	} else {
		ffi_prep_cif(&cif, FFI_DEFAULT_ABI, nargs, rtype, args);
	}

	// malloc a buffer large enough to hold rval
	void *rval = malloc(rtype->size);

	// create an array of argument values
	void *argvals[nargs];
	for (uint32_t i = 0; i < nargs; i++) {
		size_t argSize = args[i]->size;
		// we can't assign to argvals[i] directly because the compiler doesn't like it, so make a temp var
		__block void *argval = malloc(argSize);
		JSValue *jsVal = [JSValue valueWithJSValueRef:jsArgs[i] inContext:ctx];
		JXConvertFromJSValue(jsVal, sig.argumentTypes[i].encoding.UTF8String, ^(void *val) {
			// copy val into the argval buffer
			memcpy(argval, val, argSize);
		});
		argvals[i] = argval;
	}

	ffi_call(&cif, sym, rval, argvals);

	JSValue *retVal = JXConvertToJSValue(rval,
                                         sig.returnType.encoding.UTF8String,
                                         ctx,
                                         JXInteropOptionDefault | JXInteropOptionCopyStructs);

	// cleanup
	free(rval);
	for (uint32_t i = 0; i < nargs; i++) free(argvals[i]);

	return retVal;
}

void objc_msgSendSuper2(struct objc_super *super, SEL op, ...);

// the generic implementation to use for js funcs
static void tramp(ffi_cif *cif, void *ret, void **args, void *user_info) {
	JXTrampInfo *info = (__bridge JXTrampInfo *)user_info;
	
	JXMethodSignature *sig = info.sig;
	JSValue *func = info.func;
	JSContext *ctx = func.context;

    JXType *firstArgument = sig.argumentTypes[0];
    BOOL isBlock = [firstArgument isKindOfClass:[JXTypeID class]] && ((JXTypeID *)firstArgument).isBlock;
    // The number of implicit arguments
    int ignored = isBlock ? 1 : 2;

	// __unsafe_unretained ensures that arc won't try to mess with self during dealloc calls
	id __unsafe_unretained self = *(id __unsafe_unretained *)args[0];

    SEL _cmd;
    NSString *sel;
    if (isBlock) {
        _cmd = NULL;
        sel = nil;
    } else {
        _cmd = *(SEL *)args[1];
        sel = NSStringFromSelector(_cmd);
    }
	
	id origFunc = nil;
	
	IMP orig = info.orig;
	// If this is a swizzled method, create a function that JS can call, to call the original method
	if (orig) {
		origFunc = ^JSValue *(JSValue *argsJS) {
            uint32_t argsLen = ignored + [argsJS[@"length"] toUInt32];
            // we can't use the original args array because if origFunc
            // is captured, it may exist after args is freed
            void **passedArgs = malloc(sizeof(void *) * (argsLen + 1));

            passedArgs[0] = malloc(sizeof(id));
            *(id __unsafe_unretained *)passedArgs[0] = self;

            if (!isBlock) {
                passedArgs[1] = malloc(sizeof(SEL));
                *(SEL *)passedArgs[1] = _cmd;
            }

            passedArgs[argsLen] = NULL;

			// Parse the args passed into origJS and populate the passedArgs array accordingly
			parseArgs(argsJS, sig, ^(int i, void *val) {
                size_t argSize = cif->arg_types[i]->size;
                passedArgs[i] = malloc(argSize);
                memcpy(passedArgs[i], val, argSize);
			});

			size_t size = cif->rtype->size;
			
			void *rval = malloc(size);
			@try {
				ffi_call(cif, orig, rval, passedArgs);
                for (uint32_t i = 0; i < argsLen; i++) free(passedArgs[i]);
                free(passedArgs);
			} @catch (NSException *e) {
				JSContext *ctx = [JSContext currentContext];
				ctx.exception = JXConvertToError(e, ctx);
			}
			JSValue *parsedRet = JXConvertToJSValue(rval,
                                                    sig.returnType.encoding.UTF8String,
                                                    ctx,
                                                    JXInteropOptionDefault | JXInteropOptionCopyStructs);
			free(rval);
			
			return parsedRet;
		};
	}
	
	// Construct an array of JSValue arguments to pass to the JS method,
	// based on the original arguments passed by the callee
	NSUInteger argc = sig.argumentTypes.count;
	NSMutableArray<JSValue *> *methodArgs = [NSMutableArray arrayWithCapacity:argc-ignored];
	// set args to the original args that the method was called with
	for (int i = ignored; i < argc; i++) {
		const char *type = sig.argumentTypes[i].encoding.UTF8String;
		methodArgs[i-ignored] = JXConvertToJSValue(args[i], type, ctx, JXInteropOptionNone);
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
	JXConvertFromJSValue(jsRet, sig.returnType.encoding.UTF8String, ^(void *val) {
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
JXTrampInfo *JXCreateTramp(JSValue *func, NSString *types, Class cls) {
	JXTrampInfo *info = [[JXTrampInfo alloc] initWithFunc:func types:types cls:cls];

    JXMethodSignature *sig = info.sig;
	
	unsigned int nargs = (unsigned int)sig.argumentTypes.count;
	ffi_type *ret = [sig.returnType ffiType];
	
	ffi_type **args = malloc(nargs * sizeof(ffi_type *));
	for (NSUInteger i = 0; i < nargs; i++) {
		args[i] = [sig.argumentTypes[i] ffiType];
	}
	
	createTrampWithFFITypes(ret, nargs, args, info);
	return info;
}

// swizzle sel if it exists, otherwise create a new method using fallbackTypes
void JXSwizzle(JSValue *func, Class cls, BOOL isClassMethod, SEL sel, NSString *fallbackTypes) {
	Method m = (isClassMethod ? class_getClassMethod : class_getInstanceMethod)(cls, sel);
	const char *types = m ? method_getTypeEncoding(m) : fallbackTypes.UTF8String;

	JXTrampInfo *info = [JXCreateTramp(func, @(types), cls) retainForever];

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

void *JXLoadSymbol(NSString *name, JSValue *library) {
    JSContext *ctx = library.context;

#define raiseExceptionIfNULL(val) if (!val) { \
    NSException *e = JXCreateException(@(dlerror())); \
    ctx.exception = JXConvertToError(e, ctx); \
    return NULL; \
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

    return sym;
}
