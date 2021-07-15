//
//  JXType+FFI.h
//  ObjectiveScript
//
//  Created by Kabir Oberai on 29/07/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import "JXType.h"
#import <ffi/ffi.h>

NS_ASSUME_NONNULL_BEGIN

// since category inheritance is UB, we use a different method on subclasses for the concrete implementation
// of ffiType
@protocol JXFFIType <NSObject>
- (nullable ffi_type *)_ffiType;
@end

@interface JXType (FFI)
- (nullable ffi_type *)ffiType;
@end

size_t JXSizeForEncoding(const char *enc);
ffi_type *JXAllocateCompoundFFIType(size_t len);
void JXFreeFFIType(ffi_type *type);

NS_ASSUME_NONNULL_END
