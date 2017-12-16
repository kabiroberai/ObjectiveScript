//
//  JXFFIInterface.h
//  ObjectiveScript
//
//  Created by Kabir Oberai on 19/11/17.
//  Copyright © 2017 Kabir Oberai. All rights reserved.
//

#import "JXHookInfo.h"

void JXSwizzle(Class cls, BOOL isClassMethod, SEL sel, SwizzleBlock block);
IMP JXCreateImpFromJS(JSValue *func, const char *enc);
