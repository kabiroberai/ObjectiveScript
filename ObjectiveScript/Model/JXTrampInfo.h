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

NS_ASSUME_NONNULL_BEGIN

/// Stores the data associated with a JS trampoline.
///
/// Automatically frees its associated closure when deallocated.
@interface JXTrampInfo : NSObject

@property (nonatomic, readonly) JSValue *func;
@property (nonatomic, readonly) char *types;
@property (nonatomic, retain) Class cls;

@property (nonatomic, assign) ffi_closure *closure;
@property (nonatomic, assign) IMP tramp;
@property (nonatomic, assign, nullable) IMP orig; // only for hooks

@property (nonatomic, readonly) NSMethodSignature *sig; // computed

- (instancetype)initWithFunc:(JSValue *)func types:(const char *)types cls:(Class)cls;
- (void)retainForever;

@end

NS_ASSUME_NONNULL_END
