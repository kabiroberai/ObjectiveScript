//
//  JXTypeBasic.h
//  ObjectiveScript
//
//  Created by Kabir Oberai on 10/03/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JXType.h"

typedef NS_ENUM(NSUInteger, JXPrimitiveType) {
    JXPrimitiveTypeClass,
    JXPrimitiveTypeSelector,
    JXPrimitiveTypeChar,
    JXPrimitiveTypeUnsignedChar,
    JXPrimitiveTypeShort,
    JXPrimitiveTypeUnsignedShort,
    JXPrimitiveTypeInt,
    JXPrimitiveTypeUnsignedInt,
    JXPrimitiveTypeLong,
    JXPrimitiveTypeUnsignedLong,
    JXPrimitiveTypeLongLong,
    JXPrimitiveTypeUnsignedLongLong,
    JXPrimitiveTypeFloat,
    JXPrimitiveTypeDouble,
    JXPrimitiveTypeBOOL,
    JXPrimitiveTypeVoid
};

@interface JXTypeBasic : JXType

@property (nonatomic, readonly) JXPrimitiveType primitiveType;

- (instancetype)initWithPrimitiveType:(JXPrimitiveType)primitiveType;

@end
