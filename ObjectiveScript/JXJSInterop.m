//
//  JXJSInterop.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 14/12/17.
//  Copyright © 2017 Kabir Oberai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "JXJSInterop.h"
#import "JXStruct.h"
#import "JXFFITypes.h"
#import "ObjectiveScript.h"
#import "Block.h"

#define isType(primitive) (is(type, primitive))

JSClassRef JXAutoreleasingObjectClass;
JSClassRef JXObjectClass;

NSArray<NSString *> *JXKeysOfDict(JSValue *dict) {
	return [[dict.context[@"Object"][@"keys"] callWithArguments:@[dict]] toArray];
}

NSException *JXCreateException(NSString *reason) {
	return [NSException exceptionWithName:@"JXException" reason:reason userInfo:nil];
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
	return [NSException exceptionWithName:name reason:reason userInfo:nil];
}

// JXConvert[To|From]JSValue Inspired by https://github.com/steipete/Aspects and https://github.com/ReactiveCocoa/ReactiveCocoa/blob/db51e2bb2ceb7464db71b190cf133105e83dd378/ReactiveObjC/NSInvocation%2BRACTypeParsing.m

JSValue *JXConvertToJSValue(void *val, const char *type, JSContext *ctx, JXMemoryMode memoryMode) {
	if (val == NULL) return nil;
	
	JXRemoveQualifiers(&type);
	id object;
	
#define retObj(obj) return [JSValue valueWithObject:obj inContext:ctx]
#define cmpSet(primitive) else if (isType(primitive)) retObj(@(*(primitive *)val));
#define cmpSetPair(primitive) cmpSet(primitive) cmpSet(unsigned primitive)
	
	if (isType(id) || isType(Class) || isType(Block)) object = *(id __unsafe_unretained *)val;
	else if (isType(SEL)) retObj(NSStringFromSelector(val));
	else if (*type == '{') object = [JXStruct structWithVal:val type:type];
	cmpSet(char *)
	cmpSetPair(char)
	cmpSetPair(short)
	cmpSetPair(int)
	cmpSetPair(long)
	cmpSetPair(long long)
	cmpSet(float)
	cmpSet(double)
	cmpSet(bool)
	else return [JSValue valueWithUndefinedInContext:ctx];
	
#undef cmpSet
#undef cmpSetPair
	
	if (object == nil) return [JSValue valueWithNullInContext:ctx];
	
	// Handle all other ObjC objects in a special manner, by wrapping them in JXObjectClass
	void *bridged = (__bridge void *)object;
	
	BOOL retain = (memoryMode == JXMemoryModeStrong);
	BOOL autorelease = (memoryMode != JXMemoryModeNone);
	
	if (retain) CFRetain(bridged);
	JSObjectRef ref = JSObjectMake(ctx.JSGlobalContextRef, autorelease ? JXAutoreleasingObjectClass : JXObjectClass, bridged);
	JX_DEBUG(@"<JSObjectRef: %p; memoryMode = %li; private = %@>", ref, (long)memoryMode, object);
	return [JSValue valueWithJSValueRef:ref inContext:ctx];
}

JSValue *JXObjectToJSValue(id val, JSContext *ctx) {
	return JXConvertToJSValue(&val, @encode(id), ctx, JXMemoryModeStrong);
}

// Returns a (relatively) lossless, native JS representation of `obj` if
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

void JXConvertFromJSValue(JSValue *value, const char *type, void (^block)(void *)) {
	JXRemoveQualifiers(&type);
	
	id obj;
	
	JSContext *ctx = value.context;
	JSContextRef ctxRef = ctx.JSGlobalContextRef;
	JSValueRef valRef = value.JSValueRef;
	if (JSValueIsObjectOfClass(ctxRef, valRef, JXObjectClass)) {
		// If value is our JXObjectClass type, fetch it accordingly
		JSObjectRef ref = JSValueToObject(ctxRef, valRef, nil);
		obj = (__bridge id)JSObjectGetPrivate(ref);
		// Otherwise, it's an ObjC JSValue
	} else if (value.isUndefined) {
		// if the JSValue is undefined, return
		return;
	} else if (value.isNull) {
		// if the JSValue is null, set obj to nil
		obj = nil;
	} else if (value.isArray) {
		// if it's a JS array, recursively convert it
		uint32_t len = value[@"length"].toUInt32;
		NSMutableArray *arr = [NSMutableArray arrayWithCapacity:len];
		for (uint32_t i = 0; i < len; i++) {
			arr[i] = JXObjectFromJSValue(value[i]);
		}
		// if not for __autoreleasing, immutableArr would be deallocated after method return
		NSArray * __autoreleasing immutableArr = [arr copy];
		obj = immutableArr;
	} else if (!value.isDate && [value isInstanceOf:ctx[@"Object"]]) {
		// if it's a JS dict, recursively convert it
		NSArray<NSString *> *keys = JXKeysOfDict(value);
		NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:keys.count];
		for (NSString *key in keys) {
			dict[key] = JXObjectFromJSValue(value[key]);
		}
		NSDictionary * __autoreleasing immutableDict = [dict copy];
		obj = immutableDict;
	} else {
		// otherwise convert it from a native JS object
		id __autoreleasing valObj = [value toObject];
		obj = valObj;
	}

	void *arg;
	
	// primitive = methodValue
#define cmpSet(primitive, method) else if (isType(primitive)) { \
	primitive num = [(NSNumber*)obj method##Value]; \
	arg = &num; \
}
	// primitive = primitiveValue; unsigned primitive = unsignedValue
#define cmpSetPair(primitive, Primitive) cmpSet(primitive, primitive) cmpSet(unsigned primitive, unsigned##Primitive)
	
	if (isType(id) || isType(Class) || isType(Block)) arg = &obj;
	else if (isType(SEL)) {
		SEL sel = NSSelectorFromString(obj);
		arg = &sel;
	} else if (isType(char *)) {
		const char *str = [obj UTF8String];
		arg = &str;
	} else if (*type == '{') { // obj is a JXStruct
		arg = [obj val];
	}
	cmpSetPair(char, Char)
	cmpSetPair(short, Short)
	cmpSetPair(int, Int)
	cmpSetPair(long, Long)
	cmpSet(long long, longLong)
	cmpSet(unsigned long long, unsignedLongLong)
	cmpSet(float, float)
	cmpSet(double, double)
	cmpSet(bool, bool) // Otherwise method would be _BoolValue
	else {
		id val = nil;
		arg = &val;
	}
	
	// TODO: both `long` and `long long` turn into `q`, whereas `long` should become `l`. `long` seems to be the same as `int` though, so not sure what the point of supporting it is.
	
#undef cmpSet
#undef cmpSetType
#undef cmpSetPair
	
	block(arg);
}

id JXObjectFromJSValue(JSValue *value) {
	__block id obj;
	JXConvertFromJSValue(value, @encode(id), ^(void *ptr) {
		obj = *(id __unsafe_unretained *)ptr;
	});
	return obj;
}

// TODO: Maybe create a JS `TypeWrapper` class that allows you to explicitly set a type.
// If `value` is an instance of that, then return its supplied type.
// Eg. { type: "i", value: 10 } returns "i"
// Also, JXConvertFromJSValue should operate on TypeWrapper.value when a TypeWrapper is supplied
const char *JXInferType(JSValue *value) {
	// TODO: Create JXTypeWrapper or whatever, and uncomment this
//	if (JSValueIsObjectOfClass(value.context.JSGlobalContextRef, value.JSValueRef, JXTypeWrapper)) {
//		return [value[@"type"] toString].UTF8String;
//	}
	if (value.isBoolean) return @encode(BOOL);
	else if (value.isNumber) return @encode(double);
	else return @encode(id);
}
