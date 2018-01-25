//
//  JXTrampInfo.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 16/11/17.
//  Copyright © 2017 Kabir Oberai. All rights reserved.
//

#import "JXTrampInfo.h"
#import "JXFFITypes.h"
#import "Block.h"

@implementation JXTrampInfo {
	JXTrampInfo *_retained;
}

- (instancetype)initWithFunc:(JSValue *)func types:(const char *)types cls:(Class)cls {
	self = [super init];
	if (self) {
		_func = func;
		_types = malloc(sizeof(char) * strlen(types));
		strcpy(_types, types);
		_cls = cls;
	}
	return self;
}

- (void)retainForever {
	// sets up a strong reference cycle on purpose
	_retained = self;
}

- (NSMethodSignature *)sig {
	return [NSMethodSignature signatureWithObjCTypes:_types];
}

- (void)dealloc {
	free(_types);
	JXFreeClosure(_closure);
}

@end
