//
//  ObjectiveScriptTests.m
//  ObjectiveScriptTests
//
//  Created by Kabir Oberai on 16/12/17.
//  Copyright © 2017 Kabir Oberai. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "ObjectiveScript.h"
#import "JXJSInterop.h"

JSContext *JXCreateContext(void);

@interface ObjectiveScriptTests : XCTestCase

@end

@implementation ObjectiveScriptTests {
	JSContext *_ctx;
}

- (void)setUp {
    [super setUp];
	_ctx = JXCreateContext();
}

- (void)tearDown {
	_ctx = nil;
    [super tearDown];
}

- (void)testCtxExists {
	XCTAssertNotNil(_ctx, @"ctx is nil");
}

// TODO: Add more tests

@end
