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

/// Runs the provided ObjectiveScript code
/// @param script The transpiled (pure JavaScript) code to execute
/// @param configuration The configuration used when creating the environment
void JXRunScript(NSString *script, JXConfiguration *configuration);

NS_ASSUME_NONNULL_END
