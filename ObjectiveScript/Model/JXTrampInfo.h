//
//  JXTrampInfo.h
//  ObjectiveScript
//
//  Created by Kabir Oberai on 16/11/17.
//  Copyright © 2017 Kabir Oberai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <ffi.h>
#import "JXMethodSignature.h"

NS_ASSUME_NONNULL_BEGIN

/// Stores the data associated with a JS trampoline.
///
/// Automatically frees its associated closure when deallocated.
@interface JXTrampInfo : NSObject

@property (nonatomic, readonly) JSValue *func;
@property (nonatomic, readonly) Class cls;
@property (nonatomic, readonly) JXMethodSignature *sig;

@property (nonatomic) ffi_closure *closure NS_RETURNS_INNER_POINTER;
@property (nonatomic) IMP tramp NS_RETURNS_INNER_POINTER;
@property (nonatomic, nullable) IMP orig NS_RETURNS_INNER_POINTER; // only for hooks

- (instancetype)initWithFunc:(JSValue *)func types:(NSString *)types cls:(Class)cls;

/// Intentionally sets up a strong reference cycle. Returns `self` as a convenience.
- (instancetype)retainForever;

@end

NS_ASSUME_NONNULL_END
