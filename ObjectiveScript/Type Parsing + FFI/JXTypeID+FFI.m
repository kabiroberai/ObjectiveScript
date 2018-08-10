//
//  JXTypeID+FFI.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 29/07/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import "JXTypeID+FFI.h"

@implementation JXTypeID (FFI)

- (ffi_type *)_ffiType {
    return &ffi_type_pointer;
}

@end
