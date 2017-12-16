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

#define isType(primitive) is(type, primitive)

// [to|from]JSValue Inspired by Aspects and https://github.com/ReactiveCocoa/ReactiveCocoa/blob/db51e2bb2ceb7464db71b190cf133105e83dd378/ReactiveObjC/NSInvocation%2BRACTypeParsing.m

static const char *extractType(const char *type) {
	switch (*type) {
		case 'j':
		case 'r':
		case 'n':
		case 'N':
		case 'o':
		case 'O':
		case 'R':
		case 'V': return extractType(++type);
		default : return type;
	}
}

JSValue *_JXConvertToJSValue(void *val, const char *rawType, JSContext *ctx, BOOL transferOwnership) {
	if (val == nil) return nil;
	
	const char *type = extractType(rawType);
	id object;
	
#define cmpSet(primitive) else if (isType(primitive)) object = @(*(primitive *)val);
#define cmpSetPair(primitive) cmpSet(primitive) cmpSet(unsigned primitive)
	
	// TODO: __unsafe_unretained/__strong/__weak/__autoreleasing here?
	if (isType(id) || isType(Class) || isType(void (^)(void))) {
		void *idVal = *(void **)val;
		if (transferOwnership) {
			object = (__bridge_transfer id)idVal;
		} else {
			object = (__bridge id)idVal;
		}
	}
	//	else if (isType(void (^)(void))) object = [*(__unsafe_unretained id *)val copy]; // TODO: Maybe add this if needed?
	else if (isType(SEL)) object = NSStringFromSelector(val);
	// TODO: Add support for structs in general instead of just rect/size/point
	else if (isType(CGRect)) return [JSValue valueWithRect:*(CGRect *)val inContext:ctx];
	else if (isType(CGSize)) return [JSValue valueWithSize:*(CGSize *)val inContext:ctx];
	else if (isType(CGPoint)) return [JSValue valueWithPoint:*(CGPoint *)val inContext:ctx];
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
	
	// box object if it's a array/dict/string
	if (isType(id)) {
		object = [JXBox boxIfNeeded:object];
	}
	
	return [JSValue valueWithObject:object inContext:ctx];
}

void JXConvertFromJSValue(JSValue *value, const char *rawType, void (^block)(void *)) {
	if (value.isUndefined) return;
	
	const char *type = extractType(rawType);
	
	// Set obj to an unboxed object version of value
	id obj = [JXBox unboxIfNeeded:[value toObject]];
	// null in JS is passed to objc as NSNull, so convert it to nil
	if ([obj isKindOfClass:NSNull.class]) obj = nil;
	
	void *arg;
	
	// primitive = methodValue
#define cmpSet(primitive, method) else if (isType(primitive)) { \
	primitive num = [(NSNumber*)obj method##Value]; \
	arg = &num; \
}
	// primitive = primitiveValue
#define cmpSetType(primitive) cmpSet(primitive, primitive)
	// primitive = primitiveValue; unsigned primitive = unsignedValue
#define cmpSetPair(primitive, Primitive) cmpSetType(primitive) cmpSet(unsigned primitive, unsigned##Primitive)
	
	if (isType(id) || isType(Class) || isType(void (^)(void))) arg = &obj;
//	else if (isType(void (^)(void))) { // TODO: Figure out if this is needed
//		id blck = [obj copy];
//		arg = &blck;
//	}
	else if (isType(SEL)) {
		SEL sel = NSSelectorFromString(obj);
		arg = &sel;
	} else if (isType(char *)) {
		const char *str = [obj UTF8String];
		arg = &str;
	} else if (isType(CGRect)) {
		// TODO: Add support for structs in general instead of just rect/size/point
		CGRect val = [value toRect];
		arg = &val;
	} else if (isType(CGSize)) {
		CGSize val = [value toSize];
		arg = &val;
	} else if (isType(CGPoint)) {
		CGPoint val = [value toPoint];
		arg = &val;
	}
	cmpSetPair(char, Char)
	cmpSetPair(short, Short)
	cmpSetPair(int, Int)
	cmpSetPair(long, Long)
	cmpSet(long long, longLong)
	cmpSet(unsigned long long, unsignedLongLong)
	cmpSetType(float)
	cmpSetType(double)
	cmpSet(bool, bool) // Otherwise method would be _BoolValue
	else {
		id val = nil;
		arg = &val;
	}
	
#undef cmpSet
#undef cmpSetType
#undef cmpSetPair
	
	block(arg);
}

JSValue *JXConvertToJSValue(void *val, const char *rawType, JSContext *ctx) {
	return _JXConvertToJSValue(val, rawType, ctx, NO);
}

id JXObjectFromJSValue(JSValue *value) {
	__block id obj;
	JXConvertFromJSValue(value, @encode(id), ^(void *ptr) {
		obj = *(__autoreleasing id *)ptr;
	});
	return obj;
}
