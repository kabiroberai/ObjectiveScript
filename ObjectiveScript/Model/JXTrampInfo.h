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
@property (nonatomic, readonly) Class cls;
@property (nonatomic, readonly) NSMethodSignature *sig;

@property (nonatomic) ffi_closure *closure;
@property (nonatomic) IMP tramp;
@property (nonatomic, nullable) IMP orig; // only for hooks

- (instancetype)initWithFunc:(JSValue *)func types:(const char *)types cls:(Class)cls;
- (void)retainForever;

@end

NS_ASSUME_NONNULL_END
