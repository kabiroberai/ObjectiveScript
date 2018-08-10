//
//  JXTypeDescription.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 17/03/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import "JXTypeDescription.h"

@implementation JXTypeDescription

- (instancetype)initWithHead:(NSString *)head tail:(NSString *)tail {
    self = [super init];
    if (self) {
        _head = head;
        _tail = tail;
    }
    return self;
}

+ (instancetype)descriptionWithHead:(NSString *)head tail:(NSString *)tail {
    return [[self alloc] initWithHead:head tail:tail];
}

@end
