#import <Foundation/Foundation.h>

#import "SPRWebWindow.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPRWindowInfo : NSObject
- (instancetype)initWithName:(NSString *)name number:(NSNumber *)number processID:(NSNumber *)processID frame:(CGRect)rect;
@property(nonatomic) NSString *name;
@property(nonatomic) NSNumber *number;
@property(nonatomic) NSNumber *processID;
@property(nonatomic) CGRect frame;
@end

@protocol SPRSeedDelegate <NSObject>
- (void)windowAdded:(SPRWindowInfo *)windowInfo;
- (void)windowMoved:(SPRWindowInfo *)windowInfo;
- (void)windowRemoved;
- (void)didReceiveMessage:(NSString *)message fromWindow:(NSString *)windowId;
- (void)mouseButtonPressed:(NSEventType)eventType;
- (void)mouseMove:(NSEventType)eventType;
- (void)webWindowDidLoad:(NSString *)windowId;
- (void)webWindowDidBecomeMain:(NSString *)windowId;
- (void)webWindowDidResignMain:(NSString *)windowId;
@end

@interface SPRContact : NSObject
@property NSString *name;
@end

typedef NS_OPTIONS(NSUInteger, SPRMouseEvent) {
  SPRMouseEventLeftMouseDown,
  SPRMouseEventLeftMouseUp,
  SPRMouseEventRightMouseDown,
  SPRMouseEventRightMouseUp,
  SPRMouseEventMouseMoved,
  SPRMouseEventLeftMouseDragged,
  SPRMouseEventRightMouseDragged,
  SPRMouseEventMouseEntered,
  SPRMouseEventMouseExited,
  SPRMouseEventOtherMouseDown,
  SPRMouseEventOtherMouseUp,
  SPRMouseEventOtherMouseDragged,
};

typedef NS_OPTIONS(NSUInteger, SPRKeyFlag) {
  SPRKeyFlagNone    = 0,
  SPRKeyFlagCommand = 1,
  SPRKeyFlagOption  = 2,
  SPRKeyFlagControl = 4,
  SPRKeyFlagShift   = 8,
};

@interface SPRSeed : NSObject

#pragma mark - User Input

/**
 @brief Calls a selector when the user presses a hotkey.
 @discussion Each hotkey can only be registered once.
 @param keyCode  An integer representing a physical key.
 @param keyFlag  A bitmask specify which modifier keys are to be held down.
 @param target   The object or class that owns the selector.
 @param selector The selector/method to call when the hotkey is pressed.
 @return         Whether or not registeration is successful.
 */
+ (BOOL)registerHotKeyFromKeyCode:(UInt32)keyCode
                          keyFlag:(SPRKeyFlag)keyFlag
                         toTarget:(id)target
                      andSelector:(SEL)selector;

/**
 @brief Calls the selector when the mouse does something (click, move, drag, etc).
 @discussion Multiple selectors can register mouse events.
 @param mouseEventFlag An enum indicating what kind of mouse event to alert the selector of.
 @param target         The object or class that owns the selector.
 @param selector       The selector/method to call when the event occurs.
 */
+ (void)registerMouseEvent:(SPRMouseEvent)mouseEventFlag
                  toTarget:(id)target
               andSelector:(SEL)selector;

#pragma mark - Windows

+ (void)setFrame:(CGRect)rect ofWindowWithNumber:(NSNumber *)windowNumber;

+ (CGRect)getFrontmostWindowFrame;

+ (void)setFrontmostWindowFrame:(CGRect)windowFrame;

/**
 The number of seconds to poll window changes.
 The default value is 0.1, which causes roughly 2% of CPU usage.
 */
+ (CGFloat)windowTrackInterval;

+ (void)setWindowTrackInterval:(CGFloat)interval;

#pragma mark - Sprout Windows

+ (void)makeWindowWithId:(NSString *)windowId;

+ (SPRWebWindow *)windowForId:(NSString *)windowId;

+ (void)closeWindow:(NSString *)windowId;

+ (void)setIndexPath:(NSString *)indexPath ofWindow:(NSString *)windowId;

+ (void)webWindowDidLoad:(NSString *)windowId;

+ (void)didReceiveMessage:(NSString *)message fromWindow:(NSString *)windowId;

+ (void)sendMessage:(NSString *)message toWindow:(NSString *)windowId;

/**
 A class property that allows the delegate to be notified of window changes.
 */
+ (id<SPRSeedDelegate>)delegate;

+ (void)setDelegate:(id<SPRSeedDelegate>)delegate;

#pragma mark - Other

/**
 Should return a list of contacts in the future. Doesn't work at the moment. TODO: make work.
 */
+ (NSArray<SPRContact *> *)contacts;

+ (NSString*)runAppleScript:(NSString*)string;

// Note: rtn.count may be greater than 1.
// rtn[i][0] = text
// rtn[i][1] = html
+ (NSArray<NSArray<NSString *> *> *)dictionaryEntryForWord:(NSString *)word;

#pragma mark - Quasi Private

+ (void)webWindowDidBecomeMain:(NSString *)windowId;
+ (void)webWindowDidResignMain:(NSString *)windowId;

@end

NS_ASSUME_NONNULL_END
