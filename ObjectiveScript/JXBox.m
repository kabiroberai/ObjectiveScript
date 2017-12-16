//
//  JXBox.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 15/12/17.
//  Copyright © 2017 Kabir Oberai. All rights reserved.
//

#import "JXBox.h"

@implementation JXBox

- (instancetype)initWithObj:(id)obj {
	self = [super init];
	if (self) {
		_obj = obj;
	}
	return self;
}

+ (id)unboxIfNeeded:(id)obj {
	// If boxed, return box.obj
	if ([obj isKindOfClass:self]) return [obj obj];
	// Else return object itself
	return obj;
}

// If `object` is an NSMutable<Array|Dict|String>, it must be boxed before sending it to JS
// (but there's no proper way to detect mutability, so box immutable ones as well)
+ (id)boxIfNeeded:(id)obj {
	if ([obj isKindOfClass:NSArray.class] ||
		[obj isKindOfClass:NSDictionary.class] ||
		[obj isKindOfClass:NSString.class]) {
		return [[JXBox alloc] initWithObj:obj];
	} else {
		return obj;
	}
}

@end
