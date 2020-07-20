//
//  JXBlockInterop.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 25/01/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "JXBlockInterop.h"
#import "JXTrampInfo.h"
#import "JXRuntimeInterface.h"
#import "JXJSInterop.h"
#import "JXType.h"
#import "JXTypeStruct.h"

// Called when a custom block is copied
static void copyHelper(struct JXBlockLiteral *dst, const struct JXBlockLiteral *src) {
	_Block_object_assign(&dst->info, src->info, BLOCK_FIELD_IS_OBJECT);
}

// Called when a custom block is disposed
static void disposeHelper(const struct JXBlockLiteral *src) {
	free(src->descriptor);
	_Block_object_dispose(src->info, BLOCK_FIELD_IS_OBJECT);
}

JSValue *JXCreateBlock(NSString *sig, JSValue *func) {
	JXTrampInfo *info = JXCreateTramp(func, sig.UTF8String, nil);
	
	int flags = BLOCK_HAS_SIGNATURE | BLOCK_HAS_COPY_DISPOSE;

    JXType *type = [JXType typeForEncodingC:info.types];
	BOOL hasStret = [type isKindOfClass:JXTypeStruct.class];
	if (hasStret) {
		flags |= BLOCK_HAS_STRET;
	}
	
	struct JXHelpersBlockDescriptor *descriptor = malloc(sizeof(struct JXHelpersBlockDescriptor));
	*descriptor = (struct JXHelpersBlockDescriptor) {
		.size = sizeof(struct JXBlockLiteral),
		.copyHelper = copyHelper,
		.disposeHelper = disposeHelper,
		.signature = info.types
	};
	
	struct JXBlockLiteral block = {
		.isa = &_NSConcreteStackBlock,
		.flags = flags,
		.invoke = info.tramp,
		.descriptor = descriptor,
		.info = (__bridge CFTypeRef)info,
	};
	
	return JXObjectToJSValue((__bridge Block)&block, [JSContext currentContext]);
}

IMP JXGetBlockIMP(id block, const char **signature, BOOL *hasStret) {
    struct JXBlockLiteral *blockLiteral = (__bridge struct JXBlockLiteral *)block;
    if (![NSStringFromClass([block class]) containsString:@"Block"]) {
        return NULL;
    }
    if (hasStret) {
        *hasStret = (blockLiteral->flags & BLOCK_HAS_STRET) == BLOCK_HAS_STRET;
    }
    if (signature) {
        if ((blockLiteral->flags & BLOCK_HAS_SIGNATURE) == BLOCK_HAS_SIGNATURE) {
            if ((blockLiteral->flags & BLOCK_HAS_COPY_DISPOSE) == BLOCK_HAS_COPY_DISPOSE) {
                *signature = ((struct JXHelpersBlockDescriptor *)blockLiteral->descriptor)->signature;
            } else {
                *signature = ((struct JXNoHelpersBlockDescriptor *)blockLiteral->descriptor)->signature;
            }
        } else {
            *signature = NULL;
        }
    }
    return blockLiteral->invoke;
}
