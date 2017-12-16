//
//  JXJSInterop.h
//  ObjectiveScript
//
//  Created by Kabir Oberai on 14/12/17.
//  Copyright © 2017 Kabir Oberai. All rights reserved.
//

#import <JavaScriptCore/JavaScriptCore.h>
#import "JXBox.h"

#define is(type, primitive) (strcmp(type, @encode(primitive)) == 0)

JSValue *JXConvertToJSValue(void *val, const char *rawType, JSContext *ctx);
JSValue *_JXConvertToJSValue(void *val, const char *rawType, JSContext *ctx, BOOL transferOwnership);
void JXConvertFromJSValue(JSValue *value, const char *rawType, void (^block)(void *));
id JXObjectFromJSValue(JSValue *value);
