//
//  JXMethodSignature+Private.h
//  ObjectiveScript
//
//  Created by Kabir Oberai on 20/07/20.
//  Copyright © 2020 Kabir Oberai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JXMethodSignature.h"

NS_ASSUME_NONNULL_BEGIN

@interface JXMethodSignature (Private)

- (nullable instancetype)initWithScanner:(NSScanner *)scanner;
+ (nullable JXMethodSignature *)signatureWithScanner:(NSScanner *)scanner;

@end

NS_ASSUME_NONNULL_END
