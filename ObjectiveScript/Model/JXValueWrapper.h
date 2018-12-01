//
//  JXValueWrapper.h
//  ObjectiveScript
//
//  Created by Kabir Oberai on 01/12/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

NS_ASSUME_NONNULL_BEGIN

// adds a type hint to a JSValue
@interface JXValueWrapper : NSObject

@property (nonatomic, readonly) NSString *types;
@property (nonatomic, readonly) JSValue *value;

- (instancetype)initWithTypes:(NSString *)types value:(JSValue *)value;

@end

NS_ASSUME_NONNULL_END
