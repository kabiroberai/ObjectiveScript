//
//  JXTypeQualifier.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 12/03/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JXTypeQualifiers.h"
#import "JXTypeQualifiers+Private.h"

JXTypeQualifiers JXTypeQualifierForEncoding(char enc) {
    switch (enc) {
        case 'j': return JXTypeQualifierVolatile;
        case 'r': return JXTypeQualifierConst;
        case 'n': return JXTypeQualifierIn;
        case 'N': return JXTypeQualifierInout;
        case 'o': return JXTypeQualifierOut;
        case 'O': return JXTypeQualifierBycopy;
        case 'R': return JXTypeQualifierByref;
        case 'V': return JXTypeQualifierOneway;
        case 'A': return JXTypeQualifierAtomic;
        default : return JXTypeQualifierNone;
    }
}

// Strip and return any qualifiers from `type` (const, inout, etc)
JXTypeQualifiers JXRemoveQualifiersWithScanner(NSScanner *scanner) {
    static NSCharacterSet *qualifierSet;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        qualifierSet = [NSCharacterSet characterSetWithCharactersInString:@"jrnNoORVA"];
    });

    JXTypeQualifiers qualifiers = JXTypeQualifierNone;

    NSString *qualifierString = nil;
    if ([scanner scanCharactersFromSet:qualifierSet intoString:&qualifierString]) {
        // only do this if we actually scanned something
        for (NSUInteger i = 0; i < qualifierString.length; i++) {
            qualifiers |= JXTypeQualifierForEncoding([qualifierString characterAtIndex:i]);
        }
    }

    return qualifiers;
}

JXTypeQualifiers JXRemoveQualifiers(const char **encoding) {
    NSScanner *scanner = [NSScanner scannerWithString:@(*encoding)];
    JXTypeQualifiers qualifiers = JXRemoveQualifiersWithScanner(scanner);
    if (strlen(*encoding) >= scanner.scanLocation) {
        // this should be correct since encodings are ASCII. It's also safe due to the
        // strlen check. Even if strlen == location, we'll end up on the NUL byte
        *encoding += scanner.scanLocation;
    }
    return qualifiers;
}

NSArray<NSString *> *JXStringsForTypeQualifiers(JXTypeQualifiers qualifiers) {
    if (qualifiers == JXTypeQualifierNone) return @[];
    
    NSMutableArray<NSString *> *qualifierNames = [NSMutableArray array];

#define addTerm(Type, type) if (qualifiers & JXTypeQualifier##Type) [qualifierNames addObject:@#type];

    // sorted alphabetically
    addTerm(Atomic, _Atomic);
    addTerm(Bycopy, bycopy);
    addTerm(Byref, byref);
    addTerm(Const, const);
    addTerm(In, in);
    addTerm(Inout, inout);
    addTerm(Oneway, oneway);
    addTerm(Out, out);
    addTerm(Volatile, volatile)

    return [qualifierNames copy];
}
