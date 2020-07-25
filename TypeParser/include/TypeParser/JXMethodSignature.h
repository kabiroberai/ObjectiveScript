//
//  JXMethodSignature.h
//  TypeParser
//
//  Created by Kabir Oberai on 20/07/20.
//  Copyright © 2020 Kabir Oberai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JXType.h"

NS_ASSUME_NONNULL_BEGIN

@interface JXMethodSignature : NSObject

- (nullable instancetype)initWithObjCTypes:(NSString *)types;
- (nullable instancetype)initWithNSMethodSignature:(NSMethodSignature *)signature;
- (instancetype)initWithReturnType:(JXType *)returnType argumentTypes:(NSArray<JXType *> *)argumentTypes;

+ (nullable JXMethodSignature *)signatureWithObjCTypes:(NSString *)types;
+ (nullable JXMethodSignature *)signatureWithNSMethodSignature:(NSMethodSignature *)signature;
+ (JXMethodSignature *)signatureWithReturnType:(JXType *)returnType argumentTypes:(NSArray<JXType *> *)argumentTypes;

@property (nonatomic, readonly) NSString *types;
@property (nonatomic, readonly) JXType *returnType;
@property (nonatomic, readonly) NSArray<JXType *> *argumentTypes;
@property (nonatomic, readonly) NSMethodSignature *NSMethodSignature;

@end

NS_ASSUME_NONNULL_END
