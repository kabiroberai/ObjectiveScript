//
//  NSString+IsNumeric.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 02/12/19.
//  Copyright © 2019 Kabir Oberai. All rights reserved.
//

#import "NSString+IsNumeric.h"

@implementation NSString (IsNumeric)

- (BOOL)isNumeric {
    static NSCharacterSet *nonNumeric = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        nonNumeric = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet];
    });
    return [self rangeOfCharacterFromSet:nonNumeric].location == NSNotFound;
}

@end
