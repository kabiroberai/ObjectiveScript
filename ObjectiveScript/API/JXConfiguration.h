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

/// Creates a new configuration object.
/// @param externalVariables A list of variables to include in the global environment
/// @param exceptionHandler A block that is called when an uncaught exception occurs. This block should be used to perform cleanup, save the exception log, or the like. It does @b not enable recovery from the exception.
- (instancetype)initWithExternalVariables:(NSDictionary<NSString *, id> *)externalVariables
                         exceptionHandler:(nullable void (^)(NSString *log))exceptionHandler;

@property (nonatomic, readonly) NSDictionary<NSString *, id> *externalVariables;
@property (nonatomic, copy, readonly, nullable) void (^exceptionHandler)(NSString *log);

@end

NS_ASSUME_NONNULL_END
