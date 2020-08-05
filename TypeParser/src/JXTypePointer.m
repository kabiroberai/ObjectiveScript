//
//  JXTypePointer.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 10/03/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import "JXTypePointer.h"
#import "JXTypeBasic.h"
#import "JXTypeArray.h"
#import <objc/runtime.h>

@interface JXTypePointer () <JXConcreteType> @end

@implementation JXTypePointer

+ (BOOL)supportsEncoding:(char)encoding {
    return encoding == _C_PTR || encoding == _C_CHARPTR;
}

- (instancetype)initWithScanner:(NSScanner *)scanner qualifiers:(JXTypeQualifiers)qualifiers {
    self = [super initWithQualifiers:qualifiers];
    if (!self) return nil;

    char start = scanner.currentCharacter;
    if (start == _C_CHARPTR) {
        _type = [[JXTypeBasic alloc] initWithPrimitiveType:JXPrimitiveTypeChar];
        scanner.scanLocation += 1; // eat '*'
    } else {
        scanner.scanLocation += 1; // eat '^'
        if (scanner.currentCharacter == '?') _isFunction = YES;
        _type = [JXType typeWithScanner:scanner];
        if (!_type) return nil;
    }

    return self;
}

- (instancetype)initWithType:(JXType *)type isFunction:(BOOL)isFunction {
    self = [super init];
    if (!self) return nil;

    NSString *encoding = [NSString stringWithFormat:@"^%@%@", isFunction ? @"?" : @"", type.encoding];
    if ([type isKindOfClass:JXTypeBasic.class]) {
        JXTypeBasic *basicType = (JXTypeBasic *)type;
        // `char *` has a special type
        if (basicType.primitiveType == JXPrimitiveTypeChar) {
            encoding = [NSString stringWithFormat:@"%c", _C_CHARPTR];
        }
    }
    _encoding = encoding;
    _type = type;
    _isFunction = isFunction;

    return self;
}

- (BOOL)orderQualifiersBeforeDescription {
    // https://github.com/llvm/llvm-project/blob/1d9b860fb6a85df33fd52fcacc6a5efb421621bd/clang/lib/AST/ASTContext.cpp#L7224
    return !self.isFunction;
}

- (JXTypeDescription *)baseDescriptionWithOptions:(JXTypeDescriptionOptions *)options {
    if (self.isFunction) {
        return [JXTypeDescription descriptionWithHead:@"void (*" tail:@")(void)"];
    }
    // we want padding before the pointer if possible
    JXTypeDescription *subDescription = [self.type descriptionWithOptions:[options withPadding:YES]];

    // Let's consider two types:
    // A: pointer to array of int
    // B: array of pointer to int
    // Naively, we would end up representing them as follows:
    // int *A[5]
    // int *B[5]
    // Because the heads and tails would combine identically in both.
    // The solution to this is putting parens in case A, as follows:
    // int (*A)[5]
    // Effectively, we give higher "precedence" to [] than to *, and so
    // we must parenthesize the pointer to consider it first.
    // http://unixwiz.net/techtips/reading-cdecl.html

    BOOL pointsToArray = [self.type class] == [JXTypeArray class];
    return [subDescription sandwiching:
            [JXTypeDescription descriptionWithHead:pointsToArray ? @"(*" : @"*"
                                              tail:pointsToArray ? @")" : @""]];
}

@end
