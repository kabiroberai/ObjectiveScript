//
//  JXTypeStruct.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 10/03/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import <objc/runtime.h>
#import "JXTypeStruct.h"

@implementation JXTypeStruct

+ (char)startDelim { return _C_STRUCT_B; }
+ (char)endDelim { return _C_STRUCT_E; }
+ (NSString *)typeName { return @"struct"; }

@end

#if JX_USE_FFI
@implementation JXTypeStruct (FFI)

- (ffi_type *)ffiType {
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
#endif
