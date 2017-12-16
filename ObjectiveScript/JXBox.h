//
//  JXBox.h
//  ObjectiveScript
//
//  Created by Kabir Oberai on 15/12/17.
//  Copyright © 2017 Kabir Oberai. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// inspired by https://github.com/bang590/JSPatch/wiki/How-JSPatch-works#4jpboxing
@interface JXBox : NSObject

@property (nonatomic, retain) id obj;

+ (id)unboxIfNeeded:(id)obj;
+ (id)boxIfNeeded:(id)obj;

@end

NS_ASSUME_NONNULL_END
