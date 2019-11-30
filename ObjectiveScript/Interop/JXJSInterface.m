//
//  JXJSInterface.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 30/11/19.
//  Copyright © 2019 Kabir Oberai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <objc/runtime.h>
#import "JXRuntimeInterface.h"
#import "JXStruct.h"
#import "JXSymbol.h"
#import "JXJSInterop.h"
#import "JXBlockInterop.h"
#import "JXAssociatedObjects.h"
#import "JXType+FFI.h"
#import "JXTypePointer.h"
#import "JXPointer.h"
#import "JXConfiguration.h"
#import "JXContextManager.h"
#import "JXJSInterface.h"

static JSClassRef JXGlobalClass;
static JSClassRef JXMethodClass;
JSClassRef JXFunctionClass;
JSClassRef JXObjectClass;
JSClassRef JXValueWrapperClass;
JSClassRef JXAutoreleasingObjectClass;

static JXSymbolsDict *symbols(JSContext *ctx) {
    return [JXContextManager.sharedManager JXContextForJSContext:ctx].symbols;
}

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

// common method call parsing code used by both JXMethod ([foo bar], i.e. foo["@bar"]()) and
// property-like method calls (foo.bar)
static JSValueRef methodCall(JSContextRef jsCtx, NSString *selName, JSObjectRef objRef,
                             size_t argumentCount, const JSValueRef arguments[], JSValueRef *exception) {
    // cleans up selector name, and then calls JXCallMethod

    JSContext *ctx = contextFromJSContextRef(jsCtx);

    JSValue *objJS = [JSValue valueWithJSValueRef:objRef inContext:ctx];
    id obj = JXObjectFromJSValue(objJS);

    JSValue *args = [JSValue valueWithNewArrayInContext:ctx];
    for (size_t i = 0; i < argumentCount; i++) {
        args[i] = [JSValue valueWithJSValueRef:arguments[i] inContext:ctx];
    }

    BOOL isSuper = NO;
    if ([selName hasPrefix:@"^"]) {
        selName = [selName substringFromIndex:1];
        isSuper = YES;
    } else if ([selName hasPrefix:@"@"]) {
        selName = [selName substringFromIndex:1];
    }

    // TODO: Add varargs support if possible (although even Swift-ObjC interop doesn't have it)

    Class cls = isSuper ? [NSClassFromString([ctx[@"clsName"] toString]) superclass] : [obj class];

    JSValue *jsVal;
    @try {
        jsVal = JXCallMethod(cls, ctx, obj, selName, args);
    } @catch (NSException *e) {
        *exception = JXConvertToError(e, ctx).JSValueRef;
    }
    return jsVal.JSValueRef;
}

// Intercept global getProperty calls to return a class with the name propertyName if there isn't an object by the same name
static JSValueRef globalGetProperty(JSContextRef ctxRef, JSObjectRef object, JSStringRef propertyNameJS, JSValueRef *exception) {
    NSString *propertyName = stringFromJSStringRef(propertyNameJS);

    // Skip any blacklisted properties to let JS handle them by returning NULL
    // self is blacklisted to avoid unwanted recursion due to the currSelfJS statement below
    NSArray<NSString *> *blacklist = @[@"Object", @"self", @"JXPointer"];
    if ([blacklist containsObject:propertyName]) return NULL;

    JSContext *ctx = contextFromJSContextRef(ctxRef);
    JSValue *currSelfJS = ctx[@"self"];
    id currSelf = JXObjectFromJSValue(currSelfJS);
    // can't check for currSelfJS.isUndefined because that's true when using JXObject
    if (currSelf) {
        id obj = JXGetAssociatedObject(ctx, propertyName, currSelf);
        if (obj) return JXObjectToJSValue(obj, ctx).JSValueRef;
    }

    // Otherwise return the ObjC class named propertyName (if any)
    JX_DEBUG(@"Searching for class %@", propertyName);
    Class cls = NSClassFromString(propertyName);
    if (cls) {
        return JXObjectToJSValue(cls, ctx).JSValueRef;
    }

    // otherwise return symbol if it's been defined (via loadSymbol)
    JXSymbol *sym = symbols(ctx)[propertyName];
    if (sym) {
        return JXConvertToJSValue(sym.symbol, sym.types.UTF8String, ctx, JXInteropOptionDefault).JSValueRef;
    }

    return NULL;
}

static bool globalSetProperty(JSContextRef ctxRef, JSObjectRef object, JSStringRef propertyNameJS,
                              JSValueRef valueRef, JSValueRef *exception) {
    NSString *propertyName = stringFromJSStringRef(propertyNameJS);

    // Skip any blacklisted properties to let JS handle them by returning NULL
    NSArray<NSString *> *blacklist = @[@"Object"];
    if ([blacklist containsObject:propertyName]) return false;

    JSContext *ctx = contextFromJSContextRef(ctxRef);
    JSValue *valueJS = [JSValue valueWithJSValueRef:valueRef inContext:ctx];

    JSValue *currSelfJS = ctx[@"self"];
    if (!currSelfJS.isUndefined) {
        // otherwise treat propertyName as an ivar on currentSelf
        id currSelf = JXObjectFromJSValue(currSelfJS);
        id value = JXObjectFromJSValue(valueJS);
        bool didSet = JXSetAssociatedObject(ctx, propertyName, currSelf, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        if (didSet) return true;
    }

    // otherwise try setting the value of a symbol by that name
    JXSymbol *sym = symbols(ctx)[propertyName];
    if (sym) {
        JXConvertFromJSValue(valueJS, sym.types.UTF8String, ^(void *val) {
            memcpy(sym.symbol, val, JXSizeForEncoding(sym.types.UTF8String));
        });
        return true;
    }

    return false;
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

    if ([propertyName isEqualToString:@"Symbol.toPrimitive"]) { // called by JS during type coercion
//        NSString *hint = [args[0] toString]; // number, string, or default
        JSContext *ctx = contextFromJSContextRef(ctxRef);
        return [JSValue valueWithObject:^NSString *{
            return [private description];
        } inContext:ctx].JSValueRef;
    }

    if (![propertyName hasPrefix:@"@"] && ![propertyName hasPrefix:@"^"]) {
        // check if there's an objc property by this name, which has a custom getter name
        objc_property_t prop = class_getProperty([private class], propertyName.UTF8String);
        if (prop) {
            char *getterName = property_copyAttributeValue(prop, "getter");
            if (getterName) {
                // if so, then call that method
                JSValueRef ret = methodCall(ctxRef, @(getterName), object, 0, NULL, exception);
                free(getterName);
                return ret;
            }
        }
        // otherwise just call the method named propertyName
        return methodCall(ctxRef, propertyName, object, 0, NULL, exception);
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

    const JSValueRef args[] = { valueRef };

    objc_property_t prop = class_getProperty([private class], propertyName.UTF8String);
    if (prop) {
        char *setterName = property_copyAttributeValue(prop, "setter");
        if (setterName) {
            methodCall(ctxRef, @(setterName), object, 1, args, exception);
            free(setterName);
            return true;
        }
    }

    NSString *setterSEL = [NSString stringWithFormat:@"set%@%@:",
                           [[propertyName substringToIndex:1] uppercaseString],
                           [propertyName substringFromIndex:1]];
    methodCall(ctxRef, setterSEL, object, 1, args, exception);
    return true;
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

static JSValueRef methodCallViaJSFunction(JSContextRef jsCtx,
                                          JSObjectRef function,
                                          JSObjectRef objRef,
                                          size_t argumentCount,
                                          const JSValueRef arguments[],
                                          JSValueRef *exception) {
    NSString *selName = (__bridge id)JSObjectGetPrivate(function);
    return methodCall(jsCtx, selName, objRef, argumentCount, arguments, exception);
}

static JSValueRef functionCall(JSContextRef ctxRef, JSObjectRef function, JSObjectRef objRef,
                               size_t nargs, const JSValueRef arguments[], JSValueRef *exception) {
    JSContext *ctx = contextFromJSContextRef(ctxRef);

    JXSymbol *private = (__bridge id)JSObjectGetPrivate(function);

    return JXCallFunction(private.symbol, private.types, (uint32_t)nargs, arguments, ctx).JSValueRef;
}

static JSValueRef objectCall(JSContextRef ctxRef, JSObjectRef function, JSObjectRef objRef,
                             size_t nargs, const JSValueRef arguments[], JSValueRef *exception) {
    NSString *nonBlockException = @"Tried to call non-block object";

    JSContext *ctx = contextFromJSContextRef(ctxRef);
    JSValue *objJS = [JSValue valueWithJSValueRef:function inContext:ctx];

    id block = JXObjectFromJSValue(objJS);
    if (!block) {
        *exception = JXConvertToError(JXCreateException(nonBlockException), ctx).JSValueRef;
        return [JSValue valueWithUndefinedInContext:ctx].JSValueRef;
    }

    const char *signature = NULL;
    IMP invoke = JXGetBlockIMP(block, &signature, NULL);
    if (!invoke || !signature) {
        *exception = JXConvertToError(JXCreateException(nonBlockException), ctx).JSValueRef;
        return [JSValue valueWithUndefinedInContext:ctx].JSValueRef;
    }

    // self should be the first argument in a block call
    JSValueRef allArgs[nargs + 1];
    allArgs[0] = JXObjectToJSValue(block, ctx).JSValueRef;
    memcpy(allArgs + 1, arguments, nargs * sizeof(JSValueRef));

    return JXCallFunction((void *)invoke, @(signature), (uint32_t)nargs + 1, allArgs, ctx).JSValueRef;
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
        def->callAsFunction = methodCallViaJSFunction;
        def->finalize = releasePrivate;
    });

    JXFunctionClass = createClass("JXFunction", ^(JSClassDefinition *def) {
        def->callAsFunction = functionCall;
        def->finalize = releasePrivate;
    });

    JXObjectClass = createClass("JXObject", ^(JSClassDefinition *def) {
        def->getProperty = objectGetProperty;
        def->setProperty = objectSetProperty;
        def->callAsFunction = objectCall;
    });

    JXAutoreleasingObjectClass = createClass("JXAutoreleasingObject", ^(JSClassDefinition *def) {
        def->parentClass = JXObjectClass;
        def->finalize = releasePrivate;
    });

    JXValueWrapperClass = createClass("JXValueWrapper", ^(JSClassDefinition *def) {
        def->parentClass = JXAutoreleasingObjectClass;
    });
}

static void configureContext(JSContext *ctx) {
    ctx.exceptionHandler = ^(JSContext *ctx, JSValue *error) {
        NSException *e = JXConvertFromError(error);
        NSString *log = JXCreateExceptionLog(e);
        [JXContextManager.sharedManager JXContextForJSContext:ctx].configuration.exceptionHandler(log);
        @throw e;
    };

    ctx[@"global"] = ctx.globalObject;

    // For logging messages
    ctx[@"NSLog"] = ^(JSValue *msg) {
        NSLog(@"%@", [msg toString]);
    };

    // Create the JS method hookClass(name: String, hooks: { String : Function })
    ctx[@"hookClass"] = ^(NSString *clsName, NSDictionary<NSString *, NSString *> *associatedObjects, JSValue *hooks) {
        Class cls = NSClassFromString(clsName);
        JXRegisterAssociatedObjects(hooks.context, associatedObjects, clsName);
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
        JXRegisterAssociatedObjects(methods.context, associatedObjects, clsName);
    };

    ctx[@"defineStruct"] = ^(NSString *name, NSString *sig) {
        [JXContextManager.sharedManager JXContextForJSContext:[JSContext currentContext]].structDefs[name] = sig;
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

    ctx[@"loadFunc"] = ^JSValue *(NSString *name, NSString *types, BOOL global, JSValue *library) {
        JSContext *ctx = [JSContext currentContext];
        void *sym = JXLoadSymbol(name, library);
        if (!sym) return [JSValue valueWithUndefinedInContext:ctx];

        JSValue *val = JXCreateFunctionPointer(types, sym, ctx);

        if (global) ctx[name] = val;

        return val;
    };

    ctx[@"loadSymbol"] = ^(NSString *name, NSString *types, JSValue *library) {
        void *sym = JXLoadSymbol(name, library);
        if (!sym) return;
        symbols(library.context)[name] = [[JXSymbol alloc] initWithSymbol:sym types:types];
    };

    ctx[@"FunctionPointer"] = ^JSValue *(NSString *types, JSValue *ptr) {
        __block void *sym = NULL;
        JXConvertFromJSValue(ptr, @encode(void *), ^(void *val) {
            sym = *(void **)val;
        });
        return JXCreateFunctionPointer(types, sym, ptr.context);
    };

    ctx[@"getRef"] = ^JSValue *(NSString *name) {
        JSContext *ctx = [JSContext currentContext];

        JXSymbol *sym = symbols(ctx)[name];
        if (!sym) return [JSValue valueWithUndefinedInContext:ctx];

        // we don't just prepend a ^ because if sym.types is `c` then the ptr should be `*` not `^c`
        JXTypePointer *type = [[JXTypePointer alloc] initWithType:JXTypeForEncoding(sym.types.UTF8String) isFunction:NO];

        // since we want the pointer to contain `symbol` itself, we pass &symbol to JXConvertToJSValue
        void *symbol = sym.symbol;
        return JXConvertToJSValue(&symbol, type.encoding.UTF8String, ctx, JXInteropOptionDefault);
    };

    ctx[@"Pointer"] = ^JSValue *(NSString *enc, JSValue *zeroMemory) {
        size_t size = JXSizeForEncoding(enc.UTF8String);

        // see getRef for the rationale behind this
        JXTypePointer *type = [[JXTypePointer alloc] initWithType:JXTypeForEncoding(enc.UTF8String) isFunction:NO];

        void *ptr = zeroMemory.toBool ? calloc(1, size) : malloc(size);
        return JXConvertToJSValue(&ptr, type.encoding.UTF8String, [JSContext currentContext], JXInteropOptionDefault);
    };

    ctx[@"sizeof"] = ^size_t(NSString *enc) {
        return JXSizeForEncoding(enc.UTF8String);
    };

    ctx[@"cast"] = ^JSValue *(NSString *enc, JSValue *val) {
        return JXCastValue(val, enc.UTF8String);
    };
}

JSContext *JXCreateContext(JXConfiguration *configuration) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ setup(); });

    JSGlobalContextRef ctxRef = JSGlobalContextCreate(JXGlobalClass);
    JSContext *ctx = [JSContext contextWithJSGlobalContextRef:ctxRef];
    // ctx retains ctxRef, so we can release our ownership
    JSGlobalContextRelease(ctxRef);

    configureContext(ctx);

    JXContext *jxCtx = [[JXContext alloc] initWithConfiguration:configuration];
    [JXContextManager.sharedManager registerJXContext:jxCtx forJSContext:ctx];

    return ctx;
}
