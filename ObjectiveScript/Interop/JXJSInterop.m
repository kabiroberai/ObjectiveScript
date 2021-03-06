//
//  JXJSInterop.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 14/12/17.
//  Copyright © 2017 Kabir Oberai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "JXJSInterop.h"
#import "JXStruct.h"
#import "JXType.h"
#import "ObjectiveScript.h"
#import "JXBlockInterop.h"
#import "JXPointer.h"
#import "JXValueWrapper.h"
#import "JXTypeQualifiers.h"
#import "JXTypeArray.h"
#import "JXArray.h"
#import "JXSymbol.h"
#import "JXContextManager.h"

#define isType(primitive) (is(type, primitive))

extern JSClassRef JXFunctionClass;
extern JSClassRef JXObjectClass;
extern JSClassRef JXValueWrapperClass;
extern JSClassRef JXAutoreleasingObjectClass;

NSArray<NSString *> *JXKeysOfDict(JSValue *dict) {
	return [[dict.context[@"Object"][@"keys"] callWithArguments:@[dict]] toArray];
}

NSString *JXCreateExceptionLog(NSException *e) {
    NSMutableDictionary *userInfo = [e.userInfo mutableCopy] ?: [NSMutableDictionary dictionary];

    NSString *exceptionType;
    if (userInfo[@"JXIsJSError"]) {
        exceptionType = @"JS error";
    } else {
        exceptionType = @"exception";
    }
    NSMutableString *exceptionLog = [NSMutableString stringWithFormat:@"*** Terminating app due to uncaught %@ '%@'", exceptionType, e.name];
    if (e.reason) {
        [exceptionLog appendFormat:@", reason: '%@'", e.reason];
    }

    if (userInfo[@"JXLine"] && userInfo[@"JXColumn"]) {
        NSNumber *line = userInfo[@"JXLine"];
        NSNumber *column = userInfo[@"JXColumn"];
        [exceptionLog appendFormat:@"\n\n*** JS exception location: %@:%@", line, column];
    }

    if (userInfo[@"JXStackTrace"]) {
        NSString *jxStackTrace = [userInfo[@"JXStackTrace"] componentsJoinedByString:@"\n\t"];
        [exceptionLog appendFormat:@"\n\n*** JS exception call stack:\n(\n\t%@\n)", jxStackTrace];
    }
    if (e.callStackSymbols) {
        [exceptionLog appendFormat:@"\n\n*** First throw call stack:\n%@", e.callStackSymbols];
    }
    [exceptionLog appendFormat:@"\n\n*** Objective-C call stack:\n%@", NSThread.callStackSymbols];

    if (userInfo.count > 0) {
        [exceptionLog appendFormat:@"\n\n*** User info:\n%@", userInfo];
    }

    return [exceptionLog copy];
}

NSException *JXCreateException(NSString *reason) {
	return [NSException exceptionWithName:@"JXException" reason:reason userInfo:nil];
}

NSException *JXCreateExceptionFormat(NSString *format, ...) {
    va_list ap;
    va_start(ap, format);
    NSString *reason = [[NSString alloc] initWithFormat:format arguments:ap];
    va_end(ap);
    return JXCreateException(reason);
}

/// Create a JS error from an NSException
JSValue *JXConvertToError(NSException *e, JSContext *ctx) {
	NSString *message = [NSString stringWithFormat:@"%@: %@", e.name, e.reason];
	JSValue *error = [JSValue valueWithNewErrorFromMessage:message inContext:ctx];
	error[@"nsException"] = e;
	return error;
}

/// Create an NSException from a JS error
NSException *JXConvertFromError(JSValue *error) {
	NSException *e = [error[@"nsException"] toObjectOfClass:NSException.class];
	if (e) return e;
	
	NSString *name = [error[@"name"] toString];
	NSString *reason = [error[@"message"] toString];
    NSString *stack = [error[@"stack"] toString];
    NSNumber *line = [error[@"line"] toNumber];
    NSNumber *column = [error[@"column"] toNumber];

    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[@"JXIsJSError"] = @YES;
    if (column != nil) userInfo[@"JXColumn"] = column;
    if (line != nil) userInfo[@"JXLine"] = line;

    if (stack) {
        NSMutableArray<NSString *> *methods = [[stack componentsSeparatedByString:@"\n"] mutableCopy];
        for (int i = 0; i < methods.count; i++) {
            if (methods[i].length == 0) methods[i] = @"(anonymous function)";
        }
        userInfo[@"JXStackTrace"] = [methods copy];
    }

    return [NSException exceptionWithName:name reason:reason userInfo:userInfo];
}

// JXConvert[To|From]JSValue Inspired by https://github.com/steipete/Aspects and https://github.com/ReactiveCocoa/ReactiveCocoa/blob/db51e2bb2ceb7464db71b190cf133105e83dd378/ReactiveObjC/NSInvocation%2BRACTypeParsing.m

JSValue *JXConvertToJSValue(void *val, const char *type, JSContext *ctx, JXInteropOptions options) {
	if (val == NULL) return nil;
	
	JXRemoveQualifiers(&type);
	
	id obj;
	
#define as(type) (*(type *)(val))
#define ret(obj) return [JSValue valueWithObject:obj inContext:ctx];
#define retIf(primitive) else if (isType(primitive)) ret(@(as(primitive)))
#define retIfPair(primitive) retIf(primitive) retIf(unsigned primitive)

    // *type == _C_ID accounts for objects and blocks, with or without class names
	if (*type == _C_ID || isType(Class)) obj = as(id __strong);
    else if (*type == _C_PTR) {
        void *converted = as(void *);
        if (!converted) return [JSValue valueWithNullInContext:ctx];
        // type+1  removes the initial '^'
        JXPointer *ptr = [JXPointer pointerWithVal:converted type:@(type+1)];
        obj = ptr;
    }
    else if (*type == _C_ARY_B) {
        // we don't do the converted check for arrays because they're always inside a struct, so
        // val should never be NULL
        JXTypeArray *arrayType = [JXTypeArray typeForEncodingC:type];
        JXArray *arr = [JXArray arrayWithVal:val type:arrayType.type.encoding count:arrayType.count];
        obj = arr;
    }
    else if (*type == _C_STRUCT_B) {
        BOOL copyStructs = (options & JXInteropOptionCopyStructs);
        JXStruct *jxStruct = [JXStruct structWithVal:val type:type copy:copyStructs context:ctx];
        if (!jxStruct) return nil;

        NSString *extendedType = [jxStruct extendedTypeInContext:ctx];
        if (extendedType) {
            jxStruct = [JXStruct structWithVal:val type:extendedType.UTF8String copy:copyStructs context:ctx];
            if (!jxStruct) return nil;
        }

        obj = jxStruct;
    }
    else if (isType(SEL)) {
        SEL converted = as(SEL);
        if (!converted) return [JSValue valueWithNullInContext:ctx];
        ret(NSStringFromSelector(converted))
    }
    else if (isType(char *)) {
        char *converted = as(char *);
        if (!converted) return [JSValue valueWithNullInContext:ctx];
        ret(@(converted))
    }
	retIf(float)
	retIf(double)
	retIf(bool)
	retIfPair(char)
	retIfPair(short)
	retIfPair(int)
	retIfPair(long long)
	else return [JSValue valueWithUndefinedInContext:ctx];

#undef retIfPair
#undef retIf
#undef ret
#undef as
	
	if (obj == nil) return [JSValue valueWithNullInContext:ctx];
	
	// Handle ObjC objects in a special manner, by wrapping them in JXObjectClass
	void *bridged = (__bridge void *)obj;
	
	BOOL retain = (options & JXInteropOptionRetain);
	BOOL autorelease = (options & JXInteropOptionAutorelease);

	if (retain) CFRetain(bridged);
	JSObjectRef ref = JSObjectMake(ctx.JSGlobalContextRef, autorelease ? JXAutoreleasingObjectClass : JXObjectClass, bridged);
    JX_DEBUG(@"<JSObjectRef: %p; retained: %d, autorelease: %d; private = %p>", ref, retain, autorelease, obj);
	return [JSValue valueWithJSValueRef:ref inContext:ctx];
}

JSValue *JXObjectToJSValue(id val, JSContext *ctx) {
	return JXConvertToJSValue(&val, @encode(id), ctx, JXInteropOptionDefault);
}

void JXConvertFromJSValue(JSValue *value, const char *type, void (^block)(void *)) {
	JXRemoveQualifiers(&type);

    JSContext *ctx = value.context;
    JSContextRef ctxRef = ctx.JSGlobalContextRef;
    JSValueRef valRef = value.JSValueRef;

    if (JSValueIsObjectOfClass(ctxRef, valRef, JXValueWrapperClass)) {
        JSObjectRef ref = JSValueToObject(ctxRef, valRef, nil);
        id obj = (__bridge id)JSObjectGetPrivate(ref);
        // if the value is surrounded by a JXValueWrapper, then perform the call on the unwrapped value
        JXConvertFromJSValue([obj value], type, block);
        return;
    }

    // all numbers are internally doubles in JS
#define cmpSet(primitive) else if (isType(primitive)) { \
	primitive num = (primitive)[value toDouble]; \
	block(&num); \
}

#define cmpSetPair(primitive) cmpSet(primitive) cmpSet(unsigned primitive)

	// if not for __autoreleasing, `val` would be deallocated after method return
#define setAutoreleasing(val) id __autoreleasing autoreleasingVal = val; obj = autoreleasingVal;
	
	if (*type == _C_ID || isType(Class)) {
		id obj;

		if (JSValueIsObjectOfClass(ctxRef, valRef, JXObjectClass)) {
			// If value is our JXObjectClass type, fetch it accordingly
			JSObjectRef ref = JSValueToObject(ctxRef, valRef, nil);
			obj = (__bridge id)JSObjectGetPrivate(ref);
			// Otherwise, it's an ObjC JSValue
		} else if (value.isNull) {
			// if the JSValue is null, return nil
			obj = nil;
		} else if (value.isString) {
			setAutoreleasing([value toString]);
		} else if (value.isDate) {
			setAutoreleasing([value toDate]);
		} else if (value.isArray) {
			// if it's a JS array, recursively convert it
			uint32_t len = value[@"length"].toUInt32;
			NSMutableArray *arr = [NSMutableArray arrayWithCapacity:len];
			for (uint32_t i = 0; i < len; i++) {
				arr[i] = JXObjectFromJSValue(value[i]);
			}
			setAutoreleasing([arr copy]);
		} else if (value.isObject) {
			// if it's a JS dict, recursively convert it
			NSArray<NSString *> *keys = JXKeysOfDict(value);
			NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:keys.count];
			for (NSString *key in keys) {
				dict[key] = JXObjectFromJSValue(value[key]);
			}
			setAutoreleasing([dict copy])
		} else {
			// otherwise convert it from a native JS object
			setAutoreleasing([value toObject])
		}
		block(&obj);
    } else if (*type == _C_PTR) { // `value` is a pointer
        JXPointer *ptr = JXObjectFromJSValue(value);
        void *val = ptr.val;
        // pass in `&val` because the implementation of `block` uses the _contents_ of
        // the arg i.e. `*(&val)`, which results in `val`, which is the desired pointer
        block(&val);
    } else if (*type == _C_STRUCT_B) { // `value` is a JXStruct
        JXStruct *obj = JXObjectFromJSValue(value);
        // already a void *, don't pass memory address
        block(obj.val);
    } else if (*type == _C_ARY_B) {
        JXType *jxType = [JXTypeArray typeForEncodingC:type];
        @throw JXCreateExceptionFormat(@"Array type '%@' is not assignable", jxType);
    } else if (isType(SEL)) {
		SEL sel = NSSelectorFromString([value toString]);
		block(&sel);
	} else if (isType(char *)) {
		const char *str = [value toString].UTF8String;
		block(&str);
	}

	cmpSetPair(char)
	cmpSetPair(short)
	cmpSetPair(int)
	cmpSet(long long)
	cmpSet(unsigned long long)
	cmpSet(float)
	cmpSet(double)
	cmpSet(bool)
	else {
        id val = nil;
        block(&val);
	}
	
#undef cmpSet
#undef cmpSetType
#undef cmpSetPair
}

id JXObjectFromJSValue(JSValue *value) {
	__block __unsafe_unretained id obj;
	JXConvertFromJSValue(value, @encode(id), ^(void *ptr) {
		obj = *(id __unsafe_unretained *)ptr;
	});
	return obj;
}

JSValue *JXCastValue(JSValue *value, const char *rawType) {
    JXRemoveQualifiers(&rawType);

    JSContext *ctx = value.context;
    JSContextRef ctxRef = ctx.JSGlobalContextRef;

    if (*rawType == _C_PTR) {
        // if the type is a pointer, just return a new JXPointer with the required rawType
        JXPointer *ptr = JXObjectFromJSValue(value);
        return JXObjectToJSValue([ptr withType:@(rawType + 1)], ctx);
    } else if (*rawType == _C_STRUCT_B) {
        // treat structs in a similar way as well
        JXStruct *str = JXObjectFromJSValue(value);
        JXStruct *converted = [str withType:rawType context:ctx];
        if (converted) {
            return JXObjectToJSValue(converted, ctx);
        } else {
            return [JSValue valueWithNullInContext:ctx];
        }
    }

    // for everything else, wrap it in a JXValueWrapper
    JXValueWrapper *valueWrapper = [[JXValueWrapper alloc] initWithTypes:@(rawType) value:value];
    JSObjectRef ref = JSObjectMake(ctxRef, JXValueWrapperClass, (__bridge_retained void *)valueWrapper);
    return [JSValue valueWithJSValueRef:ref inContext:ctx];
}

NSString *JXGuessEncoding(JSValue *value) {
    if (value.isNumber) {
        return @(@encode(double));
    }

    JSContext *ctx = value.context;
    JSContextRef ctxRef = ctx.JSGlobalContextRef;
    JSValueRef valRef = value.JSValueRef;

    if (!JSValueIsObjectOfClass(ctxRef, valRef, JXObjectClass)) return @(@encode(id));

    JSObjectRef objRef = JSValueToObject(ctxRef, valRef, nil);
    __unsafe_unretained id obj = (__bridge id)JSObjectGetPrivate(objRef);

    if ([obj isKindOfClass:JXPointer.class]) {
        return ((JXPointer *)obj).type;
    } else if ([obj isKindOfClass:JXStruct.class]) {
        return [obj extendedTypeInContext:ctx] ?: [obj rawType];
    } else if ([obj isKindOfClass:JXValueWrapper.class]) {
        return [obj types];
    }

    return @(@encode(id));
}

// Returns a (I think) lossless, native JS representation of `obj` if
// possible. If there is no native representation, returns a wrapped object
// as JXObjectToJSValue would.
//
// This function is helpful because calling +[JSValue valueWithObject:inContext:]
// does not preserve JXObjectClass values that are embedded in arrays/dicts.
JSValue *JXUnboxValue(id obj, JSContext *ctx) {
	if ([obj isKindOfClass:NSArray.class]) {
		// Deep convert arrays
		NSArray *arr = (NSArray *)obj;
		JSValue *jsArr = [JSValue valueWithNewArrayInContext:ctx];
		for (NSUInteger i = 0; i < arr.count; i++) {
			jsArr[i] = JXUnboxValue(arr[i], ctx);
		}
		return jsArr;
	} else if ([obj isKindOfClass:NSDictionary.class]) {
		// Deep convert dicts
		NSDictionary *dict = (NSDictionary *)obj;
		JSValue *jsDict = [JSValue valueWithNewObjectInContext:ctx];
		for (NSString *key in dict) {
			jsDict[key] = JXUnboxValue(dict[key], ctx);
		}
		return jsDict;
	} else if ([obj isKindOfClass:NSString.class]) {
		// Copy strings because if the string is mutable, JS won't like it
		return [JSValue valueWithObject:[obj copy] inContext:ctx];
	} else if ([obj isKindOfClass:NSDate.class] || [obj isKindOfClass:NSNumber.class]) {
        return [JSValue valueWithObject:obj inContext:ctx];
	} else {
		// If it can't be losslessly converted, use JXObjectToJSValue as normal
		return JXObjectToJSValue(obj, ctx);
	}
}

JSValue *JXCreateFunctionPointer(NSString *types, void *sym, JSContext *ctx) {
    JSContextRef ctxRef = ctx.JSGlobalContextRef;

    JXSymbol *jxFunc = [[JXSymbol alloc] initWithSymbol:sym types:types];
    JSObjectRef obj = JSObjectMake(ctxRef, JXFunctionClass, (__bridge_retained void *)jxFunc);
    JSValue *val = [JSValue valueWithJSValueRef:obj inContext:ctx];

    return val;
}
