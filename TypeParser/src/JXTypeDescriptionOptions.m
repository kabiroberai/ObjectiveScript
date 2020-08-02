//
//  JXTypeDescriptionOptions.m
//  TypeParser
//
//  Created by Kabir Oberai on 30/07/20.
//  Copyright © 2020 Kabir Oberai. All rights reserved.
//

#import "JXTypeDescriptionOptions.h"

@implementation JXTypeDescriptionOptions

- (instancetype)initWithUsePadding:(BOOL)usePadding
                    structTypedefs:(JXStructTypedefs)structTypedefs
             demangleTypeNameBlock:(JXTypeNameDemangler)demangleTypeNameBlock {
    self = [super init];
    if (!self) return nil;

    _usePadding = usePadding;
    _structTypedefs = structTypedefs;
    _demangleTypeNameBlock = demangleTypeNameBlock;

    return self;
}

+ (instancetype)optionsWithUsePadding:(BOOL)usePadding
                       structTypedefs:(JXStructTypedefs)structTypedefs
                demangleTypeNameBlock:(nullable JXTypeNameDemangler)demangleTypeNameBlock {
    return [[self alloc] initWithUsePadding:usePadding
                             structTypedefs:structTypedefs
                      demangleTypeNameBlock:demangleTypeNameBlock];
}

- (instancetype)init {
    return [self initWithUsePadding:NO
                     structTypedefs:@{}
              demangleTypeNameBlock:nil];
}

+ (JXTypeDescriptionOptions *)defaultOptions {
    static JXTypeDescriptionOptions *defaultOptions;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary *defaultTypedefs = @{
            @"_NSZone": @"NSZone",
            @"_NSRange": @"NSRange",
            @"CGSize": @"CGSize",
            @"CGPoint": @"CGPoint",
            @"CGRect": @"CGRect",
            @"CGAffineTransform": @"CGAffineTransform",
            @"CATransform3D": @"CATransform3D",
            @"UIEdgeInsets": @"UIEdgeInsets"
        };
        defaultOptions = [JXTypeDescriptionOptions optionsWithUsePadding:NO
                                                          structTypedefs:defaultTypedefs
                                                   demangleTypeNameBlock:nil];
    });
    return defaultOptions;
}

- (id)copyWithZone:(nullable NSZone *)zone {
    return [[self class] optionsWithUsePadding:self.usePadding
                                structTypedefs:self.structTypedefs
                         demangleTypeNameBlock:self.demangleTypeNameBlock];
}

- (instancetype)withPadding:(BOOL)usePadding {
    return [[self class] optionsWithUsePadding:usePadding
                                structTypedefs:self.structTypedefs
                         demangleTypeNameBlock:self.demangleTypeNameBlock];
}

- (instancetype)withStructTypedefs:(JXStructTypedefs)structTypedefs {
    return [[self class] optionsWithUsePadding:self.usePadding
                                structTypedefs:structTypedefs
                         demangleTypeNameBlock:self.demangleTypeNameBlock];
}

- (instancetype)withDemangleTypeNameBlock:(JXTypeNameDemangler)demangleTypeNameBlock {
    return [[self class] optionsWithUsePadding:self.usePadding
                                structTypedefs:self.structTypedefs
                         demangleTypeNameBlock:demangleTypeNameBlock];
}

- (NSString *)padding {
    return self.usePadding ? @" " : @"";
}

- (nullable NSString *)demangleTypeName:(NSString *)typeName {
    if (!self.demangleTypeNameBlock) return nil;
    return self.demangleTypeNameBlock(typeName);
}

@end
