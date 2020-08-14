//
//  JXTypeQualifiers.h
//  ObjectiveScript
//
//  Created by Kabir Oberai on 12/03/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, JXTypeQualifiers) {
    JXTypeQualifierNone = 0,
    JXTypeQualifierComplex = 1 << 0,
    JXTypeQualifierConst = 1 << 1,
    JXTypeQualifierIn = 1 << 2,
    JXTypeQualifierInout = 1 << 3,
    JXTypeQualifierOut = 1 << 4,
    JXTypeQualifierBycopy = 1 << 5,
    JXTypeQualifierByref = 1 << 6,
    JXTypeQualifierOneway = 1 << 7,
    JXTypeQualifierAtomic = 1 << 8,
};

JXTypeQualifiers JXTypeQualifierForEncoding(char enc) NS_SWIFT_NAME(JXTypeQualifiers.init(encoding:));
JXTypeQualifiers JXRemoveQualifiers(const char * _Nonnull * _Nonnull encoding) NS_SWIFT_NAME(JXTypeQualifiers.init(removingQualifiersFromEncoding:));
NSArray<NSString *> *JXStringsForTypeQualifiers(JXTypeQualifiers qualifiers) NS_SWIFT_NAME(getter:JXTypeQualifiers.strings(self:));

NS_ASSUME_NONNULL_END
