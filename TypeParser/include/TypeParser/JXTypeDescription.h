//
//  JXTypeDescription.h
//  ObjectiveScript
//
//  Created by Kabir Oberai on 17/03/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JXTypeDescription : NSObject

@property (nonatomic, readonly) NSString *head;
@property (nonatomic, readonly) NSString *tail;

- (instancetype)initWithHead:(NSString *)head tail:(NSString *)tail;
+ (instancetype)descriptionWithHead:(NSString *)head tail:(NSString *)tail;
+ (instancetype)descriptionWithHead:(NSString *)head;
+ (instancetype)descriptionWithTail:(NSString *)tail;

// returns a new description type by prepending `description.head` with self.head, and
// appending self.tail to description.tail
- (JXTypeDescription *)sandwiching:(JXTypeDescription *)description;

@end

NS_ASSUME_NONNULL_END
