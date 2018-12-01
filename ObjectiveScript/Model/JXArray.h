//
//  JXArray.h
//  ObjectiveScript
//
//  Created by Kabir Oberai on 25/03/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import "JXPointer.h"

NS_ASSUME_NONNULL_BEGIN

@interface JXArray : JXPointer

@property (nonatomic, readonly) NSUInteger count;

- (instancetype)initWithVal:(void *)val type:(NSString *)type count:(NSUInteger)count;
+ (instancetype)arrayWithVal:(void *)val type:(NSString *)type count:(NSUInteger)count;

@end

NS_ASSUME_NONNULL_END
