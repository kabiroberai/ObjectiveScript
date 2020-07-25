//
//  TypeTests.m
//  TypeParserTests
//
//  Created by Kabir Oberai on 21/07/20.
//  Copyright © 2020 Kabir Oberai. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <objc/runtime.h>
#import "TypeParser.h"
#import "JXType+Private.h"

@interface TypeTests : XCTestCase
@end

@implementation TypeTests

- (void)testInvalidType {
    XCTAssertNil([JXType typeForEncoding:@"$"], @"Invalid type should be nil");
}

- (void)testInvalidSubclassInstantiation {
    XCTAssertNil([JXTypePointer typeForEncoding:@"@"], @"Subclasses should only instantiate with their exact type");
}

- (void)testTypeWithQualifiers {
    JXType *type = [JXType typeForEncoding:@"rAi"];
    XCTAssertEqual(type.qualifiers, JXTypeQualifierConst | JXTypeQualifierAtomic);
    XCTAssertEqual([type class], [JXTypeBasic class]);
    XCTAssertEqual(((JXTypeBasic *)type).primitiveType, JXPrimitiveTypeInt);
}

@end
