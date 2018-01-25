//
//  JXAssociatedObjects.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 25/01/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "JXAssociatedObjects.h"

// [class : [ivar : key]]
static NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, NSString *> *> *allAssociatedObjects;

void JXRegisterAssociatedObjects(NSDictionary<NSString *, NSString *> *associatedObjects, NSString *clsName) {
	if (!allAssociatedObjects) allAssociatedObjects = [NSMutableDictionary new];
	// Add associated object keys
	// Get the existing keys for this class
	NSMutableDictionary *dict = allAssociatedObjects[clsName];
	if (!dict) {
		dict = [NSMutableDictionary new];
		allAssociatedObjects[clsName] = dict;
	}
	[dict addEntriesFromDictionary:associatedObjects];
}

static const void *keyForAssociatedObject(NSString *name, id obj) {
	NSString *key = allAssociatedObjects[NSStringFromClass([obj class])][name];
	return (__bridge const void *)key;
}

id JXGetAssociatedObject(NSString *name, id obj) {
	const void *key = keyForAssociatedObject(name, obj);
	if (!key) return nil;
	return objc_getAssociatedObject(obj, key);
}

bool JXSetAssociatedObject(NSString *name, id obj, id value, objc_AssociationPolicy policy) {
	if (!value) return false;
	const void *key = keyForAssociatedObject(name, obj);
	if (!key) return false;
	objc_setAssociatedObject(obj, key, value, policy);
	return true;
}
