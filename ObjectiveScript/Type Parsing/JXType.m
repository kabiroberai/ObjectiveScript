//
//  JXType.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 10/03/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import <objc/runtime.h>
#import "JXType.h"
#import "JXBasicType.h"
#import "JXIDType.h"
#import "JXBitFieldType.h"
#import "JXPointerType.h"
#import "JXStructType.h"
#import "JXUnionType.h"
#import "JXArrayType.h"

@implementation JXType

- (NSString *)stringBetweenStart:(const char *)start end:(const char *)end {
    long len = end - start;
    char str[len + 1];
    strncpy(str, start, len);
    str[len] = 0;
    return @(str);
}

// scan the next number in enc and move enc forward
- (NSUInteger)numberFromEncoding:(const char **)enc {
    NSUInteger num = 0;
    while (isdigit(**enc)) {
        char digit = **enc - '0';
        num = (num * 10) + digit;
        *enc += 1;
    }
    return num;
}

+ (BOOL)supportsEncoding:(char)encoding {
    return NO;
}

- (instancetype)initWithEncoding:(const char **)enc qualifiers:(JXTypeQualifiers)qualifiers {
    self = [super init];
    if (self) {
        _qualifiers = qualifiers;
    }
    return self;
}

// without qualifiers (overriden by subclasses)
- (JXTypeDescription *)_descriptionWithPadding:(BOOL)padding {
    // head comes before the field name, tail comes after
    return [JXTypeDescription descriptionWithHead:@"" tail:@""];
}

// with qualifiers
- (JXTypeDescription *)descriptionWithPadding:(BOOL)padding {
    NSString *qualifiers = JXStringForTypeQualifiers(_qualifiers);
    if (qualifiers) qualifiers = [qualifiers stringByAppendingString:@" "];
    else qualifiers = @"";

    JXTypeDescription *type = [self _descriptionWithPadding:padding];
    return [JXTypeDescription
            descriptionWithHead:[qualifiers stringByAppendingString:type.head]
            tail:type.tail];
}

- (NSString *)description {
    JXTypeDescription *desc = [self descriptionWithPadding:NO];
    return [desc.head stringByAppendingString:desc.tail];
}

@end

JXType *JXTypeForEncoding(const char *enc) {
    return JXTypeWithEncoding(&enc);
}

JXType *JXTypeWithEncoding(const char **enc) {
    static NSArray<Class> *allTypes;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        allTypes = @[
            [JXBasicType class],
            [JXIDType class],
            [JXBitFieldType class],
            [JXPointerType class],
            [JXStructType class],
            [JXUnionType class],
            [JXArrayType class]
        ];
    });

    JXTypeQualifiers qualifiers = JXRemoveQualifiers(enc);

    for (Class type in allTypes) {
        if ([type supportsEncoding:**enc]) {
            return [[type alloc] initWithEncoding:enc qualifiers:qualifiers];
        }
    }
    return nil;
}

#if JX_USE_FFI
@implementation JXType (FFI)

- (ffi_type *)ffiType {
    return NULL;
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
#endif
