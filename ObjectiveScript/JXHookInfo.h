//
//  JXHookInfo.h
//  ObjectiveScript
//
//  Created by Kabir Oberai on 16/11/17.
//  Copyright © 2017 Kabir Oberai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ffi.h>

@interface JXHookInfo : NSObject

/**
 @return the original function's return value
 */
typedef void *(^OrigBlock)(void);

/**
 @param cif the ffi_cif associated with the trampoline
 @param ret the memory into which the return value should be copied
 @param args the original arguments passed into the function
 @param orig a block that can be called with modified arguments to retrieve a return value from the original function
 */
typedef void (^SwizzleBlock)(ffi_cif *cif, void *ret, void **args, OrigBlock orig);

@property (nonatomic, assign) IMP orig;
@property (nonatomic, copy) SwizzleBlock block;

- (instancetype)initWithOrig:(IMP)orig block:(SwizzleBlock)block;

@end
