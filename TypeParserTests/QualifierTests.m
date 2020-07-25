//
//  QualifierTests.m
//  TypeParserTests
//
//  Created by Kabir Oberai on 21/07/20.
//  Copyright © 2020 Kabir Oberai. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "JXTypeQualifiers.h"
#import "JXTypeQualifiers+Private.h"

@interface QualifierTests : XCTestCase
@end

@implementation QualifierTests

- (void)testQualifierParsing {
    XCTAssertEqual(JXTypeQualifierForEncoding('j'), JXTypeQualifierVolatile);
    XCTAssertEqual(JXTypeQualifierForEncoding('r'), JXTypeQualifierConst);
    XCTAssertEqual(JXTypeQualifierForEncoding('n'), JXTypeQualifierIn);
    XCTAssertEqual(JXTypeQualifierForEncoding('N'), JXTypeQualifierInout);
    XCTAssertEqual(JXTypeQualifierForEncoding('o'), JXTypeQualifierOut);
    XCTAssertEqual(JXTypeQualifierForEncoding('O'), JXTypeQualifierBycopy);
    XCTAssertEqual(JXTypeQualifierForEncoding('R'), JXTypeQualifierByref);
    XCTAssertEqual(JXTypeQualifierForEncoding('V'), JXTypeQualifierOneway);
    XCTAssertEqual(JXTypeQualifierForEncoding('A'), JXTypeQualifierAtomic);
}

- (void)testInvalidQualifier {
    XCTAssertEqual(JXTypeQualifierForEncoding('X'), JXTypeQualifierNone);
}

- (void)testRemoveQualifiers {
    const char *enc = "rA@";
    JXTypeQualifiers qualifiers = JXRemoveQualifiers(&enc);
    XCTAssertEqual(qualifiers, JXTypeQualifierConst | JXTypeQualifierAtomic);
    XCTAssertEqual(*enc, '@', @"enc was not updated after the qualifiers were stripped");
}

- (void)testRemoveNoQualifiers {
    const char *enc = "@";
    JXTypeQualifiers qualifiers = JXRemoveQualifiers(&enc);
    XCTAssertEqual(qualifiers, JXTypeQualifierNone);
    XCTAssertEqual(*enc, '@', @"enc was updated despite there being no qualifiers");
}

- (void)testOnlyQualifiers {
    const char *enc = "rA";
    JXTypeQualifiers qualifiers = JXRemoveQualifiers(&enc);
    XCTAssertEqual(qualifiers, JXTypeQualifierConst | JXTypeQualifierAtomic);
    XCTAssertEqual(*enc, '\0', @"enc was not moved to the end");
}

- (void)testEmptyQualifierString {
    XCTAssertEqual(JXStringsForTypeQualifiers(JXTypeQualifierNone).count, 0);
}

- (void)testSingleQualifierString {
    XCTAssertEqualObjects(JXStringsForTypeQualifiers(JXTypeQualifierVolatile), @[@"volatile"]);
    XCTAssertEqualObjects(JXStringsForTypeQualifiers(JXTypeQualifierConst), @[@"const"]);
    XCTAssertEqualObjects(JXStringsForTypeQualifiers(JXTypeQualifierIn), @[@"in"]);
    XCTAssertEqualObjects(JXStringsForTypeQualifiers(JXTypeQualifierInout), @[@"inout"]);
    XCTAssertEqualObjects(JXStringsForTypeQualifiers(JXTypeQualifierOut), @[@"out"]);
    XCTAssertEqualObjects(JXStringsForTypeQualifiers(JXTypeQualifierBycopy), @[@"bycopy"]);
    XCTAssertEqualObjects(JXStringsForTypeQualifiers(JXTypeQualifierByref), @[@"byref"]);
    XCTAssertEqualObjects(JXStringsForTypeQualifiers(JXTypeQualifierOneway), @[@"oneway"]);
    XCTAssertEqualObjects(JXStringsForTypeQualifiers(JXTypeQualifierAtomic), @[@"_Atomic"]);
}

- (void)testMultipleQualifierString {
    NSArray *expected = @[@"_Atomic", @"volatile"];
    XCTAssertEqualObjects(JXStringsForTypeQualifiers(JXTypeQualifierVolatile | JXTypeQualifierAtomic), expected);
}

@end
