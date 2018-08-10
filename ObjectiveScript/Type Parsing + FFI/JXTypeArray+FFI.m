//
//  JXTypeArray+FFI.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 29/07/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import "JXTypeArray+FFI.h"

@implementation JXTypeArray (FFI)

- (ffi_type *)_ffiType {
    ffi_type *compoundType = JXAllocateCompoundFFIType(self.count);

    // fill each slot of the compound type with `type`
    for (NSUInteger i = 0; i < self.count; i++) {
        compoundType->elements[i] = [self.type ffiType];
    }

    return compoundType;
}

@end
