//
//  JXTypeDescription.h
//  ObjectiveScript
//
//  Created by Kabir Oberai on 17/03/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JXTypeDescription : NSObject

@property (nonatomic, readonly) NSString *head;
@property (nonatomic, readonly) NSString *tail;

- (instancetype)initWithHead:(NSString *)head tail:(NSString *)tail;
+ (instancetype)descriptionWithHead:(NSString *)head tail:(NSString *)tail;

@end
