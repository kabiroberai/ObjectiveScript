//
//  JXTypeStruct+FFI.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 29/07/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import "JXTypeStruct+FFI.h"

@implementation JXTypeStruct (FFI)

- (ffi_type *)_ffiType {
    if (!self.types) return NULL;

    NSUInteger len = self.types.count;

    ffi_type *compoundType = JXAllocateCompoundFFIType(len);

    // fill each slot of the compound type with the correct FFI type
    for (NSUInteger i = 0; i < len; i++) {
        JXType *type = self.types[i];
        compoundType->elements[i] = [type ffiType];
    }

    return compoundType;
}

@end
