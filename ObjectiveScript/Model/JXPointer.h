//
//  JXPointer.h
//  ObjectiveScript
//
//  Created by Kabir Oberai on 06/03/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "JXKVC.h"

NS_ASSUME_NONNULL_BEGIN

@interface JXPointer : NSObject <JXKVC>

@property (nonatomic, readonly) void *val;
@property (nonatomic, readonly) NSString *type;
@property (nonatomic, readonly) size_t size;

- (instancetype)initWithVal:(void *)val type:(NSString *)type;
+ (instancetype)pointerWithVal:(void *)val type:(NSString *)type;

- (JXPointer *)withType:(NSString *)type;

@end

NS_ASSUME_NONNULL_END
