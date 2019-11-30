//
//  JXContextManager.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 30/11/19.
//  Copyright © 2019 Kabir Oberai. All rights reserved.
//

#import "JXContextManager.h"

@implementation JXContextManager {
    NSMutableDictionary<NSValue *, JXContext *> *_contexts;
}

+ (JXContextManager *)sharedManager {
    static JXContextManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _contexts = [NSMutableDictionary new];

    return self;
}

- (NSValue *)keyForJSContext:(JSContext *)jsCtx {
    return [NSValue valueWithPointer:(__bridge const void *)jsCtx];
}

- (void)registerJXContext:(JXContext *)jxCtx forJSContext:(JSContext *)jsCtx {
    _contexts[[self keyForJSContext:jsCtx]] = jxCtx;
}

- (JXContext *)JXContextForJSContext:(JSContext *)jsCtx {
    return _contexts[[self keyForJSContext:jsCtx]];
}

@end
