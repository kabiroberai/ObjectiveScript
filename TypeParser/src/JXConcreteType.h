//
//  JXConcreteType.h
//  ObjectiveScript
//
//  Created by Kabir Oberai on 20/07/20.
//  Copyright © 2020 Kabir Oberai. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol JXConcreteType <NSObject>

// returns whether the encoding is supported based on its first char
+ (BOOL)supportsEncoding:(char)encoding;

// `scanner` is moved forward to the start of the next type.
- (instancetype)initWithScanner:(NSScanner *)scanner qualifiers:(JXTypeQualifiers)qualifiers;

// without qualifiers (overriden by subclasses)
- (JXTypeDescription *)baseDescriptionWithOptions:(JXTypeDescriptionOptions *)options;

@end

NS_ASSUME_NONNULL_END
