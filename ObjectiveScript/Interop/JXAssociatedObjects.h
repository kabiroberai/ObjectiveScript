//
//  JXAssociatedObjects.h
//  ObjectiveScript
//
//  Created by Kabir Oberai on 25/01/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

void JXRegisterAssociatedObjects(JSContext *ctx, NSDictionary<NSString *, NSString *> *associatedObjects, NSString *clsName);
id _Nullable JXGetAssociatedObject(JSContext *ctx, NSString *name, id obj);
bool JXSetAssociatedObject(JSContext *ctx, NSString *name, id obj, id value, objc_AssociationPolicy policy);

NS_ASSUME_NONNULL_END
