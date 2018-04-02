//
//  JXTypePointer.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 10/03/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import "JXTypePointer.h"
#import <objc/runtime.h>

@implementation JXTypePointer

+ (BOOL)supportsEncoding:(char)encoding {
    return encoding == _C_PTR;
}

- (instancetype)initWithEncoding:(const char **)enc qualifiers:(JXTypeQualifiers)qualifiers {
    self = [super initWithEncoding:enc qualifiers:qualifiers];
    if (self) {
        const char *encStart = *enc;

        *enc += 1; // eat '^'

        // ^? represents a function
        if (**enc == '?') _isFunction = YES;

        _type = JXTypeWithEncoding(enc);

        _encoding = [self stringBetweenStart:encStart end:*enc];
    }
    return self;
}

- (JXTypeDescription *)_descriptionWithPadding:(BOOL)padding {
    if (self.isFunction) {
        return [JXTypeDescription descriptionWithHead:@"void (*" tail:@")(void)"];
    }
    // we want padding before the pointer if possible
    JXTypeDescription *subDescription = [self.type descriptionWithPadding:YES];
    return [JXTypeDescription
            descriptionWithHead:[subDescription.head stringByAppendingString:@"*"]
            tail:subDescription.tail];
}

@end

#if JX_USE_FFI
@implementation JXTypePointer (FFI)

- (ffi_type *)ffiType {
    return &ffi_type_pointer;
}

@end

#endif
