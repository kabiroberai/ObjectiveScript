//
//  MethodSignatureTests.m
//  TypeParserTests
//
//  Created by Kabir Oberai on 21/07/20.
//  Copyright © 2020 Kabir Oberai. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TypeParser.h"
#import "JXType+Private.h"

@interface MethodSignatureTests : XCTestCase
@end

@implementation MethodSignatureTests

// just type-based equality. Ignore frame size etc
- (void)assertNSMethodSignature:(NSMethodSignature *)lhs equalTo:(NSMethodSignature *)rhs {
    XCTAssertEqual(strcmp(lhs.methodReturnType, rhs.methodReturnType), 0);
    XCTAssertEqual(lhs.numberOfArguments, rhs.numberOfArguments);
    for (NSUInteger i = 0; i < lhs.numberOfArguments; i++) {
        XCTAssertEqual(strcmp([lhs getArgumentTypeAtIndex:i], [rhs getArgumentTypeAtIndex:i]), 0);
    }
}

- (void)validateRoundTripForEncoding:(NSString *)encoding {
    NSMethodSignature *ns = [NSMethodSignature signatureWithObjCTypes:encoding.UTF8String];
    [self assertNSMethodSignature:[JXMethodSignature signatureWithObjCTypes:encoding  ].NSMethodSignature equalTo:ns];
    [self assertNSMethodSignature:[JXMethodSignature signatureWithNSMethodSignature:ns].NSMethodSignature equalTo:ns];
}

- (void)validateBasicSignature:(JXMethodSignature *)signature {
    XCTAssertEqual([signature.returnType class], [JXTypeBasic class]);
    XCTAssertEqual([(JXTypeBasic *)signature.returnType primitiveType], JXPrimitiveTypeBOOL);
    XCTAssertEqual(signature.argumentTypes.count, 3);
    XCTAssertEqual([signature.argumentTypes[0] class], [JXTypeID class]);
    XCTAssertEqual([signature.argumentTypes[1] class], [JXTypeBasic class]);
    XCTAssertEqual([(JXTypeBasic *)signature.argumentTypes[1] primitiveType], JXPrimitiveTypeSelector);
    XCTAssertEqual([signature.argumentTypes[2] class], [JXTypeBasic class]);
    XCTAssertEqual([(JXTypeBasic *)signature.argumentTypes[2] primitiveType], JXPrimitiveTypeInt);
    XCTAssertEqualObjects(signature.types, @"B@:i");
}

- (void)testBasicSignatureFromTypes {
    NSString *rawEncoding = @"B@:i";
    JXMethodSignature *signature = [JXMethodSignature signatureWithObjCTypes:rawEncoding];
    [self validateBasicSignature:signature];
    [self validateRoundTripForEncoding:rawEncoding];
}

- (void)testBasicSignatureTermination {
    JXMethodSignature *signature = [JXMethodSignature signatureWithObjCTypes:@"B@:i>"];
    XCTAssertNil(signature, @"+[JXMethodSignature signatureWithObjCTypes:] should not support incomplete signatures");
}

- (void)testBasicSignatureWithNumbers {
    NSString *rawEncoding = @"B8@4:8i12";
    JXMethodSignature *signature = [JXMethodSignature signatureWithObjCTypes:rawEncoding];
    [self validateBasicSignature:signature];
    [self validateRoundTripForEncoding:rawEncoding];
}

- (void)testNoNegativeFrameSize {
    XCTAssertNil([JXMethodSignature signatureWithObjCTypes:@"B-2@4:8i12"]);
}

- (void)testNegativeByteOffset {
    // Note: this is not supported by NSMethodSignature, but objc-typeencoding.mm appears to
    // support it
    [self validateBasicSignature:[JXMethodSignature signatureWithObjCTypes:@"B2@-4:8i12"]];
}

- (void)testRegisterParam {
    [self validateBasicSignature:[JXMethodSignature signatureWithObjCTypes:@"B2@+4:8i12"]];
    // Note: This is technically supported by NSMethodSignature but I don't think that
    // objc-typeencoding.mm supports it
    XCTAssertNil([JXMethodSignature signatureWithObjCTypes:@"B2@++4:8i12"]); // doubleplus bad
}

- (void)testBasicSignatureFromJXTypes {
    JXType *returnType = [[JXTypeBasic alloc] initWithPrimitiveType:JXPrimitiveTypeBOOL];
    NSArray<JXType *> *argTypes = @[
        [[JXTypeID alloc] initWithClassName:nil protocols:nil],
        [[JXTypeBasic alloc] initWithPrimitiveType:JXPrimitiveTypeSelector],
        [[JXTypeBasic alloc] initWithPrimitiveType:JXPrimitiveTypeInt],
    ];
    JXMethodSignature *signature = [JXMethodSignature signatureWithReturnType:returnType argumentTypes:argTypes];
    [self validateBasicSignature:signature];
}

- (void)testSignatureWithArrayAndNumbers {
    JXMethodSignature *signature = [JXMethodSignature signatureWithObjCTypes:@"v2@4:6[10@]8"];
    XCTAssertEqual([signature.returnType class], [JXTypeBasic class]);
    XCTAssertEqual([(JXTypeBasic *)signature.returnType primitiveType], JXPrimitiveTypeVoid);
    XCTAssertEqual(signature.argumentTypes.count, 3);
    XCTAssertEqual([signature.argumentTypes[0] class], [JXTypeID class]);
    XCTAssertEqual([signature.argumentTypes[1] class], [JXTypeBasic class]);
    XCTAssertEqual([(JXTypeBasic *)signature.argumentTypes[1] primitiveType], JXPrimitiveTypeSelector);
    XCTAssertEqual([signature.argumentTypes[2] class], [JXTypeArray class]);
    XCTAssertEqual([(JXTypeArray *)signature.argumentTypes[2] count], 10);
    XCTAssertEqual([[(JXTypeArray *)signature.argumentTypes[2] type] class], [JXTypeID class]);
}

@end
