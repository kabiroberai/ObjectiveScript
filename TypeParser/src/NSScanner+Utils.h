//
//  NSScanner+Utils.h
//  TypeParser
//
//  Created by Kabir Oberai on 20/07/20.
//  Copyright © 2020 Kabir Oberai. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// required to register category.
// See https://medium.com/ios-os-x-development/categories-in-static-libraries-78e41f8ddb96
extern void *NSScannerUtilsDummy;

@interface NSScanner (Utils)

@property (readonly) char currentCharacter;

@end

NS_ASSUME_NONNULL_END
