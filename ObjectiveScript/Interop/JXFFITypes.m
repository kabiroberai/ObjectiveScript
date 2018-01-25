//
//  JXFFITypes.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 15/12/17.
//  Copyright © 2017 Kabir Oberai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "JXFFITypes.h"

// Strip any qualifiers from `type` (const, inout, etc)
void JXRemoveQualifiers(const char **type) {
	switch (**type) {
		case 'j':
		case 'r':
		case 'n':
		case 'N':
		case 'o':
		case 'O':
		case 'R':
		case 'V':
			// Advance the type str by 1
			*type += 1;
			// Remove any more qualifiers
			JXRemoveQualifiers(type);
	}
}

static ffi_type *ffiTypeForArrayEncoding(const char **strippedEnc);
static ffi_type *ffiTypeForStructEncoding(const char **strippedEnc);

// the internal function that does the actual parsing work
// takes a pointer to a string so that it can advance the string forwards
// because when ffiTypeFor[Struct|Array]Encoding recursively calls this with strippedEnc,
// it'll move it forward by the correct length, to the next value in the list
static ffi_type *ffiTypeForEncoding(const char **enc) {
	JXRemoveQualifiers(enc);
	
	// get the first (non-qualifier) char of enc
	char first = **enc;
	
	*enc += 1; // enc will always move forward by at least 1
	// so now if it's a simple (one char) type no additional action is required to move enc
	// but if it's an array/struct, this just skips the '[' or '{' so that isn't a problem either
	
	// Credits to https://github.com/parmanoir/jscocoa/blob/master/JSCocoa/JSCocoaFFIArgument.m
	switch (first) {
		case _C_ID:
		case _C_CLASS:
		case _C_SEL:
		case _C_PTR:
		case _C_CHARPTR:  return &ffi_type_pointer;
			
		case _C_CHR:      return &ffi_type_sint8;
		case _C_UCHR:     return &ffi_type_uint8;
		case _C_SHT:      return &ffi_type_sint16;
		case _C_USHT:     return &ffi_type_uint16;
		case _C_INT:
		case _C_LNG:      return &ffi_type_sint32;
		case _C_UINT:
		case _C_ULNG:     return &ffi_type_uint32;
		case _C_LNG_LNG:  return &ffi_type_sint64;
		case _C_ULNG_LNG: return &ffi_type_uint64;
		case _C_FLT:      return &ffi_type_float;
		case _C_DBL:      return &ffi_type_double;
		case _C_BOOL:     return &ffi_type_sint8;
		case _C_VOID:     return &ffi_type_void;
			
		// The type is a struct or an array, so make a custom ffi_type to represent it
		case _C_ARY_B:    return ffiTypeForArrayEncoding(enc);
		case _C_STRUCT_B: return ffiTypeForStructEncoding(enc);
	}
	return NULL;
}

// Create a blank ffi_type representing a struct with `len` elements
static ffi_type *initializeStructType(size_t len) {
	ffi_type *compoundType = malloc(sizeof(ffi_type));
	// alignment and size are automatically set by libffi during ffi_prep_cif
	compoundType->type = FFI_TYPE_STRUCT;
	// has to be a null-terminated list, so add one more element than required
	compoundType->elements = malloc((len + 1) * sizeof(ffi_type *));
	compoundType->elements[len] = NULL; // set the last element to NULL
	return compoundType;
}

// eg. [123Q] turns into a struct with 123 Qs
static ffi_type *ffiTypeForArrayEncoding(const char **strippedEnc) {
	*strippedEnc += 1; // to ignore the first '['
	
	// Calculate the number of elements in the array
	int len = 0;
	while (isdigit(**strippedEnc)) {
		char digit = **strippedEnc - '0';
		len = (len * 10) + digit;
		*strippedEnc += 1;
	}
	
	// Get the encoding type, advancing strippedEnc in place as well
	ffi_type *t = ffiTypeForEncoding(strippedEnc);
	// Move strippedEnc forward by one more to pass the ']'
	*strippedEnc += 1;
	
	ffi_type *compound_type = initializeStructType(len);
	// Populate compound_type with `len` elements of the same type `t`
	for (int i = 0; i < len; i++) {
		compound_type->elements[i] = t;
	}
	
	return compound_type;
}

// ptr to string, so that the string can be advanced (basically inout)
static ffi_type *ffiTypeForStructEncoding(const char **strippedEnc) {
	*strippedEnc = strchr(*strippedEnc, '=') + 1; // + 1 to skip the '=' itself
	
	size_t len = strlen(*strippedEnc) - 1; // -1 skips the '}'
	
	int nElements = 0;
	// there will be a max of `len` elements
	ffi_type *elements[len];
	
	// Keep on advancing strippedEnc until we hit a '}'
	while (**strippedEnc != '}') {
		// pass in strippedEnc directly so that it can be advanced in place
		// set the "nElements"th type to the next type, and increase nElements by 1
		elements[nElements++] = ffiTypeForEncoding(strippedEnc);
	}
	// Move strippedEnc forward by 1 again to advance past '}'
	*strippedEnc += 1;
	
	ffi_type *compoundType = initializeStructType(nElements);
	// copy the first `nElements` items of `elements` into compoundType->elements
	memcpy(compoundType->elements, &elements, nElements * sizeof(ffi_type *));
	
	return compoundType;
}

// Calls internal ffiTypeForEncoding with a pointer to enc
ffi_type *JXFFITypeForEncoding(const char *enc) {
	return ffiTypeForEncoding(&enc);
}

void JXFreeType(ffi_type *type) {
	// don't free unless it's a struct
	if (type->type != FFI_TYPE_STRUCT) return;
	// first free all nested structs
	for (ffi_type **el = type->elements; *el; el++) {
		JXFreeType(*el);
	}
	// then free the elements array
	free(type->elements);
	// then free the struct itself
	free(type);
}

void JXFreeClosure(ffi_closure *closure) {
	ffi_cif *cif = closure->cif;
	// free all struct args of cif
	for (size_t i = 0; i < cif->nargs; i++) {
		JXFreeType(cif->arg_types[i]);
	}
	// free the arg types array
	free(cif->arg_types);
	// free the rtype
	JXFreeType(cif->rtype);
	// free the cif itself
	free(cif);
	// free the closure
	ffi_closure_free(closure);
}

const char *JXEncodingForFFIType(ffi_type *type) {
#define cmpSet(t, v) else if (type == &ffi_type_##t) return @encode(v);
#define cmpSetPair(t, v) cmpSet(s##t, v) cmpSet(u##t, unsigned v)
	if (false);
	cmpSetPair(int8, char)
	cmpSetPair(int16, short)
	cmpSetPair(int32, int)
	cmpSetPair(int64, long long)
	cmpSet(pointer, void *)
	cmpSet(float, float)
	cmpSet(double, double)
	cmpSet(void, void)
	else if (type->type == FFI_TYPE_STRUCT) {
		NSMutableString *mutableStr = [@"{???=" mutableCopy];
		for (size_t i = 0; type->elements[i]; i++) {
			const char *enc = JXEncodingForFFIType(type->elements[i]);
			[mutableStr appendString:[NSString stringWithUTF8String:enc]];
		}
		[mutableStr appendString:@"}"];
		return mutableStr.UTF8String;
	}
	return NULL;
}
