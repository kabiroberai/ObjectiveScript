//
//  JXTypeStruct.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 10/03/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import <objc/runtime.h>
#import "JXTypeStruct.h"

@implementation JXTypeStruct

+ (char)startDelim { return _C_STRUCT_B; }
+ (char)endDelim { return _C_STRUCT_E; }
+ (NSString *)typeName { return @"struct"; }

@end
