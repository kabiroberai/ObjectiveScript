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
#import "JXType+Private.h"
#import "JXTypeQualifiers+Private.h"

@implementation JXType

+ (BOOL)supportsEncoding:(char)encoding {
    return NO;
}

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _qualifiers = JXTypeQualifierNone;

    return self;
}

- (instancetype)initWithQualifiers:(JXTypeQualifiers)qualifiers {
    self = [super init];
    if (!self) return nil;

    _qualifiers = qualifiers;

    return self;
}

- (instancetype)initWithScanner:(NSScanner *)scanner qualifiers:(JXTypeQualifiers)qualifiers {
    return [self initWithQualifiers:qualifiers];
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

@end

JXType *JXTypeWithScanner(NSScanner *scanner) {
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

    JXTypeQualifiers qualifiers = JXRemoveQualifiersWithScanner(scanner);

    for (Class type in allTypes) {
        if ([type supportsEncoding:scanner.currentCharacter]) {
            NSUInteger loc = scanner.scanLocation;
            JXType *instance = [[type alloc] initWithScanner:scanner qualifiers:qualifiers];
            if (!instance) {
                scanner.scanLocation = loc;
                return nil;
            }
            instance->_encoding = [scanner.string substringWithRange:NSMakeRange(loc, scanner.scanLocation - loc)];
            return instance;
        }
    }
    return nil;
}

JXType *JXTypeForEncoding(NSString *encoding) {
    NSScanner *scanner = [NSScanner scannerWithString:encoding];
    scanner.charactersToBeSkipped = [NSCharacterSet new];
    return JXTypeWithScanner(scanner);
}

JXType *JXTypeForEncodingC(const char *encoding) {
    return JXTypeForEncoding(@(encoding));
}

__attribute__((used)) static void registerCategories() {
    __attribute__((unused)) void *ignore = NSScannerUtilsDummy;
}
