//
//  JXTypePointer.h
//  ObjectiveScript
//
//  Created by Kabir Oberai on 10/03/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import "JXType.h"

@interface JXTypePointer : JXType

@property (nonatomic, readonly) JXType *type;
@property (nonatomic, readonly) BOOL isFunction;

@end
