//
//  BasicTypeTests.m
//  TypeParserTests
//
//  Created by Kabir Oberai on 21/07/20.
//  Copyright © 2020 Kabir Oberai. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <objc/runtime.h>
#import "TypeParser.h"
#import "JXType+Private.h"

@interface BasicTypeTests : XCTestCase
@end

@implementation BasicTypeTests

- (void)assertEncoding:(char)enc isPrimitive:(JXPrimitiveType)primitive {
    JXTypeBasic *type = [JXTypeBasic typeForEncoding:[NSString stringWithFormat:@"%c", enc]];
    XCTAssertEqual([type class], [JXTypeBasic class], @"Expected %c to be a basic type", enc);
    XCTAssertEqual([(JXTypeBasic *)type primitiveType], primitive);
    XCTAssertEqual(type.qualifiers, JXTypeQualifierNone);

    NSString *expectedEncoding = [NSString stringWithFormat:@"%c", enc];
    XCTAssertEqualObjects(type.encoding, expectedEncoding);
}

- (void)testBasicTypes {
    [self assertEncoding:_C_CLASS isPrimitive:JXPrimitiveTypeClass];
    [self assertEncoding:_C_SEL isPrimitive:JXPrimitiveTypeSelector];
    [self assertEncoding:_C_CHR isPrimitive:JXPrimitiveTypeChar];
    [self assertEncoding:_C_UCHR isPrimitive:JXPrimitiveTypeUnsignedChar];
    [self assertEncoding:_C_SHT isPrimitive:JXPrimitiveTypeShort];
    [self assertEncoding:_C_USHT isPrimitive:JXPrimitiveTypeUnsignedShort];
    [self assertEncoding:_C_INT isPrimitive:JXPrimitiveTypeInt];
    [self assertEncoding:_C_UINT isPrimitive:JXPrimitiveTypeUnsignedInt];
    [self assertEncoding:_C_LNG isPrimitive:JXPrimitiveTypeLong];
    [self assertEncoding:_C_ULNG isPrimitive:JXPrimitiveTypeUnsignedLong];
    [self assertEncoding:_C_LNG_LNG isPrimitive:JXPrimitiveTypeLongLong];
    [self assertEncoding:_C_ULNG_LNG isPrimitive:JXPrimitiveTypeUnsignedLongLong];
    [self assertEncoding:_C_FLT isPrimitive:JXPrimitiveTypeFloat];
    [self assertEncoding:_C_DBL isPrimitive:JXPrimitiveTypeDouble];
    [self assertEncoding:_C_BOOL isPrimitive:JXPrimitiveTypeBOOL];
    [self assertEncoding:_C_VOID isPrimitive:JXPrimitiveTypeVoid];
    [self assertEncoding:_C_UNDEF isPrimitive:JXPrimitiveTypeVoid];
}

- (void)testTypeDescription {
    JXTypeBasic *type = [[JXTypeBasic alloc] initWithPrimitiveType:JXPrimitiveTypeInt];
    XCTAssertNotNil(type);

    JXTypeDescription *descNoPadding = [type descriptionWithPadding:NO];
    XCTAssertEqualObjects(descNoPadding.head, @"int");
    XCTAssertEqualObjects(descNoPadding.tail, @"");

    JXTypeDescription *descWithPadding = [type descriptionWithPadding:YES];
    XCTAssertEqualObjects(descWithPadding.head, @"int ");
    XCTAssertEqualObjects(descWithPadding.tail, @"");
}

- (void)testTypeDescriptionWithQualifiers {
    JXTypeBasic *type = [JXTypeBasic typeForEncoding:@"rAi"];
    XCTAssertNotNil(type);

    JXTypeDescription *descNoPadding = [type descriptionWithPadding:NO];
    XCTAssertEqualObjects(descNoPadding.head, @"int _Atomic const");
    XCTAssertEqualObjects(descNoPadding.tail, @"");

    JXTypeDescription *descWithPadding = [type descriptionWithPadding:YES];
    XCTAssertEqualObjects(descWithPadding.head, @"int _Atomic const ");
    XCTAssertEqualObjects(descWithPadding.tail, @"");
}

- (void)testInvalidBasicType {
    XCTAssertNil([JXTypeBasic typeForEncoding:@"$"]);
}

- (void)testBasicTypeCreation {
    JXTypeBasic *type = [[JXTypeBasic alloc] initWithPrimitiveType:JXPrimitiveTypeInt];
    XCTAssertEqual(type.primitiveType, JXPrimitiveTypeInt);
    XCTAssertEqualObjects(type.encoding, @"i");
}

@end
