//
//  JXUnionType.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 11/03/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import <objc/runtime.h>
#import "JXUnionType.h"

@implementation JXUnionType

+ (char)startDelim { return _C_UNION_B; }
+ (char)endDelim { return _C_UNION_E; }
+ (NSString *)typeName { return @"union"; }

@end
