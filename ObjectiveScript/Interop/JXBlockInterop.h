//
//  Block.h
//  ObjectiveScript
//
//  Created by Kabir Oberai on 27/12/17.
//  Copyright © 2017 Kabir Oberai. All rights reserved.
//

// https://clang.llvm.org/docs/Block-ABI-Apple.html

typedef void (^Block)(void);

struct JXBlockLiteral {
	void *isa;
	int flags;
	int reserved;
	IMP invoke; // void (*)(struct JXBlockLiteral *, ...);
	struct JXBlockDescriptor {
		unsigned long int reserved;
		unsigned long int size;
		void (*copyHelper)(struct JXBlockLiteral *dst, const struct JXBlockLiteral *src);
		void (*disposeHelper)(const struct JXBlockLiteral *src);
		const char *signature;
	} *descriptor;
	CFTypeRef info;
};

enum {
	BLOCK_HAS_COPY_DISPOSE =  (1 << 25),
	BLOCK_HAS_CTOR =          (1 << 26), // helpers have C++ code
	BLOCK_IS_GLOBAL =         (1 << 28),
	BLOCK_HAS_STRET =         (1 << 29), // IFF BLOCK_HAS_SIGNATURE
	BLOCK_HAS_SIGNATURE =     (1 << 30),
};

// Values for _Block_object_assign() and _Block_object_dispose() parameters
enum {
	// see function implementation for a more complete description of these fields and combinations
	BLOCK_FIELD_IS_OBJECT   =  3,  // id, NSObject, __attribute__((NSObject)), block, ...
	BLOCK_FIELD_IS_BLOCK    =  7,  // a block variable
	BLOCK_FIELD_IS_BYREF    =  8,  // the on stack structure holding the __block variable
	BLOCK_FIELD_IS_WEAK     = 16,  // declared __weak, only used in byref copy helpers
	BLOCK_BYREF_CALLER      = 128, // called from __block (byref) copy/dispose support routines.
};

JSValue *JXCreateBlock(NSString *sig, JSValue *func);
