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
+ (void)didReceiveMessage:(NSString *)message fromWindow:(NSString *)windowId;
+ (void)windowDidLoad:(NSString *)windowId;
@end

@interface SPRContact : NSObject
@property NSString *name;
@end

/**
 By default we find all the files and directories that are children of the home directory.
 On modern computers, roughly 40,000 files can be found in a second.
 */
@interface SPRFileSearchQuery : NSObject
/* Whether or not to consider files in subdirs. */
@property(nonatomic) BOOL descendSubdirs;
/* Skip hidden files and dirs for both matching and descending. */
@property(nonatomic) BOOL searchHidden;
/* Include direcories in results/ */
@property(nonatomic) BOOL excludeDirs;
/* Include files in results/ */
@property(nonatomic) BOOL excludeFiles;
/**
 The path to the dir whose contents to search.
 If nil, the query searches from the home directory.
 */
@property(nonatomic) NSString *path;
/* The extensions to search for. If nil, this finds all files. */
@property(nonatomic) NSSet<NSString *> *extensions;
/**
 The maximum number of files to return. Files closest to the given `path` are prioritized.
 If 0, this returns all matching files. This is discouraged, because this can take a long time.
*/
@property(nonatomic) NSUInteger maxResults;
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

+ (void)makeWindowWithId:(NSString *)windowId;
+ (NSWindow *)windowForId:(NSString *)windowId;
+ (void)closeWindow:(NSString *)windowId;

+ (void)setIndexPath:(NSString *)indexPath ofWindow:(NSString *)windowId;
+ (void)windowDidLoad:(NSString *)windowId;
+ (void)sendMessage:(NSString *)message toWindow:(NSString *)windowId;

/**
 The number of seconds to poll window changes.
 The default value is 0.1, which causes roughly 2% of CPU usage.
 */
+ (CGFloat)windowTrackInterval;
+ (void)setWindowTrackInterval:(CGFloat)interval;

/**
 A class property that allows the delegate to be notified of window changes.
 */
+ (id<SPRSeedDelegate>)delegate;
+ (void)setDelegate:(id<SPRSeedDelegate>)delegate;
+ (void)didReceiveMessage:(NSString *)message fromWindow:(NSString *)windowId;

/**
 Should return a list of contacts in the future. Doesn't work at the moment. TODO: make work.
 */
+ (NSArray<SPRContact *> *)contacts;

/**
 @param query A collections of criteria for the file to meet. See `SPRFileSearchQuery` for details.
 @return A list of files matching the criteria. See `SPRFileSearchQuery` for details.
 */
+ (NSArray<NSString *> *)searchFilesWithQuery:(SPRFileSearchQuery *)query;

+ (NSString*)runAppleScript:(NSString*)string;

@end

NS_ASSUME_NONNULL_END
