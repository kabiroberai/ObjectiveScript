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
    // declare this explicitly so that subclasses can access it
    NSString *_encoding;
}

// not necessarily the entire enc passed to init
// because that may have more types after this one
// (eg if this type is inside a struct)
@property (nonatomic, readonly) NSString *encoding;
@property (nonatomic, readonly) JXTypeQualifiers qualifiers;

// `enc` is moved forward to the start of the next type.
- (instancetype)initWithEncoding:(const char * _Nonnull * _Nonnull)enc qualifiers:(JXTypeQualifiers)qualifiers;

// returns whether the encoding is supported based on its first char
+ (BOOL)supportsEncoding:(char)encoding;

// without qualifiers (overriden by subclasses)
- (JXTypeDescription *)_descriptionWithPadding:(BOOL)padding;
// with qualifiers
- (JXTypeDescription *)descriptionWithPadding:(BOOL)padding;

// helper methods
- (NSString *)stringBetweenStart:(const char *)start end:(const char *)end;
- (NSUInteger)numberFromEncoding:(const char * _Nonnull * _Nonnull)enc;

@end

// returns a parsed JXType given an encoding. Use this as an entry point for parsing encodings.
JXType * _Nullable JXTypeForEncoding(const char *enc);
// same as above but moves enc forward by the length of the encoding
JXType * _Nullable JXTypeWithEncoding(const char * _Nonnull * _Nonnull enc);

NS_ASSUME_NONNULL_END
