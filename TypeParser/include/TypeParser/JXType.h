//
//  JXType.h
//  ObjectiveScript
//
//  Created by Kabir Oberai on 10/03/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JXTypeQualifiers.h"
#import "JXTypeDescription.h"

NS_ASSUME_NONNULL_BEGIN

@interface JXType : NSObject {
    NSString *_encoding;
}

// not necessarily the entire enc passed to init
// because that may have more types after this one
// (eg if this type is inside a struct)
@property (nonatomic, readonly) NSString *encoding;
@property (nonatomic, readonly) JXTypeQualifiers qualifiers;

// This isn't `descriptionWithName:` because we may want padding without the
// name, such as in `JXTypePointer`.
- (JXTypeDescription *)descriptionWithPadding:(BOOL)padding;

// If the receiver is the JXType base class, this will try to return a suitable subclass.
// If the receiver is a subclass, this will try to construct the receiver with encoding,
// or else return nil.
+ (nullable instancetype)typeForEncoding:(NSString *)encoding NS_SWIFT_NAME(init(encoding:));

+ (nullable instancetype)typeForEncodingC:(const char *)encoding NS_SWIFT_NAME(init(encodingC:));

@end

NS_ASSUME_NONNULL_END
