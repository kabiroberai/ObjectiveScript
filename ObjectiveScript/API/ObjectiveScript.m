//
//  ObjectiveScript.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 13/12/17.
//  Copyright © 2017 Kabir Oberai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "JXJSInterop.h"
#import "JXJSInterface.h"
#import "JXConfiguration.h"
#import "ObjectiveScript.h"

void JXRunScript(NSString *script, JXConfiguration *configuration) {
	JSContext *ctx = JXCreateContext(configuration);
    for (NSString *key in configuration.externalVariables) {
        ctx[key] = JXObjectToJSValue(configuration.externalVariables[key], ctx);
    }
	[ctx evaluateScript:script];
}
