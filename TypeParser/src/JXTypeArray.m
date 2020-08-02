//
//  JXTypeArray.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 10/03/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import <objc/runtime.h>
#import "JXTypeArray.h"
#import "JXTypePointer.h"

@interface JXTypeArray () <JXConcreteType> @end

@implementation JXTypeArray

+ (BOOL)supportsEncoding:(char)encoding {
    return encoding == _C_ARY_B;
}

- (instancetype)initWithScanner:(NSScanner *)scanner qualifiers:(JXTypeQualifiers)qualifiers {
    self = [super initWithQualifiers:qualifiers];
    if (!self) return nil;

    scanner.scanLocation += 1; // eat '['

    unsigned long long count;
    if (![scanner scanUnsignedLongLong:&count]) return nil;
    _count = (NSUInteger)count;

    _type = [JXType typeWithScanner:scanner];

    // eat ']'
    if (![scanner scanString:@"]" intoString:nil]) return nil;

    return self;
}

- (instancetype)initWithCount:(NSUInteger)count type:(JXType *)type {
    self = [super init];
    if (!self) return nil;

    _encoding = [NSString stringWithFormat:@"[%lu%@]", (long)count, type.encoding];
    _count = count;
    _type = type;

    return self;
}

- (JXTypeDescription *)baseDescriptionWithOptions:(JXTypeDescriptionOptions *)options {
    NSString *tail = [NSString stringWithFormat:@"[%lu]", (long)self.count];
    return [[self.type descriptionWithOptions:options]
            sandwiching:[JXTypeDescription descriptionWithTail:tail]];
}

@end
