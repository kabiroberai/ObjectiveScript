//
//  NSScanner+Utils.m
//  TypeParser
//
//  Created by Kabir Oberai on 20/07/20.
//  Copyright © 2020 Kabir Oberai. All rights reserved.
//

#import "NSScanner+Utils.h"

void *NSScannerUtilsDummy = NULL;

@implementation NSScanner (Utils)

- (char)currentCharacter {
    return (char)[self.string characterAtIndex:self.scanLocation];
}

@end
