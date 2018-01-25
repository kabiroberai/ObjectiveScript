//
//  JXStruct.h
//  ObjectiveScript
//
//  Created by Kabir Oberai on 18/01/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ffi.h>

NS_ASSUME_NONNULL_BEGIN

/// A box for C structs.
@interface JXStruct : NSObject

@property (nonatomic, assign, readonly) void *val;

- (instancetype)initWithVal:(void *)val type:(const char *)type;
+ (instancetype)structWithVal:(void *)val type:(const char *)type;
// also copies the type of the value at `index` into `type`
- (void *)getValueAtIndex:(size_t)index type:(const char * _Nonnull * _Nonnull)type NS_RETURNS_INNER_POINTER;

@end

NS_ASSUME_NONNULL_END
