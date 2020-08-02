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
    if (!self) return nil;
    _head = head;
    _tail = tail;
    return self;
}

- (instancetype)init {
    return [self initWithHead:@"" tail:@""];
}

+ (instancetype)descriptionWithHead:(NSString *)head tail:(NSString *)tail {
    return [[self alloc] initWithHead:head tail:tail];
}

+ (instancetype)descriptionWithHead:(NSString *)head {
    return [self descriptionWithHead:head tail:@""];
}

+ (instancetype)descriptionWithTail:(NSString *)tail {
    return [self descriptionWithHead:@"" tail:tail];
}

- (JXTypeDescription *)sandwiching:(JXTypeDescription *)description {
    return [JXTypeDescription
            descriptionWithHead:[self.head stringByAppendingString:description.head]
            tail:[description.tail stringByAppendingString:self.tail]];
}

- (NSString *)description {
    return [self.head stringByAppendingString:self.tail];
}

@end
