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

- (void)testNativePerformance {
	[self measureBlock:^{
		for (int i = 0; i < 1000000; i++) strcmp("hello", "henlo");
	}];
}

- (void)testJSPerformance {
	JSContext *ctx = JXCreateContext();
	[ctx evaluateScript:@"loadFunc('strcmp', 'i**', true);"];
	
	[self measureBlock:^{
		[ctx evaluateScript:@"for (var i = 0; i < 10000; i++) strcmp('hello', 'henlo');"];
	}];
}

- (void)testHookPerformance {
	JSContext *ctx = JXCreateContext();
	[self measureBlock:^{
		for (int i = 0; i < 200; i++) {
			[ctx evaluateScript:@"hookClass('UIViewController', {}, { 'v@:B-viewDidAppear:':function(){} })"];
		}
	}];
}

// TODO: Add more tests

@end
