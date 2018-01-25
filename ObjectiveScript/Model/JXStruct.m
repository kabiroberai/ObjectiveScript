//
//  JXStruct.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 18/01/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import <ffi.h>
#import "JXStruct.h"
#import "JXFFITypes.h"

@implementation JXStruct {
	size_t *_offsets;
	ffi_type *_type;
}

- (instancetype)initWithVal:(void *)val type:(const char *)type {
	self = [super init];
	if (self) {
		// get ffi type
		_type = JXFFITypeForEncoding(type);
		// calculate number of elements
		size_t nelements = 0;
		// keep incrementing nelements till the value at that idx is NULL
		while (_type->elements[nelements]) nelements++;
		_offsets = malloc(sizeof(size_t) * nelements);
		// fully populate type and get offsets
		ffi_get_struct_offsets(FFI_DEFAULT_ABI, _type, _offsets);
		// assign _val
		_val = malloc(_type->size);
		memcpy(_val, val, _type->size);
	}
	return self;
}

+ (instancetype)structWithVal:(void *)val type:(const char *)type {
	return [[JXStruct alloc] initWithVal:val type:type];
}

- (void *)getValueAtIndex:(size_t)index type:(const char **)type {
	*type = JXEncodingForFFIType(_type->elements[index]);
	return _val + _offsets[index];
}

- (void)dealloc {
	JXFreeType(_type);
	free(_offsets);
	free(_val);
}

@end
