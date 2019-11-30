//
//  JXAssociatedObjects.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 25/01/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <objc/runtime.h>
#import "JXContextManager.h"
#import "JXAssociatedObjects.h"

static JXAssociatedObjectsDict *allAssociatedObjects(JSContext *ctx) {
    return [JXContextManager.sharedManager JXContextForJSContext:ctx].associatedObjects;
}

void JXRegisterAssociatedObjects(JSContext *ctx, NSDictionary<NSString *, NSString *> *associatedObjects, NSString *clsName) {
    JXAssociatedObjectsDict *all = allAssociatedObjects(ctx);
	// Add associated object keys
	// Get the existing keys for this class
	NSMutableDictionary *dict = all[clsName];
	if (!dict) {
		dict = [NSMutableDictionary new];
		all[clsName] = dict;
	}
	[dict addEntriesFromDictionary:associatedObjects];
}

static const void *keyForAssociatedObject(JSContext *ctx, NSString *name, id obj) {
	NSString *key = allAssociatedObjects(ctx)[NSStringFromClass([obj class])][name];
	return (__bridge const void *)key;
}

id JXGetAssociatedObject(JSContext *ctx, NSString *name, id obj) {
	const void *key = keyForAssociatedObject(ctx, name, obj);
	if (!key) return nil;
	return objc_getAssociatedObject(obj, key);
}

bool JXSetAssociatedObject(JSContext *ctx, NSString *name, id obj, id value, objc_AssociationPolicy policy) {
	if (!value) return false;
	const void *key = keyForAssociatedObject(ctx, name, obj);
	if (!key) return false;
	objc_setAssociatedObject(obj, key, value, policy);
	return true;
}
