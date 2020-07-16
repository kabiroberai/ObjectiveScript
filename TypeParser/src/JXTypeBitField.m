//
//  JXTypeBitField.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 12/03/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import <objc/runtime.h>
#import "JXTypeBitField.h"

@implementation JXTypeBitField

+ (BOOL)supportsEncoding:(char)encoding {
    return encoding == _C_BFLD;
}

- (instancetype)initWithEncoding:(const char **)enc qualifiers:(JXTypeQualifiers)qualifiers {
    self = [super initWithEncoding:enc qualifiers:qualifiers];
    if (self) {
        const char *encStart = *enc;

        *enc += 1; // eat 'b'

        _bits = [self numberFromEncoding:enc];

        _encoding = [self stringBetweenStart:encStart end:*enc];
    }
    return self;
}

- (instancetype)initWithBits:(NSUInteger)bits {
    NSString *str = [NSString stringWithFormat:@"%c%lu", _C_BFLD, (long)bits];
    const char *enc = str.UTF8String;
    self = [super initWithEncoding:&enc qualifiers:JXTypeQualifierNone];
    if (self) {
        _encoding = str;
        _bits = bits;
    }
    return self;
}

- (JXTypeDescription *)_descriptionWithPadding:(BOOL)padding {
    return [JXTypeDescription
            descriptionWithHead:[@"unsigned int" stringByAppendingString: padding ? @" " : @""]
            tail:[NSString stringWithFormat:@":%lu", (long)self.bits]];
}

@end
