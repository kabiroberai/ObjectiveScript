//
//  JXTypeArray.h
//  ObjectiveScript
//
//  Created by Kabir Oberai on 10/03/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import "JXType.h"

NS_ASSUME_NONNULL_BEGIN

@interface JXTypeArray : JXType

@property (nonatomic, readonly) NSUInteger count;
@property (nonatomic, readonly) JXType *type;

@end

NS_ASSUME_NONNULL_END
