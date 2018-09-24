//
//  JXTypeComplex.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 11/03/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import "JXTypeComplex.h"
#import "JXTypeID.h"
#import "JXJSInterop.h"

@implementation JXTypeComplex

// NOTE: references to structs in the comments also apply to unions

+ (char)startDelim { return 0; }
+ (char)endDelim { return 0; }
+ (NSString *)typeName { return nil; }

+ (BOOL)supportsEncoding:(char)encoding {
    return encoding == [[self class] startDelim];
}

- (instancetype)initWithEncoding:(const char **)enc qualifiers:(JXTypeQualifiers)qualifiers {
    self = [super initWithEncoding:enc qualifiers:qualifiers];
    if (self) {
        const char *encStart = *enc;

        // eat '{'
        *enc += 1;

        // get name
        char *nameEnd = strchr(*enc, '=');
        char *structEnd = strchr(*enc, [[self class] endDelim]);
        // doubly-indirect structs don't have type info (eg. ^^{foo})
        // so the name will be till the struct end.
        // if nameEnd isn't null, it may belong to another struct, so ensure that
        // it comes before the struct end
        BOOL hasTypeInfo = (nameEnd != NULL && nameEnd < structEnd);
        if (!hasTypeInfo) nameEnd = structEnd;

        // jump to the end of the name
        *enc = nameEnd;

        _name = [self stringBetweenStart:encStart+1 end:*enc];

        // ? represents an anonymous struct/union
        if ([_name isEqualToString:@"?"] || [_name isEqualToString:@""]) _name = nil;

        if (hasTypeInfo) {
            *enc += 1; // eat '=' as well

            NSMutableArray<JXType *> *types = [NSMutableArray array];
            // only create fieldNames if first char after = is a double quote
            NSMutableArray<NSString *> *fieldNames = (**enc == '"') ? [NSMutableArray array] : nil;

            const char *prevTypeEnc = NULL;

            while (**enc != [[self class] endDelim]) {
                // get the field name if this struct has them
                if (fieldNames) {
                    if (**enc != '"' && prevTypeEnc != NULL) {
                        // the previous type was an untyped id which ate the following type's name
                        // eg. struct Foo { id bar; int baz; }
                        // which turned into {Foo="bar"@"baz"i}
                        // but JXTypeID thought the "baz" was its own type

                        // backtrack and tell the type to not take eat names this time
                        // note: we don't simply use the JXTypeID initializer because the type may be ^@"baz" too
                        [types removeLastObject];
                        *enc = prevTypeEnc;

                        @synchronized (JXTypeIDIgnoreNameLock) {
                            JXTypeIDIgnoreName = YES;
                            [types addObject:JXTypeWithEncoding(enc)];
                            JXTypeIDIgnoreName = NO;
                        }
                    }
                    *enc += 1; // eat '"'
                    const char *fieldEnd = strchr(*enc, '"');
                    [fieldNames addObject:[self stringBetweenStart:*enc end:fieldEnd]];
                    *enc = fieldEnd + 1;

                    // store the previous type encoding so that if the id bug happens we can backtrack
                    prevTypeEnc = *enc;
                }

                JXType *type = JXTypeWithEncoding(enc);
                [types addObject:type];
            }

            _types = [types copy];
            _fieldNames = [fieldNames copy];
        } else {
            _types = nil;
        }

        *enc += 1; // eat '}'

        _encoding = [self stringBetweenStart:encStart end:*enc];
    }
    return self;
}

- (JXTypeDescription *)_descriptionWithPadding:(BOOL)padding {
    // if the type metadata is present, add it to the description
    NSMutableString *typesStr = [NSMutableString string];
    if (self.types && self.types.count > 0) {
        [typesStr appendString:@" { "];
        for (NSUInteger i = 0; i < self.types.count; i++) {
            NSString *subfieldName = self.fieldNames[i] ? : [NSString stringWithFormat:@"field%lu", (long)(i+1)];
            JXTypeDescription *description = [self.types[i] descriptionWithPadding:YES];
            [typesStr appendFormat:@"%@%@%@; ", description.head, subfieldName, description.tail];
        }
        [typesStr appendString:@"}"];
    }

    // generate a string representing the type
    NSString *type = [NSString stringWithFormat:@"%@%@%@",
                      [[self class] typeName],
                      self.name ? [@" " stringByAppendingString:self.name] : @"",
                      typesStr];

    return [JXTypeDescription
            descriptionWithHead:[type stringByAppendingString:padding ? @" " : @""]
            tail:@""];
}

@end
