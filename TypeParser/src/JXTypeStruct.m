//
//  JXTypeStruct.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 10/03/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import <objc/runtime.h>
#import "JXTypeStruct.h"

@interface JXTypeCompound () <JXConcreteType> @end

@implementation JXTypeStruct

+ (char)startDelim { return _C_STRUCT_B; }
+ (char)endDelim { return _C_STRUCT_E; }
+ (NSString *)typeName { return @"struct"; }

- (JXTypeDescription *)baseDescriptionWithOptions:(JXTypeDescriptionOptions *)options {
    NSString *commonName;
    if (self.name && (commonName = options.structTypedefs[self.name])) {
        return [JXTypeDescription descriptionWithHead:[commonName stringByAppendingString:options.padding]];
    } else {
        return [super baseDescriptionWithOptions:options];
    }
}

@end
