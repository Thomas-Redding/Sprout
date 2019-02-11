//
//  SPRStatusMenu.h
//  Sprout
//
//  Created by Thomas Redding on 2/3/19.
//  Copyright © 2019 Thomas Redding. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SPRStatusMenu : NSObject

+ (void)rootCreate:(NSString *)rootId;
+ (void)rootDestroy:(NSString *)rootId;
+ (CGFloat)rootGetSpace:(NSString *)rootId;
+ (void)root:(NSString *)rootId setSpace:(CGFloat)space;
+ (NSString *)rootGetText:(NSString *)rootId;
+ (void)root:(NSString *)rootId setText:(NSString *)text;
+ (void)root:(NSString *)rootId addChild:(NSString *)childJSON atIndex:(NSUInteger)index;
+ (void)root:(NSString *)rootId removeChildAtIndex:(NSUInteger)index;

+ (NSString *)textGetText:(NSString *)itemId;
+ (void)text:(NSString *)itemId setText:(NSString *)text;
+ (void)text:(NSString *)itemId addChild:(NSString *)childJSON atIndex:(NSUInteger)index;
+ (void)text:(NSString *)itemId removeChildAtIndex:(NSUInteger)index;

+ (NSString *)webGetIndexPath:(NSString *)itemId;
+ (void)web:(NSString *)itemId setIndexPath:(NSString *)indexPath;
+ (void)web:(NSString *)itemId sendMessage:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
