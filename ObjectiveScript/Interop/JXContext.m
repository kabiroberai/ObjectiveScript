//
//  JXContext.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 30/11/19.
//  Copyright © 2019 Kabir Oberai. All rights reserved.
//

#import "JXContext.h"

@implementation JXContext

- (instancetype)initWithConfiguration:(JXConfiguration *)configuration {
    self = [super init];
    if (!self) return nil;

    _configuration = configuration;

    _structDefs = [NSMutableDictionary new];
    _associatedObjects = [NSMutableDictionary new];
    _symbols = [NSMutableDictionary new];

    return self;
}

@end
