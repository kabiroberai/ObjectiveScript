//
//  JXTypeID.h
//  ObjectiveScript
//
//  Created by Kabir Oberai on 11/03/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import "JXType.h"
#import "JXMethodSignature.h"

NS_ASSUME_NONNULL_BEGIN

@interface JXTypeID : JXType

@property (nonatomic, readonly, nullable) NSString *name;
@property (nonatomic, readonly, nullable) NSArray<NSString *> *protocols;

@property (nonatomic, readonly) BOOL isBlock;
// may be present if isBlock is YES
@property (nonatomic, readonly, nullable) JXMethodSignature *blockSignature;

- (instancetype)initWithClassName:(nullable NSString *)name protocols:(nullable NSArray<NSString *> *)protocols;
- (instancetype)initWithBlockSignature:(nullable JXMethodSignature *)blockSignature;

@end

NS_ASSUME_NONNULL_END
