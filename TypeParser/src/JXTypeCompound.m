//
//  JXTypeCompound.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 11/03/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import "JXTypeCompound.h"
#import "JXTypeID.h"

@interface JXTypeCompound () <JXConcreteType> @end

@implementation JXTypeCompound

// NOTE: references to structs in the comments also apply to unions

+ (char)startDelim { return 0; }
+ (char)endDelim { return 0; }
+ (NSString *)typeName { return nil; }

+ (BOOL)supportsEncoding:(char)encoding {
    return encoding == [self class].startDelim;
}

- (NSString *)unknownFieldNameAtIndex:(NSUInteger)index {
    return [NSString stringWithFormat:@"x%lu", (long)index];
}

- (instancetype)initWithScanner:(NSScanner *)scanner qualifiers:(JXTypeQualifiers)qualifiers {
    self = [super initWithQualifiers:qualifiers];
    if (!self) return nil;

    NSString *endDelimString = [NSString stringWithFormat:@"%c", [self class].endDelim];

    // eat '{'
    scanner.scanLocation += 1;

    // Not all structs will have types. For example, doubly indirect structs are in the form
    // `^^{foo}`. So just scan up to the next = or }, whichever comes first.
    NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:
                           [NSString stringWithFormat:@"=%c", [self class].endDelim]];
    NSString *name = nil;
    if (![scanner scanUpToCharactersFromSet:set intoString:&name] && scanner.isAtEnd) return nil;
    _name = name;

    // ? represents an anonymous struct/union
    if (_name.length == 0 || [_name isEqualToString:@"?"]) _name = nil;

    if ([scanner scanString:@"=" intoString:nil]) {
        // we have type info

        NSMutableArray<JXType *> *types = [NSMutableArray array];
        // only create fieldNames if first char after = is a double quote
        NSMutableArray<NSString *> *fieldNames = (scanner.currentCharacter == '"') ? [NSMutableArray array] : nil;

        NSUInteger lastLocation = -1;

        while (![scanner scanString:endDelimString intoString:nil]) {
            // get the field name if this struct has them
            if (fieldNames) {
                if (![scanner scanString:@"\"" intoString:nil]) {
                    // the previous type was an untyped id which ate the following type's name
                    // eg. struct Foo { id bar; int baz; }
                    // which turned into {Foo="bar"@"baz"i}
                    // but JXTypeID thought the "baz" was its own type

                    // backtrack and tell the type to not take eat names this time
                    // note: we don't simply use the JXTypeID initializer because the type may be ^@"baz" too
                    [types removeLastObject];
                    scanner.scanLocation = lastLocation;

                    @synchronized (JXTypeIDIgnoreNameLock) {
                        JXTypeIDIgnoreName = YES;
                        [types addObject:[JXType typeWithScanner:scanner]];
                        JXTypeIDIgnoreName = NO;
                    }

                    scanner.scanLocation += 1; // eat "
                }

                // note: we've now eaten the opening "

                NSString *fieldName;
                if (![scanner scanUpToString:@"\"" intoString:&fieldName] && scanner.isAtEnd) return nil;
                if (fieldName.length == 0) fieldName = [self unknownFieldNameAtIndex:fieldNames.count];
                [fieldNames addObject:fieldName];

                scanner.scanLocation += 1; // eat closing "

                // store the previous type encoding so that if the id bug happens we can backtrack
                lastLocation = scanner.scanLocation;
            }

            JXType *type = [JXType typeWithScanner:scanner];
            if (!type)
                return nil;
            [types addObject:type];
        }

        _types = [types copy];
        _fieldNames = [fieldNames copy];
    } else {
        _types = nil;
        // it's safe to assume that the current char is the endDelim because the only other case, the = sign,
        // was handled in the above branch
        scanner.scanLocation += 1;
    }

    return self;
}

- (instancetype)initWithName:(NSString *)name types:(NSArray<JXType *> *)types fieldNames:(NSArray<NSString *> *)fieldNames {
    self = [super init];
    if (!self) return nil;

    NSMutableString *str = [NSMutableString stringWithFormat:@"%c%@", [self class].startDelim, name ?: @"?"];
    if (types) {
        [str appendString:@"="];
        for (int i = 0; i < types.count; i++) {
            if (fieldNames) {
                [str appendFormat:@"\"%@\"", fieldNames[i]];
            }
            [str appendString:types[i].encoding];
        }
    }
    [str appendFormat:@"%c", [self class].endDelim];

    _encoding = [str copy];
    _name = name;
    _types = types;
    _fieldNames = fieldNames;

    return self;
}

- (JXTypeDescription *)baseDescriptionWithOptions:(JXTypeDescriptionOptions *)options {
    // if the type metadata is present, add it to the description
    NSMutableString *typesStr = [NSMutableString string];
    if (self.types && self.types.count > 0) {
        [typesStr appendString:@" { "];
        for (NSUInteger i = 0; i < self.types.count; i++) {
            NSString *subfieldName = self.fieldNames[i] ?: [self unknownFieldNameAtIndex:(i + 1)];
            JXTypeDescription *description = [self.types[i] descriptionWithOptions:[options withPadding:YES]];
            [typesStr appendFormat:@"%@%@%@; ", description.head, subfieldName, description.tail];
        }
        [typesStr appendString:@"}"];
    }

    // generate a string representing the type
    NSString *type = [NSString stringWithFormat:@"%@%@%@",
                      [[self class] typeName],
                      self.name ? [@" " stringByAppendingString:self.name] : @"",
                      typesStr];

    return [JXTypeDescription descriptionWithHead:[type stringByAppendingString:options.padding]];
}

@end
