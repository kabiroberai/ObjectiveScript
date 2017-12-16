//
//  JXHookInfo.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 16/11/17.
//  Copyright © 2017 Kabir Oberai. All rights reserved.
//

#import "JXHookInfo.h"

@implementation JXHookInfo

- (instancetype)initWithOrig:(IMP)orig block:(SwizzleBlock)block {
	self = [super init];
	if (self) {
		_orig = orig;
		_block = block;
	}
	return self;
}

@end
