//
//  JXJSInterop.h
//  ObjectiveScript
//
//  Created by Kabir Oberai on 14/12/17.
//  Copyright © 2017 Kabir Oberai. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

#define is(type, primitive) (strcmp(type, @encode(primitive)) == 0)

@class JSValue;

/// An enum that defines how a JSObjectRef's data is memory managed
typedef NS_ENUM(NSInteger, JXMemoryMode) {
	/// Don't memory manage the data at all (similar to __unsafe_unretained)
	JXMemoryModeNone,
	/// Don't retain the data, but release it when the associated JSObjectRef is garbage collected
	JXMemoryModeTransfer,
	/// Retain the data, and release it when the associated JSObjectRef is garbage collected
	JXMemoryModeStrong
};

NSArray<NSString *> *JXKeysOfDict(JSValue *dict);

NSException *JXCreateException(NSString *reason);

JSValue *JXConvertToError(NSException *e, JSContext *ctx);
NSException *JXConvertFromError(JSValue *error);

JSValue * _Nullable JXConvertToJSValue(void *val, const char *rawType, JSContext *ctx, JXMemoryMode memoryMode);
JSValue * _Nullable JXObjectToJSValue(id _Nullable val, JSContext *ctx);

JSValue * _Nullable JXUnboxValue(id _Nullable obj, JSContext *ctx);

void JXConvertFromJSValue(JSValue *value, const char *rawType, void (^block)(void *));
id _Nullable JXObjectFromJSValue(JSValue *value);

const char *JXInferType(JSValue *value);

NS_ASSUME_NONNULL_END
