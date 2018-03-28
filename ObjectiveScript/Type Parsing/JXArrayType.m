//
//  JXArrayType.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 10/03/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import <objc/runtime.h>
#import "JXArrayType.h"
#import "JXPointerType.h"

@implementation JXArrayType

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

- (JXTypeDescription *)_descriptionWithPadding:(BOOL)padding {
    JXTypeDescription *subDescription = [self.type descriptionWithPadding:padding];
    return [JXTypeDescription
            descriptionWithHead:subDescription.head
            tail:[NSString stringWithFormat:@"[%lu]%@", (long)self.count, subDescription.tail]];
}

@end

#if JX_USE_FFI
@implementation JXArrayType (FFI)

- (ffi_type *)ffiType {
    ffi_type *compoundType = JXAllocateCompoundFFIType(self.count);

    // fill each slot of the compound type with `type`
    for (NSUInteger i = 0; i < self.count; i++) {
        compoundType->elements[i] = [self.type ffiType];
    }

    return compoundType;
}

@end
#endif
