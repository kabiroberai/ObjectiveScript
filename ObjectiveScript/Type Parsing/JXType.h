//
//  JXType.h
//  ObjectiveScript
//
//  Created by Kabir Oberai on 10/03/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#define JX_USE_FFI 1

#import <Foundation/Foundation.h>
#import "JXTypeQualifiers.h"
#import "JXTypeDescription.h"

NS_ASSUME_NONNULL_BEGIN

@interface JXType : NSObject {
    // declare this explicitly so that subclasses can access it
    NSString *_encoding;
}

// not necessarily the same as the enc passed to init
// because that may have more types after this one
@property (nonatomic, readonly) NSString *encoding;

@property (nonatomic, readonly) JXTypeQualifiers qualifiers;

// `enc` is moved forward to the start of the next type.
- (instancetype)initWithEncoding:(const char * _Nonnull * _Nonnull)enc qualifiers:(JXTypeQualifiers)qualifiers;

// returns whether the encoding is supported based on its first char
+ (BOOL)supportsEncoding:(char)encoding;

- (NSString *)stringBetweenStart:(const char *)start end:(const char *)end;
- (NSUInteger)numberFromEncoding:(const char * _Nonnull * _Nonnull)enc;

- (JXTypeDescription *)_descriptionWithPadding:(BOOL)padding;
- (JXTypeDescription *)descriptionWithPadding:(BOOL)padding;

@end

#if JX_USE_FFI
NS_ASSUME_NONNULL_END
#import <ffi.h>
NS_ASSUME_NONNULL_BEGIN

@interface JXType (FFI)
- (nullable ffi_type *)ffiType;
@end
#endif

// returns a parsed JXType given an encoding. Use this as an entry point for parsing encodings.
JXType * _Nullable JXTypeForEncoding(const char *enc);
// same as above but moves enc forward by the length of the encoding
JXType * _Nullable JXTypeWithEncoding(const char * _Nonnull * _Nonnull enc);

#if JX_USE_FFI
size_t JXSizeForEncoding(const char *enc);
ffi_type *JXAllocateCompoundFFIType(size_t len);
void JXFreeFFIType(ffi_type *type);
#endif

NS_ASSUME_NONNULL_END
