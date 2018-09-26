//
//  JXTypeID.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 11/03/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import <objc/runtime.h>
#import "JXTypeID.h"

BOOL JXTypeIDIgnoreName = NO;
NSString *JXTypeIDIgnoreNameLock = @"JXTypeIDIgnoreNameLock";

@implementation JXTypeID

+ (BOOL)supportsEncoding:(char)encoding {
    return encoding == _C_ID;
}

- (instancetype)initWithEncoding:(const char **)enc qualifiers:(JXTypeQualifiers)qualifiers {
    self = [super initWithEncoding:enc qualifiers:qualifiers];
    if (self) {
        const char *start = *enc; // get '@' and advance string
        *enc += 1;

        @synchronized (JXTypeIDIgnoreNameLock) {
            // ids may have names in front of them, eg. @"NSString", so parse them if needed
            // see JXTypeComplex initWithEncoding for details on `JXTypeIDIgnoreName`
            if (!JXTypeIDIgnoreName && **enc == '"') {
                *enc += 1;
                const char *nameStart = *enc;
                char *nameEnd = strchr(*enc, '"');
                _name = [self stringBetweenStart:nameStart end:nameEnd];
                *enc = nameEnd + 1;

                // the object name may have protocols like @"<NSCopying><NSCoding>" or @"Foo<NSCopying><NSCoding>"
                // parse them if they exist.
                NSArray<NSString *> *protoParts = [_name componentsSeparatedByString:@"<"];
                if (protoParts.count > 1) {
                    // rather than using the whole string as the name, only take the part before the <
                    // if there's nothing before the <, set the name to nil
                    if (*_name.UTF8String == '<') {
                        _name = nil;
                    } else {
                        _name = protoParts[0];
                    }

                    NSMutableArray<NSString *> *protocols = [NSMutableArray arrayWithCapacity:protoParts.count - 1];
                    for (NSUInteger i = 1; i < protoParts.count; i++) {
                        NSString *protocol = protoParts[i];
                        // remove the trailing > from protocol names since we only split on <
                        protocol = [protocol substringToIndex:protocol.length - 1];
                        [protocols addObject:protocol];
                    }
                    _protocols = [protocols copy];
                }
            } else if (**enc == '?') {
                // represents a block
                _isBlock = YES;
                *enc += 1;
            }
        }

        _encoding = [self stringBetweenStart:start end:*enc];
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name protocols:(NSArray<NSString *> *)protocols isBlock:(BOOL)isBlock {
    NSMutableString *curr = [@(@encode(id)) mutableCopy];
    if (isBlock) {
        [curr appendString:@"?"];
    } else {
        if (name || protocols) [curr appendString:@"\""];
        if (name) [curr appendString:name];
        if (protocols) {
            for (NSString *proto in protocols) {
                [curr appendFormat:@"<%@>", proto];
            }
        }
        if (name || protocols) [curr appendString:@"\""];
    }
    const char *enc = curr.UTF8String;
    self = [super initWithEncoding:&enc qualifiers:JXTypeQualifierNone];
    if (self) {
        _encoding = [curr copy];
        _name = name;
        _protocols = protocols;
        _isBlock = isBlock;
    }
    return self;
}

- (JXTypeDescription *)_descriptionWithPadding:(BOOL)padding {
    // if there are any protocols, add them to the description
    NSString *protoList;

    if (self.protocols) {
        protoList = [NSString stringWithFormat:@"<%@>", [self.protocols componentsJoinedByString:@", "]];
    } else {
        protoList = @"";
    }

    if (_isBlock) {
        return [JXTypeDescription descriptionWithHead:@"void (^" tail:@")(void)"];
    } else if (self.name) {
        return [JXTypeDescription
                descriptionWithHead:[NSString stringWithFormat:@"%@%@ *", self.name, protoList]
                tail:@""];
    } else {
        return [JXTypeDescription
                descriptionWithHead:[NSString stringWithFormat:@"id%@%@", protoList, padding ? @" " : @""]
                tail:@""];
    }
}

@end
