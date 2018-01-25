//
//  JXFFITypes.h
//  ObjectiveScript
//
//  Created by Kabir Oberai on 15/12/17.
//  Copyright © 2017 Kabir Oberai. All rights reserved.
//

#import <ffi.h>

NS_ASSUME_NONNULL_BEGIN

void JXRemoveQualifiers(const char * _Nonnull * _Nonnull type);
ffi_type *JXFFITypeForEncoding(const char *enc);
void JXFreeType(ffi_type *type);
void JXFreeClosure(ffi_closure *closure);
const char * _Nullable JXEncodingForFFIType(ffi_type *type);

NS_ASSUME_NONNULL_END
