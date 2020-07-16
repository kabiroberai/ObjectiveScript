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

@implementation JXTypeArray

+ (BOOL)supportsEncoding:(char)encoding {
    return encoding == _C_ARY_B;
}

- (instancetype)initWithEncoding:(const char **)enc qualifiers:(JXTypeQualifiers)qualifiers {
    self = [super initWithEncoding:enc qualifiers:qualifiers];
    if (self) {
        const char *encStart = *enc;

        // eat '['
        *enc += 1;

        _count = [self numberFromEncoding:enc];

        _type = JXTypeWithEncoding(enc);

        // eat ']'
        *enc += 1;

        _encoding = [self stringBetweenStart:encStart end:*enc];
    }
    return self;
}

- (instancetype)initWithCount:(NSUInteger)count type:(JXType *)type {
    NSString *encoding = [NSString stringWithFormat:@"[%lu%@]", (long)count, type.encoding];
    const char *enc = encoding.UTF8String;
    self = [super initWithEncoding:&enc qualifiers:JXTypeQualifierNone];
    if (self) {
        _encoding = encoding;
        _count = count;
        _type = type;
    }
    return self;
}

- (JXTypeDescription *)_descriptionWithPadding:(BOOL)padding {
    JXTypeDescription *subDescription = [self.type descriptionWithPadding:padding];
    return [JXTypeDescription
            descriptionWithHead:subDescription.head
            tail:[NSString stringWithFormat:@"[%lu]%@", (long)self.count, subDescription.tail]];
}

@end
