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

- (JXPrimitiveType)primitiveType {
    switch (*self.encoding.UTF8String) {
        case _C_CHARPTR:  return JXPrimitiveTypeCharPtr;
        case _C_CLASS:    return JXPrimitiveTypeClass;
        case _C_SEL:      return JXPrimitiveTypeSelector;
        case _C_CHR:      return JXPrimitiveTypeChar;
        case _C_UCHR:     return JXPrimitiveTypeUnsignedChar;
        case _C_SHT:      return JXPrimitiveTypeShort;
        case _C_USHT:     return JXPrimitiveTypeUnsignedShort;
        case _C_INT:      return JXPrimitiveTypeInt;
        case _C_UINT:     return JXPrimitiveTypeUnsignedInt;
        case _C_LNG:      return JXPrimitiveTypeLong;
        case _C_ULNG:     return JXPrimitiveTypeUnsignedLong;
        case _C_LNG_LNG:  return JXPrimitiveTypeLongLong;
        case _C_ULNG_LNG: return JXPrimitiveTypeUnsignedLongLong;
        case _C_FLT:      return JXPrimitiveTypeFloat;
        case _C_DBL:      return JXPrimitiveTypeDouble;
        case _C_BOOL:     return JXPrimitiveTypeBOOL;
        default:          return JXPrimitiveTypeVoid;
    }
}

- (JXTypeDescription *)_descriptionWithPadding:(BOOL)padding {
    NSString *head;
    switch ([self primitiveType]) {
        case JXPrimitiveTypeCharPtr:          return [JXTypeDescription descriptionWithHead:@"char *" tail:@""];
        case JXPrimitiveTypeClass:            head = @"Class"; break;
        case JXPrimitiveTypeSelector:         head = @"SEL"; break;
        case JXPrimitiveTypeChar:             head = @"char"; break;
        case JXPrimitiveTypeUnsignedChar:     head = @"unsigned char"; break;
        case JXPrimitiveTypeShort:            head = @"short"; break;
        case JXPrimitiveTypeUnsignedShort:    head = @"unsigned short"; break;
        case JXPrimitiveTypeInt:              head = @"int"; break;
        case JXPrimitiveTypeUnsignedInt:      head = @"unsigned int"; break;
        case JXPrimitiveTypeLong:             head = @"long"; break;
        case JXPrimitiveTypeUnsignedLong:     head = @"unsigned long"; break;
        case JXPrimitiveTypeLongLong:         head = @"long long"; break;
        case JXPrimitiveTypeUnsignedLongLong: head = @"unsigned long long"; break;
        case JXPrimitiveTypeFloat:            head = @"float"; break;
        case JXPrimitiveTypeDouble:           head = @"double"; break;
        case JXPrimitiveTypeBOOL:             head = @"BOOL"; break;
        case JXPrimitiveTypeVoid:             head = @"void"; break;
    }

    if (padding) head = [head stringByAppendingString:@" "];

    return [JXTypeDescription descriptionWithHead:head tail:@""];
}

@end
