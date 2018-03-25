//
//  JXKVC.h
//  ObjectiveScript
//
//  Created by Kabir Oberai on 21/03/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

NS_ASSUME_NONNULL_BEGIN

@protocol JXKVC <NSObject>

@required
- (nullable JSValue *)jsPropertyForKey:(NSString *)key ctx:(JSContext *)ctx;

@optional
- (void)setJSProperty:(JSValue *)property forKey:(NSString *)key ctx:(JSContext *)ctx;

@end

NS_ASSUME_NONNULL_END
