//
//  JXTypeID.h
//  ObjectiveScript
//
//  Created by Kabir Oberai on 11/03/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import "JXType.h"

NS_ASSUME_NONNULL_BEGIN

#if __i386__
// suppresses warning about using __thread on 32-bit simulator
#define __thread
#endif

// __thread ensures that in the middle of one JXTypeWithEncoding call where this is YES,
// if a JXTypeWithEncoding call occurs on another thread, this isn't YES on that thread
// too, which would be incorrect
extern __thread BOOL JXTypeIDIgnoreName;

@interface JXTypeID : JXType

@property (nonatomic, readonly, nullable) NSString *name;
@property (nonatomic, readonly, nullable) NSArray<NSString *> *protocols;
@property (nonatomic, readonly) BOOL isBlock;

@end

NS_ASSUME_NONNULL_END
