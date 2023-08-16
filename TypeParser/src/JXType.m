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
#import "JXTypeQualifiers+Private.h"
// we don't actually need this import but at least one non-pch import is
// required to get autocomplete working
#import "JXType+Private.h"

@implementation JXType

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

+ (instancetype)typeWithScanner:(NSScanner *)scanner {
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

    NSUInteger startLoc = scanner.scanLocation;
    JXTypeQualifiers qualifiers = JXRemoveQualifiersWithScanner(scanner);

    // only search subclasses if this was directly called on JXType.class. Else just use that class itself
    NSArray<Class> *searchTypes = ([self class] == [JXType class]) ? allTypes : @[[self class]];
    for (Class type in searchTypes) {
        if (![type supportsEncoding:scanner.currentCharacter]) continue;
        NSUInteger loc = scanner.scanLocation;
        JXType *instance = [[type alloc] initWithScanner:scanner qualifiers:qualifiers];
        if (!instance) {
            scanner.scanLocation = startLoc;
            return nil;
        }
        instance->_encoding = [scanner.string substringWithRange:NSMakeRange(loc, scanner.scanLocation - loc)];
        return instance;
    }

    return nil;
}

+ (instancetype)typeForEncoding:(NSString *)encoding {
    NSScanner *scanner = [NSScanner scannerWithString:encoding];
    scanner.charactersToBeSkipped = [NSCharacterSet new];
    return [self typeWithScanner:scanner];
}

+ (instancetype)typeForEncodingC:(const char *)encoding {
    return [self typeForEncoding:@(encoding)];
}

- (BOOL)orderQualifiersBeforeDescription { return YES; }

- (JXTypeDescription *)descriptionWithOptions:(JXTypeDescriptionOptions *)options {
    if (![self conformsToProtocol:@protocol(JXConcreteType)]) {
        [self doesNotRecognizeSelector:_cmd];
        return nil;
    }

    NSArray<NSString *> *qualifiers = JXStringsForTypeQualifiers(_qualifiers);
    if (qualifiers.count == 0) {
        return [(id<JXConcreteType>)self baseDescriptionWithOptions:options];
    }

    BOOL qualifiersGoBefore = [self orderQualifiersBeforeDescription];

    // we need padding if we need to append qualifiersString after it
    JXTypeDescription *type = [(id<JXConcreteType>)self
                               baseDescriptionWithOptions:[options withPadding:!qualifiersGoBefore]];
    NSString *qualifiersString = [qualifiers componentsJoinedByString:@" "];
    // NOTE: We don't put the qualifiers before the head because in stuff like pointers (and maybe blocks, functions?),
    // we have to put it after. So to keep it uniform, we do that everywhere
    NSString *head = [NSString stringWithFormat:@"%@%@%@%@",
                      qualifiersGoBefore ? qualifiersString : type.head,
                      qualifiersGoBefore ? @" " : @"",
                      qualifiersGoBefore ? type.head : qualifiersString,
                      options.usePadding ? @" " : @""];
    return [JXTypeDescription descriptionWithHead:head tail:type.tail];
}

- (NSString *)description {
    JXTypeDescription *desc = [self descriptionWithOptions:JXTypeDescriptionOptions.defaultOptions];
    return [desc.head stringByAppendingString:desc.tail];
}

@end

__attribute__((used)) static void registerCategories(void) {
    __attribute__((unused)) void *ignore = NSScannerUtilsDummy;
}
