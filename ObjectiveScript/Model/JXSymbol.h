//
//  JXSymbol.h
//  ObjectiveScript
//
//  Created by Kabir Oberai on 25/01/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JXSymbol : NSObject

@property (nonatomic, readonly) void *symbol;
@property (nonatomic, readonly) NSString *types;

- (instancetype)initWithSymbol:(void *)symbol types:(NSString *)types;

@end
