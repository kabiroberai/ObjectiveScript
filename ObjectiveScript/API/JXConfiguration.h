//
//  JXConfiguration.h
//  ObjectiveScript
//
//  Created by Kabir Oberai on 30/11/19.
//  Copyright © 2019 Kabir Oberai. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JXConfiguration : NSObject

- (instancetype)initWithExternalVariables:(NSDictionary<NSString *, id> *)externalVariables
                         exceptionHandler:(nullable void (^)(NSString *log))exceptionHandler;

@property (nonatomic, readonly) NSDictionary<NSString *, id> *externalVariables;
@property (nonatomic, copy, readonly, nullable) void (^exceptionHandler)(NSString *log);

@end

NS_ASSUME_NONNULL_END
