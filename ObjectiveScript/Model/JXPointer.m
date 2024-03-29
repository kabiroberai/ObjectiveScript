//
//  JXPointer.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 06/03/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import <ffi/ffi.h>
#import "JXPointer.h"
#import "JXJSInterop.h"
#import "JXType+FFI.h"

@implementation JXPointer

- (instancetype)initWithVal:(void *)val type:(NSString *)type {
    self = [super init];
    if (self) {
        _val = val;
        _type = type;
    }
    return self;
}

+ (instancetype)pointerWithVal:(void *)val type:(NSString *)type {
    return [[JXPointer alloc] initWithVal:val type:type];
}

- (size_t)size {
    return JXSizeForEncoding(self.type.UTF8String);
}

- (JXPointer *)withType:(NSString *)type {
    return [JXPointer pointerWithVal:self.val type:type];
}

- (JSValue *)jsPropertyForKey:(NSString *)key ctx:(JSContext *)ctx {
    // pointee is a property, the rest are functions

    if ([key isEqualToString:@"Symbol.toPrimitive"]) {

        return [JSValue valueWithObject:^NSString *{
            return [NSString stringWithFormat:@"%p", self.val];
        } inContext:ctx];

    } else if ([key isEqualToString:@"pointee"]) {

        return JXConvertToJSValue(self.val, self.type.UTF8String, ctx, JXInteropOptionDefault);

    } else if ([key isEqualToString:@"advancedBy"]) {

        return [JSValue valueWithObject:^JSValue *(ptrdiff_t n) {
            void *newVal = (char *)self.val + n * self.size;
            // we use [JSContext currentContext] instead of ctx to avoid setting up a retain cycle
            return JXObjectToJSValue([JXPointer pointerWithVal:newVal type:self.type], [JSContext currentContext]);
        } inContext:ctx];

    } else if ([key isEqualToString:@"distanceTo"]) {

        return [JSValue valueWithObject:^ptrdiff_t (JSValue *endJS) {
            JXPointer *end = JXObjectFromJSValue(endJS);
            if (![end.type isEqualToString:self.type]) {
                @throw JXCreateExceptionFormat(@"End type (\"%@\") not equal to callee type (\"%@\")", end.type, self.type);
            }
            // we need to cast size to a signed value, otherwise everything will be promoted to unsigned types
            // and this will overflow if self > end
            return ((char *)end.val - (char *)self.val) / (ssize_t)self.size;
        } inContext:ctx];

    }

    NSInteger num;
    // if key is a number (subscript)
    if ([[NSScanner scannerWithString:key] scanInteger:&num]) {
        // this.advancedBy(n).pointee
        return [[self jsPropertyForKey:@"advancedBy" ctx:ctx] callWithArguments:@[@(num)]][@"pointee"];
    }

    return nil;
}

- (void)setJSProperty:(JSValue *)property forKey:(NSString *)key ctx:(JSContext *)ctx {
    if ([key isEqualToString:@"pointee"]) {

        const char *rawType = self.type.UTF8String;
        JXConvertFromJSValue(property, rawType, ^(void *newVal) {
            memcpy(self.val, newVal, JXSizeForEncoding(rawType));
        });

        return;

    }

    NSInteger num;
    if ([[NSScanner scannerWithString:key] scanInteger:&num]) {
        // this.advancedBy(n).pointee = property
        [[self jsPropertyForKey:@"advancedBy" ctx:ctx] callWithArguments:@[@(num)]][@"pointee"] = property;
    }
}

@end
