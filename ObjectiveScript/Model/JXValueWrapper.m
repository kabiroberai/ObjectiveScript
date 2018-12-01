//
//  JXValueWrapper.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 01/12/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import "JXValueWrapper.h"

@implementation JXValueWrapper

- (instancetype)initWithTypes:(NSString *)types value:(JSValue *)value {
    self = [super init];
    if (self) {
        _types = types;
        _value = value;
    }
    return self;
}

@end
