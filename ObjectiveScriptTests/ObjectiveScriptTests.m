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

- (void)testMsgSend {
	UILabel *label = [UILabel new];
	[_ctx[@"msgSend"] callWithArguments:@[label, @"setText:", @"new text!"]];
	XCTAssert([label.text isEqualToString:@"new text!"]);
	NSString *changed = @"changed text 🙂";
	label.text = changed;
	
	JSValue *jsResp = [_ctx[@"msgSend"] callWithArguments:@[label, @"text"]];
	NSString *res = JXObjectFromJSValue(jsResp);
	XCTAssert([res isEqualToString:changed]);
}

- (void)testStringBoxing {
	NSString *val = @"hello";
	id maybeBoxed = [JXBox boxIfNeeded:val];
	XCTAssert([maybeBoxed isKindOfClass:JXBox.class]);
	XCTAssert([[maybeBoxed obj] isEqualToString:val]);
	
	id unboxed = [JXBox unboxIfNeeded:maybeBoxed];
	XCTAssert([unboxed isKindOfClass:NSString.class]);
	XCTAssert([unboxed isEqualToString:val]);
	
	NSMutableString *mutable = [@"hey" mutableCopy];
	id mutableMaybeBoxed = [JXBox boxIfNeeded:mutable];
	XCTAssert([mutableMaybeBoxed isKindOfClass:JXBox.class]);
}

// TODO: Add tests for classes, associated objects, orig

- (void)testArrayBoxing {
	NSArray *val = @[@"foo", @(1)];
	id maybeBoxed = [JXBox boxIfNeeded:val];
	XCTAssert([maybeBoxed isKindOfClass:JXBox.class]);
	XCTAssert([[maybeBoxed obj] isKindOfClass:NSArray.class]);
	
	id unboxed = [JXBox unboxIfNeeded:maybeBoxed];
	XCTAssert([unboxed isKindOfClass:NSArray.class]);
	XCTAssert([unboxed isEqualToArray:val]);
}

// TODO: Add more boxing tests

// TODO: Add tests for JXConvert<To|From>JSValue

@end
