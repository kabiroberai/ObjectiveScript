//
//  JXTypeComplex.h
//  ObjectiveScript
//
//  Created by Kabir Oberai on 11/03/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import "JXType.h"

NS_ASSUME_NONNULL_BEGIN

@interface JXTypeComplex : JXType

+ (char)startDelim;
+ (char)endDelim;
+ (NSString *)typeName;

// nil if no name
@property (nonatomic, readonly, nullable) NSString *name;
// nil if no type info
@property (nonatomic, readonly, nullable) NSArray<JXType *> *types;
// nil if no name info
@property (nonatomic, readonly, nullable) NSArray<NSString *> *fieldNames;

- (instancetype)initWithName:(nullable NSString *)name types:(nullable NSArray<JXType *> *)types fieldNames:(nullable NSArray<NSString *> *)fieldNames;

@end

NS_ASSUME_NONNULL_END
