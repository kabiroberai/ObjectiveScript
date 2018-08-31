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
@property (nonatomic, readonly) void *val;

// when copy is NO, saves a reference to the passed in `val` rather than copying it
// this is useful when the struct is part of an L-value
// eg. in ptr.pointee.width = 5 we would not want `pointee` to be copied
- (instancetype)initWithVal:(void *)val type:(const char *)type copy:(BOOL)copy;
+ (instancetype)structWithVal:(void *)val type:(const char *)type copy:(BOOL)copy;
// also copies the type of the value at `index` into `type`
- (nullable void *)getValueWithName:(NSString *)name type:(const char * _Nonnull * _Nonnull)type NS_RETURNS_INNER_POINTER;
- (NSString *)descriptionWithContext:(JSContext *)ctx;

@end

NS_ASSUME_NONNULL_END
