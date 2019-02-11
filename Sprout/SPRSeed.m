//
//  SPRSeed.m
//  Sprout
//
//  Created by Thomas Redding on 1/4/19.
//  Copyright © 2019 Thomas Redding. All rights reserved.
//

#import <Carbon/Carbon.h>
#import <Cocoa/Cocoa.h>
#import <Contacts/Contacts.h>

#import "SPRSeed.h"
#import "SPRWebWindow.h"

static NSMutableDictionary<NSString *, SPRWebWindow *> *_windows;

@implementation SPRWindowInfo

- (instancetype)initWithName:(NSString *)name number:(NSNumber *)number processID:(NSNumber *)processID frame:(CGRect)frame {
  self = [super init];
  if (self) {
    self.name = name;
    self.number = number;
    self.processID = processID;
    self.frame = frame;
  }
  return self;
}
- (NSString *)description {
  return [NSString stringWithFormat:@"('%@', %@, %@, [%f, %f, %f, %f])", self.name, self.number, self.processID, self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.frame.size.height];
}
@end

OSStatus callback(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData);

@interface SPRTarget : NSObject
+ (SPRTarget *)fromTarget:(id)target selector:(SEL)selector;
@property id target;
@property SEL selector;
@end

@implementation SPRTarget
+ (SPRTarget *)fromTarget:(id)target selector:(SEL)selector {
  SPRTarget *rtn = [[SPRTarget alloc] init];
  rtn.target = target;
  rtn.selector = selector;
  return rtn;
}
@end

static NSMutableDictionary<NSNumber *, SPRTarget *> *_hotKeyToTarget;

static NSMutableDictionary<NSString *, NSValue *> *_windowNumberToFrame;
static CGFloat _windowTrackInterval = 0.1;
static NSTimer *_windowTrackingTimer;
static id<SPRSeedDelegate> _delegate;

@implementation SPRFileSearchQuery
@end

@implementation SPRSeed

+ (void)initialize {
  if (self == [SPRSeed self]) {
    // Commented out to speed up development.
    [self requestA11y];
    
    // Hotkey Events
    _hotKeyToTarget = [[NSMutableDictionary alloc] init];
    EventTypeSpec eventType;
    eventType.eventClass=kEventClassKeyboard;
    eventType.eventKind=kEventHotKeyPressed;
    InstallApplicationEventHandler(&callback, 1, &eventType, (__bridge void *)self, NULL);
    
    
    // Mouse Events
    NSEventMask buttonMask = NSEventMaskLeftMouseDown | NSEventMaskLeftMouseUp |
        NSEventMaskOtherMouseDown | NSEventMaskOtherMouseUp | NSEventMaskRightMouseDown |
        NSEventMaskRightMouseUp;
    [NSEvent addLocalMonitorForEventsMatchingMask:buttonMask handler:^NSEvent *(NSEvent *event) {
      if ([self.delegate respondsToSelector:@selector(mouseButtonPressed:)]) {
        [self.delegate mouseButtonPressed:event.type];
      }
      return event;
    }];
    [NSEvent addGlobalMonitorForEventsMatchingMask:buttonMask handler:^(NSEvent *event) {
      if ([self.delegate respondsToSelector:@selector(mouseButtonPressed:)]) {
        [self.delegate mouseButtonPressed:event.type];
      }
    }];
    NSEventMask moveMask = NSEventMaskMouseMoved | NSEventMaskLeftMouseDragged | NSEventMaskRightMouseDragged | NSEventMaskOtherMouseDragged;
    [NSEvent addLocalMonitorForEventsMatchingMask:moveMask handler:^NSEvent *(NSEvent *event) {
      if ([self.delegate respondsToSelector:@selector(mouseMove:)]) {
        [self.delegate mouseMove:event.type];
      }
      return event;
    }];
    [NSEvent addGlobalMonitorForEventsMatchingMask:moveMask handler:^(NSEvent *event) {
      if ([self.delegate respondsToSelector:@selector(mouseMove:)]) {
        [self.delegate mouseMove:event.type];
      }
    }];
    
    _windowNumberToFrame = [[NSMutableDictionary alloc] init];
    _windowTrackingTimer = [NSTimer scheduledTimerWithTimeInterval:_windowTrackInterval target:[self class] selector:@selector(tickTock) userInfo:nil repeats:YES];
    _windows = [[NSMutableDictionary alloc] init];
    [self tickTock:NO];
  }
}

#pragma mark - Public

// https://stackoverflow.com/a/6365105
// https://stackoverflow.com/a/4744315
// https://stackoverflow.com/a/17011107
// https://stackoverflow.com/q/6178860
+ (void)setFrame:(CGRect)rect ofWindowWithNumber:(NSNumber *)windowNumber {
  // There's no (known) way to identify a window's a11y refernece from it's windowNumber, so we
  // assume windows are uniquely identified by process and frame.
  CGWindowID windowId = windowNumber.intValue;
  CFArrayRef windowIdArray = CFArrayCreate(NULL, (const void **)(&windowId), 1, NULL);
  CFArrayRef windowArray = CGWindowListCreateDescriptionFromArray(windowIdArray);
  if (CFArrayGetCount(windowArray) != 1) return;
  NSDictionary *windowInfo = CFArrayGetValueAtIndex(windowArray, 0);
  NSDictionary *bounds = [windowInfo objectForKey:@"kCGWindowBounds"];
  CGRect currentFrame = CGRectMake([bounds[@"X"] floatValue], [bounds[@"Y"] floatValue], [bounds[@"Width"] floatValue], [bounds[@"Height"] floatValue]);
  int processId = [[windowInfo objectForKey:@"kCGWindowOwnerPID"] intValue];
  
  // Accessibility
  AXUIElementRef appRef = AXUIElementCreateApplication(processId);
  CFArrayRef appWindows;
  AXUIElementCopyAttributeValues(appRef, kAXWindowsAttribute, 0, 1024, &appWindows);
  if (!appWindows) return;
  CFIndex count = CFArrayGetCount(appWindows);
  for (CFIndex i = 0; i < count; ++i) {
    AXUIElementRef windowRef = (AXUIElementRef)CFArrayGetValueAtIndex(appWindows, 0);
    
    CGPoint windowOrigin = CGPointZero;
    AXValueRef originVal;
    AXUIElementCopyAttributeValue(windowRef, kAXPositionAttribute, (CFTypeRef*)&originVal);
    AXValueGetValue(originVal, kAXValueCGPointType, &windowOrigin);
    
    CGSize windowSize = CGSizeZero;
    AXValueRef sizeValue;
    AXUIElementCopyAttributeValue(windowRef, kAXSizeAttribute, (CFTypeRef*)&sizeValue);
    AXValueGetValue(sizeValue, kAXValueCGSizeType, &windowSize);
    
    if (!CGSizeEqualToSize(currentFrame.size, windowSize)) continue;
    if (fabs(currentFrame.origin.x - windowOrigin.x) + fabs(currentFrame.origin.y - windowOrigin.y) > 10) continue;
    
    // Since this window has the same process ID, size, and (roughly) position, its probably the one we want.
    AXValueRef positionRef = AXValueCreate(kAXValueCGPointType, &rect.origin);
    AXValueRef sizeRef = AXValueCreate(kAXValueCGSizeType, &rect.size);
    AXUIElementSetAttributeValue(windowRef, kAXPositionAttribute, positionRef);
    AXUIElementSetAttributeValue(windowRef, kAXSizeAttribute, sizeRef);
    break;
  }
}

+ (BOOL)registerHotKeyFromKeyCode:(UInt32)keyCode
                          keyFlag:(SPRKeyFlag)keyFlag
                         toTarget:(id)target
                      andSelector:(SEL)selector {
  if (keyFlag == 0 || keyFlag > 15 || keyFlag == SPRKeyFlagShift) return NO;
  EventHotKeyRef myHotKeyEventRef;
  UInt32 keyModifiers = 0;
  if (keyFlag & SPRKeyFlagCommand) keyModifiers += cmdKey;
  if (keyFlag & SPRKeyFlagOption) keyModifiers += optionKey;
  if (keyFlag & SPRKeyFlagControl) keyModifiers += controlKey;
  if (keyFlag & SPRKeyFlagShift) keyModifiers += shiftKey;
  UInt32 hotKeyId = keyCode + ((UInt32)keyFlag) * 1048576; // 2^20
  if (_hotKeyToTarget[[NSNumber numberWithUnsignedInteger:hotKeyId]]) return NO;
  EventHotKeyID myHotKeyID;
  myHotKeyID.signature = 'SPR0';
  myHotKeyID.id = hotKeyId;
  RegisterEventHotKey(keyCode, keyModifiers, myHotKeyID, GetApplicationEventTarget(), 0, &myHotKeyEventRef);
  _hotKeyToTarget[[NSNumber numberWithUnsignedInteger:hotKeyId]] = [SPRTarget fromTarget:target selector:selector];
  return YES;
}

+ (void)registerMouseEvent:(SPRMouseEvent)mouseEventFlag toTarget:(id)target
                                                      andSelector:(SEL)selector {
  NSEventMask eventMask;
  switch (mouseEventFlag) {
    case SPRMouseEventLeftMouseDown:
      eventMask = NSEventMaskLeftMouseDown;
      break;
    case SPRMouseEventLeftMouseUp:
      eventMask = NSEventMaskLeftMouseUp;
      break;
    case SPRMouseEventRightMouseDown:
      eventMask = NSEventMaskRightMouseDown;
      break;
    case SPRMouseEventRightMouseUp:
      eventMask = NSEventMaskRightMouseUp;
      break;
    case SPRMouseEventMouseMoved:
      eventMask = NSEventMaskMouseMoved;
      break;
    case SPRMouseEventLeftMouseDragged:
      eventMask = NSEventMaskLeftMouseDragged;
      break;
    case SPRMouseEventRightMouseDragged:
      eventMask = NSEventMaskRightMouseDragged;
      break;
    case SPRMouseEventMouseEntered:
      eventMask = NSEventMaskMouseEntered;
      break;
    case SPRMouseEventMouseExited:
      eventMask = NSEventMaskMouseExited;
      break;
    case SPRMouseEventOtherMouseDown:
      eventMask = NSEventMaskOtherMouseDown;
      break;
    case SPRMouseEventOtherMouseUp:
      eventMask = NSEventMaskOtherMouseUp;
      break;
    case SPRMouseEventOtherMouseDragged:
      eventMask = NSEventMaskOtherMouseDragged;
      break;
    default:
      NSLog(@"ERROR: Should Never Happen.");
      return;
  }
  [NSEvent addLocalMonitorForEventsMatchingMask:eventMask
                                        handler:^NSEvent * _Nullable(NSEvent * _Nonnull event) {
                                          [target performSelector:selector];
                                          return event;
                                        }];
  [NSEvent addGlobalMonitorForEventsMatchingMask:eventMask
                                         handler:^(NSEvent * _Nonnull event) {
                                           [target performSelector:selector];
                                         }];
}

+ (void)makeWindowWithId:(NSString *)windowId {
  if ([_windows objectForKey:windowId]) return;
  _windows[windowId] = [[SPRWebWindow alloc] initWithId:windowId];
  _windows[windowId].webWindowDelegate = self;
}

+ (SPRWebWindow *)windowForId:(NSString *)windowId {
  return [_windows objectForKey:windowId];
}

+ (void)closeWindow:(NSString *)windowId {
  if (![_windows objectForKey:windowId]) return;
  [_windows[windowId] close];
  [_windows removeObjectForKey:windowId];
}

+ (void)setIndexPath:(NSString *)indexPath ofWindow:(NSString *)windowId {
  if (![_windows objectForKey:windowId]) return;
  [_windows[windowId] setIndexPath:indexPath];
}

+ (void)sendMessage:(NSString *)message toWindow:(NSString *)windowId {
  if (![_windows objectForKey:windowId]) return;
  [_windows[windowId] sendMessage:message];
}

+ (void)webWindowDidLoad:(NSString *)windowId {
  [_delegate webWindowDidLoad:windowId];
}

# pragma mark - Private

+ (void)didReceiveMessage:(NSString *)message fromWindow:(NSString *)windowId {
  [_delegate didReceiveMessage:message fromWindow:windowId];
}

+ (void)sendWindow:(NSString *)windowId message:(NSString *)message {
  [_windows[windowId] sendMessage:message];
}

#pragma mark - Hotkeys - Private

+ (void)callCallbackForHotKeyId:(UInt32)hotKeyId {
  UInt32 keyCode = hotKeyId % 1048576;
  UInt32 flagInt = hotKeyId / 1048576;
  if (flagInt == 0 || flagInt > 15 || flagInt == SPRKeyFlagShift) return;
  SPRTarget *target = _hotKeyToTarget[[NSNumber numberWithInt:hotKeyId]];
  [target.target performSelector:target.selector
                      withObject:[NSNumber numberWithUnsignedInteger:keyCode]
                      withObject:[NSNumber numberWithUnsignedInteger:flagInt]];
}

OSStatus callback(EventHandlerCallRef nextHandler, EventRef event,void *userData) {
  EventHotKeyID hkCom;
  GetEventParameter(event, kEventParamDirectObject, typeEventHotKeyID, NULL, sizeof(hkCom), NULL, &hkCom);
  [SPRSeed callCallbackForHotKeyId:hkCom.id];
  return noErr;
}

#pragma mark - Window Tracking - Public

+ (CGFloat)windowTrackInterval {
  return _windowTrackInterval;
}

+ (void)setWindowTrackInterval:(CGFloat)interval {
  _windowTrackInterval = interval;
  [_windowTrackingTimer invalidate];
  _windowTrackingTimer = nil;
  if (_windowTrackInterval > 0) {
      _windowTrackingTimer = [NSTimer scheduledTimerWithTimeInterval:_windowTrackInterval
                                                              target:[self class]
                                                            selector:@selector(tickTock)
                                                            userInfo:nil
                                                             repeats:YES];
  }
}

+ (id<SPRSeedDelegate>)delegate {
  return _delegate;
}

+ (void)setDelegate:(id<SPRSeedDelegate>)delegate {
  _delegate = delegate;
}

#pragma mark - Window Tracking - Private

+ (void)tickTock {
  [self tickTock:YES];
}

+ (void)tickTock:(BOOL)alertDelegate {
  // Check for moving windows.
  NSArray<NSDictionary *> *windows = (__bridge NSArray*)CGWindowListCopyWindowInfo(kCGWindowListOptionAll, kCGNullWindowID);
  NSMutableSet<NSString *> *newWindowNumbers = [[NSMutableSet alloc] init];
  NSMutableDictionary<NSString *, NSDictionary *> *movedWindows = [[NSMutableDictionary alloc] init];
  for (NSDictionary *window in windows) {
    // `window` contains various information other than the two accessed here. All the keys begin
    // with "kCGWindow". Examples include Alpha, IsOnscreen, Layer, MemoryUsage, Number, OwnerName,
    // OwnerPID, SharingState, StoreType, and Name
    
    // Visible above screensaver, so skip.
    // https://gist.github.com/matthewreagan/2f3a30b8b229e9e2aa7c
    if ([window[@"kCGWindowLayer"] integerValue] > 1000) continue;
    
    NSString *windowNumber = [NSString stringWithFormat:@"%@", (NSNumber *)window[@"kCGWindowNumber"]];
    [newWindowNumbers addObject:windowNumber];
    NSDictionary *bounds = window[@"kCGWindowBounds"];
    CGRect newRect = CGRectMake([bounds[@"X"] floatValue], [bounds[@"Y"] floatValue], [bounds[@"Width"] floatValue], [bounds[@"Height"] floatValue]);
    if (_windowNumberToFrame[windowNumber]) {
      // The window already exists.
      CGRect oldRect = [_windowNumberToFrame[windowNumber] rectValue];
      if (CGRectEqualToRect(oldRect, newRect)) continue;
      [_windowNumberToFrame setObject:[NSValue valueWithRect:newRect] forKey:windowNumber];
      [movedWindows setObject:window forKey:windowNumber];
    } else {
      // A new window has been added.
      [_windowNumberToFrame setObject:[NSValue valueWithRect:newRect] forKey:windowNumber];
      if (alertDelegate && _delegate) {
        [_delegate performSelector:@selector(windowAdded:)
                                    withObject:[self windowInfoFromDict:window]];
      }
    }
  }
  
  if (alertDelegate && _delegate) {
    NSMutableSet<NSNumber *> *processesWithMovedWindows = [[NSMutableSet alloc] init];
    for (NSString *w in movedWindows) {
      [processesWithMovedWindows addObject:movedWindows[w][@"kCGWindowOwnerPID"]];
    }
    // If zero processes have moving windows, nothing is happening.
    // If more than one process has moving windows, we're probably changing workspaces.
    if (processesWithMovedWindows.count == 1) {
      NSDictionary *windowDict = movedWindows[movedWindows.allKeys.firstObject];
      [_delegate performSelector:@selector(windowMoved:) withObject:[self windowInfoFromDict:windowDict]];
    }
  }
  
  // Remove windows that no longer exist.
  NSMutableSet<NSString *> *windowsToRemove = [[NSMutableSet alloc] init];
  for (NSString *windowNumber in _windowNumberToFrame) {
    if (![newWindowNumbers containsObject:windowNumber]) {
      [windowsToRemove addObject:windowNumber];
    }
  }
  for (NSString *windowNumber in windowsToRemove) {
    [_windowNumberToFrame removeObjectForKey:windowNumber];
    if (alertDelegate && _delegate) {
      [_delegate performSelector:@selector(windowRemoved)];
    }
  }
}

+ (SPRWindowInfo *)windowInfoFromDict:(NSDictionary *)dict {
  NSDictionary *bounds = dict[@"kCGWindowBounds"];
  CGRect rect = CGRectMake([bounds[@"X"] floatValue], [bounds[@"Y"] floatValue], [bounds[@"Width"] floatValue], [bounds[@"Height"] floatValue]);
  return [[SPRWindowInfo alloc] initWithName:(NSString *)dict[@"kCGWindowName"]
                                      number:(NSNumber *)dict[@"kCGWindowNumber"]
                                   processID:(NSNumber *)dict[@"kCGWindowOwnerPID"]
                                       frame:rect];
  
}

#pragma mark - Contacts - Public

+ (NSArray<SPRContact *> *)contacts {
  NSPredicate *pred = [CNContact predicateForContactsMatchingName:@"Morgan"];
  CNContactStore *store = [[CNContactStore alloc] init];
  NSArray *keys = @[CNContactGivenNameKey, CNContactFamilyNameKey];
  NSError *error;
  NSArray<CNContact *> *containers = [store unifiedContactsMatchingPredicate:pred keysToFetch:keys error:&error];
  if ([error.domain isEqualToString:CNErrorDomain] && error.code == 100) {
    // The user denied us permission to access contacts.
    return nil;
  }
  // TODO: Make this work.
  NSLog(@"TR: %@", error);
  NSLog(@"TR: %@", containers);
  return nil;
}

#pragma mark - Files - Public

+ (NSArray<NSString *> *)searchFilesWithQuery:(SPRFileSearchQuery *)query {
  if (query.maxResults == 0) query.maxResults = NSUIntegerMax;
  if (!query.path) query.path = NSHomeDirectory();
  if ([query.path characterAtIndex:0] == '~') {
    query.path = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), [query.path substringFromIndex:1]];
  }
  NSFileManager *manager = NSFileManager.defaultManager;
  NSMutableArray<NSString *> *rtn = [[NSMutableArray alloc] init];
  NSMutableArray<NSString *> *queue = [[NSMutableArray alloc] initWithObjects:query.path, nil];
  for (NSUInteger queueIndex = 0; queueIndex < queue.count; ++queueIndex) {
    NSString *dirPath = queue[queueIndex];
    NSArray<NSString *> *contents = [manager contentsOfDirectoryAtPath:dirPath error:nil];
    for (NSString *p in contents) {
      NSString *pa = [NSString stringWithFormat:@"%@/%@", dirPath, p];
      BOOL isDir;
      [manager fileExistsAtPath:pa isDirectory:&isDir];
      if (isDir) {
        if (!query.searchHidden) {
          NSNumber *isHidden;
          [[NSURL fileURLWithPath:pa] getResourceValue:&isHidden
                                                forKey:NSURLIsHiddenKey
                                                 error:nil];
          if (isHidden.intValue) continue;
        }
        if (query.descendSubdirs) [queue addObject:pa];
        if (!query.excludeDirs) [rtn addObject:pa];
      } else {
        if (query.extensions && ![query.extensions containsObject:pa.pathExtension]) continue;
        if (!query.searchHidden) {
          NSNumber *isHidden;
          [[NSURL fileURLWithPath:pa] getResourceValue:&isHidden
                                                forKey:NSURLIsHiddenKey
                                                 error:nil];
          if (isHidden.intValue) continue;
        }
        if (!query.excludeFiles) [rtn addObject:pa];
        if (rtn.count >= query.maxResults) return rtn;
      }
    }
  }
  return rtn;
}

#pragma mark - Run Scripts - Public

+ (NSString*)runAppleScript:(NSString*)string {
  NSAppleScript *script = [[NSAppleScript alloc] initWithSource:string];
  NSDictionary *scriptExecuteError;
  NSAppleEventDescriptor *result = [script executeAndReturnError:&scriptExecuteError];
  if(scriptExecuteError) {
    return @""; // Failed
  } else {
    return result.stringValue;
  }
}

# pragma mark - SPRWebWindowDelegate

+ (void)webWindowDidBecomeMain:(NSString *)windowId {
  [self.delegate webWindowDidBecomeMain:windowId];
}

+ (void)webWindowDidResignMain:(NSString *)windowId {
  [self.delegate webWindowDidResignMain:windowId];
}

# pragma mark - Private

/*
 * @return Whether the app has a11y permission.
 */
+ (BOOL)a11yEnabled {
  NSDictionary *options = @{(__bridge id) kAXTrustedCheckOptionPrompt : @NO};
  BOOL accessibilityEnabled = AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef) options);
  return accessibilityEnabled;
}

/*
 * If, the app has a11y permission, return true. Otherwise, return false and asynchronously shows a
 * dialog requesting a11y permission.
 */
+ (BOOL)requestA11y {
  NSDictionary *options = @{(__bridge id) kAXTrustedCheckOptionPrompt : @YES};
  BOOL accessibilityEnabled = AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef) options);
  return accessibilityEnabled;
  return NO;
}

@end
