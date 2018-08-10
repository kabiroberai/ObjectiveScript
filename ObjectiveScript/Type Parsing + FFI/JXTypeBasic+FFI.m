//
//  JXTypeBasic+FFI.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 29/07/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import "JXTypeBasic+FFI.h"
#import <objc/runtime.h>

@implementation JXTypeBasic (FFI)

- (ffi_type *)_ffiType {
    switch (*self.encoding.UTF8String) {
        case _C_CLASS:
        case _C_SEL:
        case _C_CHARPTR:  return &ffi_type_pointer;
        case _C_CHR:      return &ffi_type_sint8;
        case _C_UCHR:     return &ffi_type_uint8;
        case _C_SHT:      return &ffi_type_sint16;
        case _C_USHT:     return &ffi_type_uint16;
        case _C_INT:
        case _C_LNG:      return &ffi_type_sint32;
        case _C_UINT:
        case _C_ULNG:     return &ffi_type_uint32;
        case _C_LNG_LNG:  return &ffi_type_sint64;
        case _C_ULNG_LNG: return &ffi_type_uint64;
        case _C_FLT:      return &ffi_type_float;
        case _C_DBL:      return &ffi_type_double;
        case _C_BOOL:     return &ffi_type_sint8;
        case _C_VOID:     return &ffi_type_void;
        default:          return NULL;
    }
}

@end
