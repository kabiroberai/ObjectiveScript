//
//  JXAssociatedObjects.h
//  ObjectiveScript
//
//  Created by Kabir Oberai on 25/01/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

void JXRegisterAssociatedObjects(NSDictionary<NSString *, NSString *> *associatedObjects, NSString *clsName);
id JXGetAssociatedObject(NSString *name, id obj);
bool JXSetAssociatedObject(NSString *name, id obj, id value, objc_AssociationPolicy policy);

NS_ASSUME_NONNULL_END
