//
//  JXSymbol.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 25/01/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import "JXSymbol.h"

@implementation JXSymbol

- (instancetype)initWithSymbol:(void *)symbol types:(NSString *)types {
	self = [super init];
	if (self) {
		_symbol = symbol;
		_types = types;
	}
	return self;
}

@end
