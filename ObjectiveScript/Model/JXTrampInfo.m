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

- (instancetype)initWithFunc:(JSValue *)func types:(const char *)types cls:(Class)cls {
	self = [super init];
	if (self) {
		_func = func;
		_types = malloc(sizeof(char) * strlen(types));
		strcpy(_types, types);
        _sig = [NSMethodSignature signatureWithObjCTypes:_types];
		_cls = cls;
	}
	return self;
}

- (void)retainForever {
	// sets up a strong reference cycle on purpose
	_retained = self;
}

- (void)dealloc {
	free(_types);

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
