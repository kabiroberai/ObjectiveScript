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
@package
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

@end

JXType * _Nullable JXTypeForEncoding(NSString *encoding);
JXType * _Nullable JXTypeForEncodingC(const char *encoding);

NS_ASSUME_NONNULL_END
