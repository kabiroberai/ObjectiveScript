//
//  JXTypeQualifier.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 12/03/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JXTypeQualifiers.h"

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
JXTypeQualifiers JXRemoveQualifiers(const char **enc) {
    JXTypeQualifiers qualifier = JXTypeQualifierForEncoding(**enc);
    if (qualifier == JXTypeQualifierNone) return qualifier;

    *enc += 1;

    // Remove any more qualifiers, and return this qualifier + any further ones
    return qualifier | JXRemoveQualifiers(enc);
}

NSString *JXStringForTypeQualifiers(JXTypeQualifiers qualifiers) {
    if (qualifiers == JXTypeQualifierNone) return nil;
    
    NSMutableArray<NSString *> *qualifierNames = [NSMutableArray array];

#define addTerm(Type, type) if (qualifiers & JXTypeQualifier##Type) [qualifierNames addObject:@#type];

    addTerm(Volatile, volatile)
    addTerm(Const, const);
    addTerm(In, in);
    addTerm(Inout, inout);
    addTerm(Out, out);
    addTerm(Bycopy, bycopy);
    addTerm(Byref, byref);
    addTerm(Oneway, oneway);
    addTerm(Atomic, _Atomic);

    return [qualifierNames componentsJoinedByString:@" "];
}
