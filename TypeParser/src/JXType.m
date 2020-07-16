//
//  JXType.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 10/03/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import "JXType.h"
#import "JXTypeBasic.h"
#import "JXTypeID.h"
#import "JXTypeBitField.h"
#import "JXTypePointer.h"
#import "JXTypeStruct.h"
#import "JXTypeUnion.h"
#import "JXTypeArray.h"

@implementation JXType

+ (BOOL)supportsEncoding:(char)encoding {
    return NO;
}

- (instancetype)initWithEncoding:(const char **)enc qualifiers:(JXTypeQualifiers)qualifiers {
    self = [super init];
    if (self) {
        _qualifiers = qualifiers;
    }
    return self;
}

- (JXTypeDescription *)_descriptionWithPadding:(BOOL)padding {
    // head comes before the field name, tail comes after
    return [JXTypeDescription descriptionWithHead:@"" tail:@""];
}

- (JXTypeDescription *)descriptionWithPadding:(BOOL)padding {
    NSString *qualifiers = JXStringForTypeQualifiers(_qualifiers);
    if (qualifiers) qualifiers = [qualifiers stringByAppendingString:@" "];
    else qualifiers = @"";

    JXTypeDescription *type = [self _descriptionWithPadding:padding];
    return [JXTypeDescription
            descriptionWithHead:[qualifiers stringByAppendingString:type.head]
            tail:type.tail];
}

- (NSString *)description {
    JXTypeDescription *desc = [self descriptionWithPadding:NO];
    return [desc.head stringByAppendingString:desc.tail];
}

- (NSString *)stringBetweenStart:(const char *)start end:(const char *)end {
    long len = end - start;
    char str[len + 1];
    strncpy(str, start, len);
    str[len] = 0;
    return @(str);
}

// scan the next number in enc and move enc forward
- (NSUInteger)numberFromEncoding:(const char **)enc {
    NSUInteger num = 0;
    while (isdigit(**enc)) {
        char digit = **enc - '0';
        num = (num * 10) + digit;
        *enc += 1;
    }
    return num;
}

@end

JXType *JXTypeVoid() {
    return JXTypeForEncoding(@encode(void));
}

JXType *JXTypeForEncoding(const char *enc) {
    return JXTypeWithEncoding(&enc);
}

JXType *JXTypeWithEncoding(const char **enc) {
    static NSArray<Class> *allTypes;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        allTypes = @[
            [JXTypeBasic class],
            [JXTypeID class],
            [JXTypeBitField class],
            [JXTypePointer class],
            [JXTypeStruct class],
            [JXTypeUnion class],
            [JXTypeArray class]
        ];
    });

    JXTypeQualifiers qualifiers = JXRemoveQualifiers(enc);

    for (Class type in allTypes) {
        if ([type supportsEncoding:**enc]) {
            return [[type alloc] initWithEncoding:enc qualifiers:qualifiers];
        }
    }
    return nil;
}
