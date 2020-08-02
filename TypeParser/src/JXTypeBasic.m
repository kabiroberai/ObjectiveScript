//
//  JXTypeBasic.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 10/03/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import <objc/runtime.h>
#import "JXTypeBasic.h"

@interface JXTypeBasic () <JXConcreteType> @end

@implementation JXTypeBasic

+ (BOOL)supportsEncoding:(char)encoding {
    switch (encoding) {
        case _C_ID:
        case _C_ARY_B:
        case _C_STRUCT_B:
        case _C_UNION_B:
        case _C_BFLD:
        case _C_CHARPTR:
        case _C_PTR: return NO;
        default: return YES;
    }
}

- (instancetype)initWithScanner:(NSScanner *)scanner qualifiers:(JXTypeQualifiers)qualifiers {
    self = [super initWithQualifiers:qualifiers];
    if (!self) return nil;

    char encoding = scanner.currentCharacter;
    scanner.scanLocation += 1;
    switch (encoding) {
        case _C_CLASS:
            _primitiveType = JXPrimitiveTypeClass;
            break;
        case _C_SEL:
            _primitiveType = JXPrimitiveTypeSelector;
            break;
        case _C_CHR:
            _primitiveType = JXPrimitiveTypeChar;
            break;
        case _C_UCHR:
            _primitiveType = JXPrimitiveTypeUnsignedChar;
            break;
        case _C_SHT:
            _primitiveType = JXPrimitiveTypeShort;
            break;
        case _C_USHT:
            _primitiveType = JXPrimitiveTypeUnsignedShort;
            break;
        case _C_INT:
            _primitiveType = JXPrimitiveTypeInt;
            break;
        case _C_UINT:
            _primitiveType = JXPrimitiveTypeUnsignedInt;
            break;
        case _C_LNG:
            _primitiveType = JXPrimitiveTypeLong;
            break;
        case _C_ULNG:
            _primitiveType = JXPrimitiveTypeUnsignedLong;
            break;
        case _C_LNG_LNG:
            _primitiveType = JXPrimitiveTypeLongLong;
            break;
        case _C_ULNG_LNG:
            _primitiveType = JXPrimitiveTypeUnsignedLongLong;
            break;
        case _C_FLT:
            _primitiveType = JXPrimitiveTypeFloat;
            break;
        case _C_DBL:
            _primitiveType = JXPrimitiveTypeDouble;
            break;
        case _C_BOOL:
            _primitiveType = JXPrimitiveTypeBOOL;
            break;
        case _C_VOID:
        case _C_UNDEF:
            _primitiveType = JXPrimitiveTypeVoid;
            break;
        default:
            // we can't return non-nil because otherwise this would become a catch-all,
            // and thus JXMethodSignature's sentinel parsing wouldn't work
            return nil;
    }

    return self;
}

- (instancetype)initWithPrimitiveType:(JXPrimitiveType)primitiveType {
    self = [super init];
    if (!self) return nil;

    _primitiveType = primitiveType;

    char type;
    switch (primitiveType) {
        case JXPrimitiveTypeClass:            type = _C_CLASS; break;
        case JXPrimitiveTypeSelector:         type = _C_SEL; break;
        case JXPrimitiveTypeChar:             type = _C_CHR; break;
        case JXPrimitiveTypeUnsignedChar:     type = _C_UCHR; break;
        case JXPrimitiveTypeShort:            type = _C_SHT; break;
        case JXPrimitiveTypeUnsignedShort:    type = _C_USHT; break;
        case JXPrimitiveTypeInt:              type = _C_INT; break;
        case JXPrimitiveTypeUnsignedInt:      type = _C_UINT; break;
        case JXPrimitiveTypeLong:             type = _C_LNG; break;
        case JXPrimitiveTypeUnsignedLong:     type = _C_ULNG; break;
        case JXPrimitiveTypeLongLong:         type = _C_LNG_LNG; break;
        case JXPrimitiveTypeUnsignedLongLong: type = _C_ULNG_LNG; break;
        case JXPrimitiveTypeFloat:            type = _C_FLT; break;
        case JXPrimitiveTypeDouble:           type = _C_DBL; break;
        case JXPrimitiveTypeBOOL:             type = _C_BOOL; break;
        case JXPrimitiveTypeVoid:             type = _C_VOID; break;
    }
    _encoding = [NSString stringWithFormat:@"%c", type];

    return self;
}

- (JXTypeDescription *)baseDescriptionWithOptions:(JXTypeDescriptionOptions *)options {
    NSString *head;
    switch (self.primitiveType) {
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

    return [JXTypeDescription descriptionWithHead:[head stringByAppendingString:options.padding]];
}

@end
