//
//  JXConfiguration.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 30/11/19.
//  Copyright © 2019 Kabir Oberai. All rights reserved.
//

#import "JXConfiguration.h"

@implementation JXConfiguration

- (instancetype)initWithExternalVariables:(NSDictionary<NSString *, id> *)externalVariables
                         exceptionHandler:(nullable void (^)(NSString *))exceptionHandler {
    self = [super init];
    if (!self) return nil;

    _externalVariables = externalVariables;
    _exceptionHandler = exceptionHandler;

    return self;
}

@end
