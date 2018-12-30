//
//  JXFFIInterface.h
//  ObjectiveScript
//
//  Created by Kabir Oberai on 19/11/17.
//  Copyright © 2017 Kabir Oberai. All rights reserved.
//

#import "JXTrampInfo.h"

NS_ASSUME_NONNULL_BEGIN

JSValue *JXCallMethod(Class cls, JSContext *ctx, id obj, NSString *selName, JSValue *args);
JSValue *JXCallFunction(void *sym, NSString *types, uint32_t nargs, const JSValueRef _Nonnull jsArgs[_Nonnull], JSContext *ctx);
JXTrampInfo *JXCreateTramp(JSValue *func, const char *types, __nullable Class superclass);
void JXSwizzle(JSValue *func, Class cls, BOOL isClassMethod, SEL sel, NSString *fallbackTypes);
void * _Nullable JXLoadSymbol(NSString *name, JSValue *library);

NS_ASSUME_NONNULL_END
