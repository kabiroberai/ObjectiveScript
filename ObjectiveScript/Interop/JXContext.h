//
//  JXContext.h
//  ObjectiveScript
//
//  Created by Kabir Oberai on 30/11/19.
//  Copyright © 2019 Kabir Oberai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "JXConfiguration.h"
#import "JXSymbol.h"

NS_ASSUME_NONNULL_BEGIN

@interface JXContext : NSObject

- (instancetype)initWithConfiguration:(JXConfiguration *)configuration;

@property (nonatomic, retain) JXConfiguration *configuration;

@property (nonatomic, retain, readonly) NSMutableDictionary<NSString *, NSString *> *structDefs;

// [class : [ivar : key]]
typedef NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, NSString *> *> JXAssociatedObjectsDict;
@property (nonatomic, retain, readonly) JXAssociatedObjectsDict *associatedObjects;

typedef NSMutableDictionary<NSString *, JXSymbol *> JXSymbolsDict;
@property (nonatomic, retain, readonly) JXSymbolsDict *symbols;

@end

NS_ASSUME_NONNULL_END
