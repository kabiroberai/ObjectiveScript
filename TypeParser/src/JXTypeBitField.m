//
//  JXTypeBitField.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 12/03/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import <objc/runtime.h>
#import "JXTypeBitField.h"

@interface JXTypeBitField () <JXConcreteType> @end

@implementation JXTypeBitField

+ (BOOL)supportsEncoding:(char)encoding {
    return encoding == _C_BFLD;
}

- (instancetype)initWithScanner:(NSScanner *)scanner qualifiers:(JXTypeQualifiers)qualifiers {
    self = [super initWithQualifiers:qualifiers];
    if (!self) return nil;

    scanner.scanLocation += 1; // eat 'b'

    unsigned long long bits;
    if (![scanner scanUnsignedLongLong:&bits]) return nil;
    _bits = (NSUInteger)bits;

    return self;
}

- (instancetype)initWithBits:(NSUInteger)bits {
    self = [super init];
    if (!self) return nil;

    _encoding = [NSString stringWithFormat:@"%c%lu", _C_BFLD, (long)bits];
    _bits = bits;

    return self;
}

- (JXTypeDescription *)baseDescriptionWithPadding:(BOOL)padding {
    return [JXTypeDescription
            descriptionWithHead:[@"unsigned int" stringByAppendingString: padding ? @" " : @""]
            tail:[NSString stringWithFormat:@":%lu", (long)self.bits]];
}

@end
