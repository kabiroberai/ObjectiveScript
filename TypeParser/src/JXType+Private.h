//
//  JXType+Private.h
//  ObjectiveScript
//
//  Created by Kabir Oberai on 20/07/20.
//  Copyright © 2020 Kabir Oberai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JXType.h"
#import "NSScanner+Utils.h"
#import "JXConcreteType.h"

NS_ASSUME_NONNULL_BEGIN

extern BOOL JXTypeIDIgnoreName;
extern NSString *JXTypeIDIgnoreNameLock;

@interface JXType (Private)

- (instancetype)initWithQualifiers:(JXTypeQualifiers)qualifiers;

// scans encoding from `scanner`, moving `scanner` forward if the scan succeeded
+ (nullable instancetype)typeWithScanner:(NSScanner *)scanner;

// defaults to YES
- (BOOL)orderQualifiersBeforeDescription;

@end

NS_ASSUME_NONNULL_END
