//
//  JXTypeBasic.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 10/03/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import <objc/runtime.h>
#import "JXTypeBasic.h"

@implementation JXTypeBasic

+ (BOOL)supportsEncoding:(char)encoding {
    switch (encoding) {
        case _C_ID:
        case _C_ARY_B:
        case _C_STRUCT_B:
        case _C_UNION_B:
        case _C_BFLD:
        case _C_PTR: return NO;
        default: return YES;
    }
}

- (instancetype)initWithEncoding:(const char **)enc qualifiers:(JXTypeQualifiers)qualifiers {
    self = [super initWithEncoding:enc qualifiers:qualifiers];
    if (self) {
        const char *start = *enc; // get first char and advance string
        *enc += 1;
        _encoding = [self stringBetweenStart:start end:*enc];
    }
    return self;
}

- (JXTypeDescription *)_descriptionWithPadding:(BOOL)padding {
    NSString *head;
    switch (*self.encoding.UTF8String) {
        case _C_CHARPTR:  return [JXTypeDescription descriptionWithHead:@"char *" tail:@""];
        case _C_CLASS:    head = @"Class"; break;
        case _C_SEL:      head = @"SEL"; break;
        case _C_CHR:      head = @"char"; break;
        case _C_UCHR:     head = @"unsigned char"; break;
        case _C_SHT:      head = @"short"; break;
        case _C_USHT:     head = @"unsigned short"; break;
        case _C_INT:      head = @"int"; break;
        case _C_UINT:     head = @"unsigned int"; break;
        case _C_LNG:      head = @"long"; break;
        case _C_ULNG:     head = @"unsigned long"; break;
        case _C_LNG_LNG:  head = @"long long"; break;
        case _C_ULNG_LNG: head = @"unsigned long long"; break;
        case _C_FLT:      head = @"float"; break;
        case _C_DBL:      head = @"double"; break;
        case _C_BOOL:     head = @"BOOL"; break;
        default:          head = @"void"; break;
    }

    if (padding) head = [head stringByAppendingString:@" "];

    return [JXTypeDescription descriptionWithHead:head tail:@""];
}

@end

#if JX_USE_FFI
@implementation JXTypeBasic (FFI)

- (ffi_type *)ffiType {
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
#endif
