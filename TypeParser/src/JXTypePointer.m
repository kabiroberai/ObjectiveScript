//
//  JXTypePointer.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 10/03/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import "JXTypePointer.h"
#import "JXTypeBasic.h"
#import <objc/runtime.h>

@implementation JXTypePointer

+ (BOOL)supportsEncoding:(char)encoding {
    return encoding == _C_PTR || encoding == _C_CHARPTR;
}

- (instancetype)initWithEncoding:(const char **)enc qualifiers:(JXTypeQualifiers)qualifiers {
    self = [super initWithEncoding:enc qualifiers:qualifiers];
    if (self) {
        const char *encStart = *enc;

        if (**enc == _C_CHARPTR) {
            _type = JXTypeForEncoding(@encode(char));
            *enc += 1; // eat '*'
        } else {
            *enc += 1; // eat '^'

            // ^? represents a function
            if (**enc == '?') _isFunction = YES;

            _type = JXTypeWithEncoding(enc);
        }

        _encoding = [self stringBetweenStart:encStart end:*enc];
    }
    return self;
}

- (instancetype)initWithType:(JXType *)type isFunction:(BOOL)isFunction {
    NSString *encoding = [NSString stringWithFormat:@"^%@%@", isFunction ? @"?" : @"", type.encoding];
    if ([type isKindOfClass:JXTypeBasic.class]) {
        JXTypeBasic *basicType = (JXTypeBasic *)type;
        // `char *` has a special type
        if (basicType.primitiveType == JXPrimitiveTypeChar) {
            encoding = [NSString stringWithFormat:@"%c", _C_CHARPTR];
        }
    }

    const char *enc = encoding.UTF8String;
    self = [super initWithEncoding:&enc qualifiers:JXTypeQualifierNone];
    if (self) {
        _encoding = encoding;
        _type = type;
        _isFunction = isFunction;
    }
    return self;
}

- (JXTypeDescription *)_descriptionWithPadding:(BOOL)padding {
    if (self.isFunction) {
        return [JXTypeDescription descriptionWithHead:@"void (*" tail:@")(void)"];
    }
    // we want padding before the pointer if possible
    JXTypeDescription *subDescription = [self.type descriptionWithPadding:YES];
    return [JXTypeDescription
            descriptionWithHead:[subDescription.head stringByAppendingString:@"*"]
            tail:subDescription.tail];
}

@end