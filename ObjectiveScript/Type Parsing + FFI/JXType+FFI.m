//
//  JXType+FFI.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 29/07/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import "JXType+FFI.h"

@implementation JXType (FFI)

- (ffi_type *)ffiType {
    if ([self conformsToProtocol:@protocol(JXFFIType)]) {
        return [(id<JXFFIType>)self _ffiType];
    } else {
        return NULL;
    }
}

@end

size_t JXSizeForEncoding(const char *enc) {
    JXType *type = JXTypeForEncoding(enc);
    ffi_type *ffiType = [type ffiType];

    size_t size;
    if (ffiType->type == FFI_TYPE_STRUCT) {
        // populate ffiType's size if it's a struct
        ffi_get_struct_offsets(FFI_DEFAULT_ABI, ffiType, NULL);
        size = ffiType->size;
        JXFreeFFIType(ffiType);
    } else {
        size = ffiType->size;
    }

    return size;
}

ffi_type *JXAllocateCompoundFFIType(size_t len) {
    ffi_type *compoundType = malloc(sizeof(ffi_type));
    // alignment and size are automatically set by libffi during ffi_prep_cif
    compoundType->type = FFI_TYPE_STRUCT;
    // has to be a null-terminated list, so add one more element than required
    compoundType->elements = malloc((len + 1) * sizeof(ffi_type *));
    compoundType->elements[len] = NULL; // set the last element to NULL
    return compoundType;
}

void JXFreeFFIType(ffi_type *type) {
    // don't free unless it's a struct
    if (type->type != FFI_TYPE_STRUCT) return;
    // first free all nested structs
    for (ffi_type **el = type->elements; *el; el++) {
        JXFreeFFIType(*el);
    }
    // then free the elements array
    free(type->elements);
    // then free the struct itself
    free(type);
}
