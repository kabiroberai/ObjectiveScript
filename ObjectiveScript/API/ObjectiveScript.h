//
//  ObjectiveScript.h
//  ObjectiveScript
//
//  Created by Kabir Oberai on 15/12/17.
//  Copyright © 2017 Kabir Oberai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "JXConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

void JXRunScript(NSString *script, JXConfiguration *configuration);

NS_ASSUME_NONNULL_END
