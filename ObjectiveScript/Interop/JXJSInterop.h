//
//  JXJSInterop.h
//  ObjectiveScript
//
//  Created by Kabir Oberai on 14/12/17.
//  Copyright © 2017 Kabir Oberai. All rights reserved.
//

#import <JavaScriptCore/JavaScriptCore.h>

NS_ASSUME_NONNULL_BEGIN

#define is(type, primitive) (strcmp(type, @encode(primitive)) == 0)

typedef NS_OPTIONS(NSUInteger, JXInteropOptions) {
    JXInteropOptionNone = 0,
    JXInteropOptionRetain = 1 << 0,
    JXInteropOptionAutorelease = 1 << 1,
    JXInteropOptionCopyStructs = 1 << 2,
};

NSArray<NSString *> *JXKeysOfDict(JSValue *dict);

void JXThrow(NSException *e);

NSException *JXCreateException(NSString *reason);
NSException *JXCreateExceptionFormat(NSString *format, ...) NS_FORMAT_FUNCTION(1,2);

JSValue *JXConvertToError(NSException *e, JSContext *ctx);
NSException *JXConvertFromError(JSValue *error);

JSValue * _Nullable JXConvertToJSValue(void *val, const char *rawType, JSContext *ctx, JXInteropOptions options);
JSValue * _Nullable JXObjectToJSValue(id _Nullable val, JSContext *ctx);

void JXConvertFromJSValue(JSValue *value, const char *rawType, void (^block)(void *));
id _Nullable JXObjectFromJSValue(JSValue *value);

JSValue * _Nullable JXCastValue(JSValue *value, const char *rawType);
NSString * _Nullable JXGuessEncoding(JSValue *value);

JSValue * _Nullable JXUnboxValue(id _Nullable obj, JSContext *ctx);

NS_ASSUME_NONNULL_END
