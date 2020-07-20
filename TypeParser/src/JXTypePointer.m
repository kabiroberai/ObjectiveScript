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

@interface JXTypePointer () <JXConcreteType> @end

@implementation JXTypePointer

+ (BOOL)supportsEncoding:(char)encoding {
    return encoding == _C_PTR || encoding == _C_CHARPTR;
}

- (instancetype)initWithScanner:(NSScanner *)scanner qualifiers:(JXTypeQualifiers)qualifiers {
    self = [super initWithQualifiers:qualifiers];
    if (!self) return nil;

    char start = scanner.currentCharacter;
    if (start == _C_CHARPTR) {
        _type = [[JXTypeBasic alloc] initWithPrimitiveType:JXPrimitiveTypeChar];
        scanner.scanLocation += 1; // eat '*'
    } else {
        scanner.scanLocation += 1; // eat '^'
        if (scanner.currentCharacter == '?') _isFunction = YES;
        _type = [JXType typeWithScanner:scanner];
    }

    return self;
}

- (instancetype)initWithType:(JXType *)type isFunction:(BOOL)isFunction {
    self = [super init];
    if (!self) return nil;

    NSString *encoding = [NSString stringWithFormat:@"^%@%@", isFunction ? @"?" : @"", type.encoding];
    if ([type isKindOfClass:JXTypeBasic.class]) {
        JXTypeBasic *basicType = (JXTypeBasic *)type;
        // `char *` has a special type
        if (basicType.primitiveType == JXPrimitiveTypeChar) {
            encoding = [NSString stringWithFormat:@"%c", _C_CHARPTR];
        }
    }
    _encoding = encoding;
    _type = type;
    _isFunction = isFunction;

    return self;
}

- (JXTypeDescription *)baseDescriptionWithPadding:(BOOL)padding {
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
