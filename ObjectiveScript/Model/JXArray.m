//
//  JXArray.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 25/03/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import "JXArray.h"
#import "JXJSInterop.h"

@implementation JXArray

- (instancetype)initWithVal:(void *)val type:(NSString *)type count:(NSUInteger)count {
    self = [super initWithVal:val type:type];
    if (self) {
        _count = count;
    }
    return self;
}

+ (instancetype)arrayWithVal:(void *)val type:(NSString *)type count:(NSUInteger)count {
    return [[self alloc] initWithVal:val type:type count:count];
}

- (JSValue *)jsPropertyForKey:(NSString *)key ctx:(JSContext *)ctx {
    // makes JXArray JS-array-like so Array.from() works with it
    if ([key isEqualToString:@"length"]) {
        return JXConvertToJSValue(&_count, @encode(NSUInteger), ctx, JXInteropOptionNone);
    }

    // we could add a check here to ensure that the array index is within bounds, but C allows out-of-bounds
    // access (although it's UB)
    return [super jsPropertyForKey:key ctx:ctx];
}

@end
