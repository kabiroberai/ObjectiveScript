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

NS_ASSUME_NONNULL_BEGIN

@interface JXType (Private)

- (instancetype)initWithQualifiers:(JXTypeQualifiers)qualifiers;

// `scanner` is moved forward to the start of the next type.
- (instancetype)initWithScanner:(NSScanner *)scanner qualifiers:(JXTypeQualifiers)qualifiers;

// returns whether the encoding is supported based on its first char
+ (BOOL)supportsEncoding:(char)encoding;

// without qualifiers (overriden by subclasses)
- (JXTypeDescription *)_descriptionWithPadding:(BOOL)padding;

@end

// scans encoding from `scanner`, moving `scanner` forward if the scan succeeded
JXType * _Nullable JXTypeWithScanner(NSScanner *scanner);

NS_ASSUME_NONNULL_END
