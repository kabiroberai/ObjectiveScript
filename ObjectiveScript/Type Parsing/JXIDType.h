//
//  JXIDType.h
//  ObjectiveScript
//
//  Created by Kabir Oberai on 11/03/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import "JXType.h"

NS_ASSUME_NONNULL_BEGIN

extern BOOL JXIDTypeIgnoreName;

@interface JXIDType : JXType

@property (nonatomic, readonly, nullable) NSString *name;
@property (nonatomic, readonly, nullable) NSArray<NSString *> *protocols;
@property (nonatomic, readonly) BOOL isBlock;

@end

NS_ASSUME_NONNULL_END
