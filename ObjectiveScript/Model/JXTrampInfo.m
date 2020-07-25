//
//  JXTrampInfo.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 16/11/17.
//  Copyright © 2017 Kabir Oberai. All rights reserved.
//

#import "JXTrampInfo.h"
#import "Block.h"
#import "JXType+FFI.h"

@implementation JXTrampInfo {
	JXTrampInfo *_retained;
}

- (instancetype)initWithFunc:(JSValue *)func types:(NSString *)types cls:(Class)cls {
	self = [super init];
	if (self) {
		_func = func;
        _sig = [JXMethodSignature signatureWithObjCTypes:types];
		_cls = cls;
	}
	return self;
}

- (instancetype)retainForever {
	_retained = self;
    return self;
}

- (void)dealloc {
    // free _closure
    ffi_cif *cif = _closure->cif;
    for (size_t i = 0; i < cif->nargs; i++) {
        // free all struct args of cif
        JXFreeFFIType(cif->arg_types[i]);
    }
    free(cif->arg_types);
    JXFreeFFIType(cif->rtype);
    free(cif);
    ffi_closure_free(_closure);
}

@end
