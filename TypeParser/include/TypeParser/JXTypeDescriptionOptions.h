//
//  JXTypeDescriptionOptions.h
//  TypeParser
//
//  Created by Kabir Oberai on 30/07/20.
//  Copyright © 2020 Kabir Oberai. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSString * _Nullable (^JXTypeNameDemangler)(NSString *);
typedef NSDictionary<NSString *, NSString *> *JXStructTypedefs;

@interface JXTypeDescriptionOptions : NSObject <NSCopying>

// MARK: Structure

- (instancetype)initWithUsePadding:(BOOL)usePadding
                    structTypedefs:(JXStructTypedefs)structTypedefs
             demangleTypeNameBlock:(nullable JXTypeNameDemangler)demangleTypeNameBlock;

+ (instancetype)optionsWithUsePadding:(BOOL)usePadding
                       structTypedefs:(JXStructTypedefs)structTypedefs
                demangleTypeNameBlock:(nullable JXTypeNameDemangler)demangleTypeNameBlock;

// a configured instance of JXTypeDescriptionOptions, with some preset values for
// structTypedefs
@property (nonatomic, class, readonly) JXTypeDescriptionOptions *defaultOptions;

// whether the description should add padding for the identifier
// defaults to NO
@property (nonatomic, readonly) BOOL usePadding;

// a dictionary of struct types along with their corresponding typedef values. For
// example, `@"_NSRange": @"NSRange"` effectively means `typedef struct _NSRange NSRange;`
// and all instances of `struct _NSRange { /* blah */ }` will be replaced with just `NSRange`.
// defaults to an empty dictionary
@property (nonatomic, readonly) JXStructTypedefs structTypedefs;

// a block which accepts a type name and returns a demangled value, or nil if the type was
// not demangle-able.
// defaults to nil
@property (nonatomic, nullable, readonly) JXTypeNameDemangler demangleTypeNameBlock;

// copies the object with the provided value of usePadding
- (instancetype)withPadding:(BOOL)usePadding;

// copies the object with the provided value of structTypedefs
- (instancetype)withStructTypedefs:(JXStructTypedefs)structTypedefs;

// copies the object with the provided value of demangleTypeNameBlock
- (instancetype)withDemangleTypeNameBlock:(nullable JXTypeNameDemangler)demangleTypeNameBlock;

// MARK: Helpers

// a single space if usePadding is YES, else an empty string
@property (nonatomic, readonly) NSString *padding;

// delegates to demangleTypeNameBlock if that is set, else returns nil
- (nullable NSString *)demangleTypeName:(NSString *)typeName;

@end

NS_ASSUME_NONNULL_END
