//
//  JXMethodSignature.m
//  TypeParser
//
//  Created by Kabir Oberai on 20/07/20.
//  Copyright © 2020 Kabir Oberai. All rights reserved.
//

#import "JXMethodSignature.h"
#import "JXMethodSignature+Private.h"

@implementation JXMethodSignature

- (instancetype)initWithScanner:(NSScanner *)scanner {
    self = [super init];
    if (!self) return nil;

    // https://github.com/opensource-apple/objc4/blob/master/runtime/objc-typeencoding.mm

    JXType *returnType = [JXType typeWithScanner:scanner];
    if (!returnType) return nil;
    _returnType = returnType;

    // eat argument frame size
    BOOL hasNumbers = [scanner scanUnsignedLongLong:nil];

    NSMutableArray *argumentTypes = [NSMutableArray new];
    while (!scanner.isAtEnd) {
        JXType *argumentType = [JXType typeWithScanner:scanner];
        if (!argumentType) {
            // if we're parsing a method signature embedded into a larger string, for example
            // <signature> in a block, we might've gotten to the closing delimiter (in this
            // case the '>'). Don't return nil, we'll let the caller decide whether or not
            // an incomplete parse is a failure or just an indication they've reached the
            // sentinel. Note that we don't need to backtrack scanner as typeWithScanner
            // does that for us
            break;
        }
        [argumentTypes addObject:argumentType];

        // eat byte offset if needed. That this can be negative, so don't use `scanUnsigned...`. This
        // also accepts + at the beginning, so GNU runtime register parameter indicators are parsed
        // (although they're probably not used on Darwin)
        if (hasNumbers && ![scanner scanInteger:nil]) return nil;
    }
    _argumentTypes = [argumentTypes copy];

    return self;
}

- (instancetype)initWithObjCTypes:(NSString *)types {
    NSScanner *scanner = [NSScanner scannerWithString:types];
    scanner.charactersToBeSkipped = [NSCharacterSet new];
    self = [self initWithScanner:scanner];
    if (!scanner.isAtEnd) {
        // while initWithScanner supports embedded method signatures, this method implies
        // that the full string needs to be parsed. If it hasn't been parsed, that's an
        // error
        return nil;
    }
    return self;
}

- (instancetype)initWithNSMethodSignature:(NSMethodSignature *)signature {
    self = [super init];
    if (!self) return nil;

    JXType *returnType = [JXType typeForEncodingC:signature.methodReturnType];
    if (!returnType) return nil;
    _returnType = returnType;

    NSMutableArray *argumentTypes = [NSMutableArray new];
    for (NSUInteger i = 0; i < signature.numberOfArguments; i++) {
        JXType *argumentType = [JXType typeForEncodingC:[signature getArgumentTypeAtIndex:i]];
        if (!argumentType) return nil;
        [argumentTypes addObject:argumentType];
    }
    _argumentTypes = [argumentTypes copy];

    return self;
}

- (instancetype)initWithReturnType:(JXType *)returnType argumentTypes:(NSArray<JXType *> *)argumentTypes {
    self = [super init];
    if (!self) return nil;

    _returnType = returnType;
    _argumentTypes = argumentTypes;

    return self;
}

+ (nullable JXMethodSignature *)signatureWithScanner:(NSScanner *)scanner {
    return [[self alloc] initWithScanner:scanner];
}

+ (nullable JXMethodSignature *)signatureWithObjCTypes:(NSString *)types {
    return [[self alloc] initWithObjCTypes:types];
}

+ (nullable JXMethodSignature *)signatureWithNSMethodSignature:(NSMethodSignature *)signature {
    return [[self alloc] initWithNSMethodSignature:signature];
}

+ (JXMethodSignature *)signatureWithReturnType:(JXType *)returnType argumentTypes:(NSArray<JXType *> *)argumentTypes {
    return [[self alloc] initWithReturnType:returnType argumentTypes:argumentTypes];
}

- (NSString *)types {
    NSMutableString *types = [NSMutableString new];
    [types appendString:self.returnType.encoding];
    for (JXType *type in self.argumentTypes) {
        [types appendString:type.encoding];
    }
    return [types copy];
}

- (NSMethodSignature *)NSMethodSignature {
    return [NSMethodSignature signatureWithObjCTypes:self.types.UTF8String];
}

@end
