//
//  JXContextManager.h
//  ObjectiveScript
//
//  Created by Kabir Oberai on 30/11/19.
//  Copyright © 2019 Kabir Oberai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JXContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface JXContextManager : NSObject

@property (nonatomic, class, readonly) JXContextManager *sharedManager;

- (void)registerJXContext:(JXContext *)jxCtx forJSContext:(JSContext *)jsCtx;
- (JXContext *)JXContextForJSContext:(JSContext *)jsCtx;

@end

NS_ASSUME_NONNULL_END
