//
//  JXStruct.h
//  ObjectiveScript
//
//  Created by Kabir Oberai on 18/01/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ffi.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "JXKVC.h"

NS_ASSUME_NONNULL_BEGIN

/// A box for C structs.
@interface JXStruct : NSObject <JXKVC>

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *rawType;
@property (nonatomic, readonly) void *val;

// when copy is NO, saves a reference to the passed in `val` rather than copying it
// this is useful when the struct is part of an L-value
// eg. in ptr.pointee.width = 5 we would not want `pointee` to be copied
- (instancetype)initWithVal:(void *)val type:(const char *)type copy:(BOOL)copy;
+ (instancetype)structWithVal:(void *)val type:(const char *)type copy:(BOOL)copy;
- (NSString *)descriptionWithContext:(JSContext *)ctx;

- (nullable NSString *)extendedTypeInContext:(JSContext *)ctx;

@end

NS_ASSUME_NONNULL_END
