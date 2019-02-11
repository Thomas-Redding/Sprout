//
//  SPRStatusMenu.m
//  Sprout
//
//  Created by Thomas Redding on 2/3/19.
//  Copyright © 2019 Thomas Redding. All rights reserved.
//

#import "SPRStatusMenu.h"

@interface SPRStatusItem : NSObject
- (instancetype)initWithId:(NSString *)itemId;
@property (readonly) NSString *itemId;
@end
@implementation SPRStatusItem
- (instancetype)initWithId:(NSString *)itemId {
  self = [super init];
  if (self) _itemId = itemId;
  return self;
}
@end


@interface SPRRootStatusMenu : NSObject
- (instancetype)initWithId:(NSString *)itemId;
@property (readonly) NSString *itemId;
@property CGFloat space;
@property NSString *text;
@property (readonly) NSArray<SPRStatusItem *> *children;
- (void)insertChild:(SPRStatusItem *)item atIndex:(NSUInteger)index;
- (void)removeChildAtIndex:(NSUInteger)index;
- (void)cleanUp;
@end
@implementation SPRRootStatusMenu
- (instancetype)initWithId:(NSString *)itemId {
  self = [super init];
  if (self) _itemId = itemId;
  return self;
}
- (CGFloat)space {}
- (void)setSpace:(CGFloat)space {}
- (NSString *)text {}
- (void)setText:(NSString *)text {}
- (void)insertChild:(SPRStatusItem *)item atIndex:(NSUInteger)index {}
- (void)removeChildAtIndex:(NSUInteger)index {}
- (void)cleanUp {}
@end



@interface SPRTextStatusItem : SPRStatusItem
@property NSString *text;
@property (readonly) NSArray<SPRStatusItem *> *children;
- (void)insertChild:(SPRStatusItem *)item atIndex:(NSUInteger)index;
- (void)removeChildAtIndex:(NSUInteger)index;
@end
@implementation SPRTextStatusItem
- (NSString *)text {}
- (void)setText:(NSString *)text {}
- (void)insertChild:(SPRStatusItem *)item atIndex:(NSUInteger)index {}
- (void)removeChildAtIndex:(NSUInteger)index {}
@end



@interface SPRWebStatusItem : SPRStatusItem
@property NSString *indexPath;
- (void)sendMessage:(NSString *)message;
@end
@implementation SPRWebStatusItem
- (NSString*)indexPath { return @""; }
- (void)setIndexPath:(NSString *)indexPath {}
- (void)sendMessage:(NSString *)message {}
@end









static NSMutableDictionary<NSString *, SPRRootStatusMenu *> *_rootMenus;
static NSMutableDictionary<NSString *, SPRTextStatusItem *> *_textItems;
static NSMutableDictionary<NSString *, SPRWebStatusItem *> *_webItems;

@implementation SPRStatusMenu

# pragma mark - Initializer

+(void)initialize {
  _rootMenus = [[NSMutableDictionary alloc] init];
  _textItems = [[NSMutableDictionary alloc] init];
  _webItems = [[NSMutableDictionary alloc] init];
}

# pragma mark - Public

+ (void)rootCreate:(NSString *)rootId {
  SPRRootStatusMenu *x = [[SPRRootStatusMenu alloc] initWithId:rootId];
  [_rootMenus setObject:x forKey:rootId];
}
+ (void)rootDestroy:(NSString *)rootId {
  [_rootMenus[rootId] cleanUp];
  [_rootMenus removeObjectForKey:rootId];
}
+ (CGFloat)rootGetSpace:(NSString *)rootId {
  return [_rootMenus[rootId] space];
}
+ (void)root:(NSString *)rootId setSpace:(CGFloat)space {
  [_rootMenus[rootId] setSpace:space];
}
+ (NSString *)rootGetText:(NSString *)rootId {
  return [_rootMenus[rootId] text];
}
+ (void)root:(NSString *)rootId setText:(NSString *)text {
  [_rootMenus[rootId] setText:text];
}
+ (void)root:(NSString *)rootId addChild:(NSString *)childJSON atIndex:(NSUInteger)index {
  // TODO
}
+ (void)root:(NSString *)rootId removeChildAtIndex:(NSUInteger)index {
  [_rootMenus[rootId] removeChildAtIndex:index];
}

+ (NSString *)textGetText:(NSString *)itemId {
  return [_textItems[itemId] text];
}
+ (void)text:(NSString *)itemId setText:(NSString *)text {
  [_textItems[itemId] setText:text];
}
+ (void)text:(NSString *)itemId addChild:(NSString *)childJSON atIndex:(NSUInteger)index {
  // TODO
}
+ (void)text:(NSString *)itemId removeChildAtIndex:(NSUInteger)index {
  [_textItems[itemId] removeChildAtIndex:index];
}

+ (NSString *)webGetIndexPath:(NSString *)itemId {
  return [_webItems[itemId] indexPath];
}
+ (void)web:(NSString *)itemId setIndexPath:(NSString *)indexPath {
  [_webItems[itemId] setIndexPath:indexPath];
}
+ (void)web:(NSString *)itemId sendMessage:(NSString *)message {
  [_webItems[itemId] sendMessage:message];
}


@end
