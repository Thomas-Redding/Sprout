#import "SPRMainSprout.h"

#include <time.h>
#include <stdlib.h>

#import "FileQuery.h"
#import "SPRWebWindow.h"

static const CGFloat kMinTimeBetweenMouseEvents = 1.0/20;

@implementation SPRMainSprout {
  BOOL shouldLogAllPipes;
  NSTask *_task;
  NSPipe *_inPipe;
  NSPipe *_outPipe;
  NSInteger _DoNotUseMe_UniqueId;
  NSMutableDictionary<NSString *, NSTimer *> *_idToTimer;
  NSMutableDictionary<NSString *, NSRunningApplication *> *windowToOriginallyFocusedApp;
  NSMutableSet<NSString *> *_mouseMoveEventQueue;
  NSMutableString *messageSoFar;
};

# pragma mark - Public

- (void)launch {
  // shouldLogAllPipes = YES;
  _DoNotUseMe_UniqueId = 0;
  _mouseMoveEventQueue = [[NSMutableSet alloc] init];
  NSString *pathToSproutMain = [NSBundle.mainBundle pathForResource:@"SproutObjcInterface" ofType:@"py"];
  windowToOriginallyFocusedApp = [[NSMutableDictionary alloc] init];
  _idToTimer = [[NSMutableDictionary alloc] init];
  _task = [[NSTask alloc] init];
  _task.launchPath = @"/usr/local/bin/python";
  _task.arguments = @[ pathToSproutMain ];
  _inPipe = [[NSPipe alloc] init];
  _outPipe = [[NSPipe alloc] init];
  _task.standardInput = _inPipe;
  _task.standardOutput = _outPipe;
  SPRSeed.delegate = self;
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(sproutMainTerminated)
                                               name:NSTaskDidTerminateNotification
                                             object:_task];
  [self makeLaunchOnLogin];
  [NSNotificationCenter.defaultCenter
      addObserver:self
         selector:@selector(pythonSentMessage)
             name:NSFileHandleDataAvailableNotification
           object:_outPipe.fileHandleForReading];
  [NSTimer scheduledTimerWithTimeInterval:kMinTimeBetweenMouseEvents
                                  repeats:YES
                                    block:^(NSTimer *timer) {
    NSSet<NSString *> *events = [self->_mouseMoveEventQueue copy];
    [self->_mouseMoveEventQueue removeAllObjects];
    for (NSString *eventString in events) {
      [self sendToPython:eventString withUniqueId:[self generateUniqueId]];
    }
  }];
  [_outPipe.fileHandleForReading waitForDataInBackgroundAndNotify];
  [_task launch];
}

- (void)terminate {
  [_task terminate];
}

# pragma mark - SPRSeedDelegate

- (void)windowAdded:(SPRWindowInfo *)windowInfo {
  // TODO: Use this event.
}
- (void)windowMoved:(SPRWindowInfo *)windowInfo {
  NSRunningApplication *app =
      [NSRunningApplication runningApplicationWithProcessIdentifier:windowInfo.processID.intValue];
  if (!app) return;
  NSString *message = [NSString stringWithFormat:@"liteWindow.windowMoved\t%@\t%@\t%@", windowInfo.number,
                       app.bundleIdentifier, app.localizedName];
  [self sendToPython:message withUniqueId:[self generateUniqueId]];
}
- (void)windowRemoved {
  // TODO: Use this event.
}

- (void)didReceiveMessage:(NSString *)message fromWindow:(NSString *)windowId {
  [self sendToPython:[NSString stringWithFormat:@"window.request\t%@\t%@", windowId, message] withUniqueId:[self generateUniqueId]];
}

- (void)mouseButtonPressed:(NSEventType)eventType {
  switch (eventType) {
    case NSEventTypeLeftMouseDown:
      [self sendToPython:@"mouseButton\t1\tdown" withUniqueId:[self generateUniqueId]];
      break;
    case NSEventTypeLeftMouseUp:
      [self sendToPython:@"mouseButton\t1\tup" withUniqueId:[self generateUniqueId]];
      break;
    case NSEventTypeRightMouseDown:
      [self sendToPython:@"mouseButton\t2\tdown" withUniqueId:[self generateUniqueId]];
      break;
    case NSEventTypeRightMouseUp:
      [self sendToPython:@"mouseButton\t2\tup" withUniqueId:[self generateUniqueId]];
      break;
    case NSEventTypeOtherMouseDown:
      [self sendToPython:@"mouseButton\t3\tdown" withUniqueId:[self generateUniqueId]];
      break;
    case NSEventTypeOtherMouseUp:
      [self sendToPython:@"mouseButton\t3\tup" withUniqueId:[self generateUniqueId]];
      break;
    default:
      [self assert:NO message:@"Unknown eventType in mouseButtonPressed:"];
  }
}

- (void)mouseMove:(NSEventType)eventType {
  // Note: left mouse button takes precedence over right.
  /*
  switch (eventType) {
    case NSEventTypeMouseMoved:
      [_mouseMoveEventQueue addObject:@"mouseMove\t0"];
      break;
    case NSEventTypeLeftMouseDragged:
      [_mouseMoveEventQueue addObject:@"mouseMove\t1"];
      break;
    case NSEventTypeRightMouseDragged:
      [_mouseMoveEventQueue addObject:@"mouseMove\t2"];
      break;
    case NSEventTypeOtherMouseDragged:
      [_mouseMoveEventQueue addObject:@"mouseMove\t3"];
      break;
    default:
      [self assert:NO message:@"Unknown eventType in mouseMove:"];
      break;
  }*/
}

- (void)webWindowDidLoad:(NSString *)windowId {
  // TODO: Use this event.
  [self sendToPython:[NSString stringWithFormat:@"window.didLoad\t%@", windowId] withUniqueId:[self generateUniqueId]];
}

- (void)webWindowDidBecomeMain:(NSString *)windowId {
  [self sendToPython:[NSString stringWithFormat:@"window.didBecomeMain\t%@", windowId] withUniqueId:[self generateUniqueId]];
}

- (void)webWindowDidResignMain:(NSString *)windowId {
  [self sendToPython:[NSString stringWithFormat:@"window.didResignMain\t%@", windowId] withUniqueId:[self generateUniqueId]];
}

# pragma mark - I/O

- (void)sendToPython:(NSString *)string withUniqueId:(NSString *)uniqueId {
  string = [self stringByEscapingNewlines:string];
  NSString *flushString = [NSString stringWithFormat:@"%@\t%@\n", uniqueId, string];
  if (shouldLogAllPipes) NSLog(@"  TO PYTHON:%lu:%@", flushString.length, [flushString substringToIndex:MIN(flushString.length, 200)]);
  NSData *data = [flushString dataUsingEncoding:NSUTF8StringEncoding];
  [_inPipe.fileHandleForWriting writeData:data];
}

- (void)pythonSentMessage {
  NSData *data = _outPipe.fileHandleForReading.availableData;
  NSString *outStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  [_outPipe.fileHandleForReading waitForDataInBackgroundAndNotify];
  NSArray<NSString *> *lines = [outStr componentsSeparatedByString:@"\n"];
  for (NSString *line in lines) {
    if (line.length == 0) {
      if (messageSoFar) {
        [self handleMessageFromPython:messageSoFar];
        messageSoFar = nil;
      }
    } else {
      if (!messageSoFar) messageSoFar = [[NSMutableString alloc] init];
      [messageSoFar appendString:[self stringByUnescapingNewlines:line]];
    }
  }
}

# pragma mark - Private

- (NSString *)stringByEscapingNewlines:(NSString *)s {
  return [[s stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"] stringByReplacingOccurrencesOfString:@"\n" withString:@"\\\n"];
}

- (NSString *)stringByUnescapingNewlines:(NSString *)str {
  //a
  NSMutableString *rtn = [[NSMutableString alloc] init];
  NSUInteger len = [str length];
  unichar buffer[len+1];
  [str getCharacters:buffer range:NSMakeRange(0, len)];
  BOOL justConsume = YES;
  for(int i = 0; i < len; i++) {
    unichar c = buffer[i];
    if (justConsume) {
      if (c == '\\') {
        justConsume = NO;
      } else {
        [rtn appendFormat:@"%C", c];
      }
    } else {
      if (c == '\\') {
        [rtn appendString:@"\\"];
        justConsume = YES;
      } else if (c == 'n') {
        [rtn appendString:@"\n"];
        justConsume = YES;
      } else {
        NSException* myException =
            [NSException exceptionWithName:@"Error in |stringByUnescapingNewlines:|"
                                    reason:@"Improper backslashes"
                                  userInfo:nil];
        @throw myException;
      }
    }
  }
  return rtn;
}

- (NSString *)generateUniqueId {
  ++_DoNotUseMe_UniqueId;
  return [NSString stringWithFormat:@"x%lu", _DoNotUseMe_UniqueId];
}

- (void)handleMessageFromPython:(NSString *)line {
  if (shouldLogAllPipes) NSLog(@"FROM PYTHON:%lu:%@", line.length, [line substringToIndex:MIN(line.length, 200)]);
  NSString *uniqueId = [self firstWordInString:line];
  NSString *command = [line substringFromIndex:uniqueId.length + 1];
  NSString *commandType = [self firstWordInString:command];
  if ([commandType isEqualToString:@"print"]) {
    NSString *q = [command substringFromIndex:commandType.length + 1];
    NSLog(@"Python Print: '%@'", [self stringByUnescaping:q]);
  } else if ([commandType isEqualToString:@"quitSprout"]) {
    [self terminate];
  } else if ([commandType isEqualToString:@"runAppleScript"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:1];
    NSString *script = args[0];
    NSString *result = [self _runAppleScript:script];
    [self sendToPython:[NSString stringWithFormat:@"runAppleScript\t%@", result]
          withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"registerHotKey"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:2];
    NSUInteger keyCode = [args[0] integerValue];
    NSString *flags = args[1];
    SPRKeyFlag keyFlag = 0;
    if ([flags characterAtIndex:0] != '0') keyFlag |= SPRKeyFlagCommand;
    if ([flags characterAtIndex:1] != '0') keyFlag |= SPRKeyFlagOption;
    if ([flags characterAtIndex:2] != '0') keyFlag |= SPRKeyFlagControl;
    if ([flags characterAtIndex:3] != '0') keyFlag |= SPRKeyFlagShift;
    [SPRSeed registerHotKeyFromKeyCode:(UInt32)keyCode
                               keyFlag:keyFlag
                              toTarget:self
                           andSelector:@selector(hotkeyPressed:withFlags:)];
    [self sendToPython:command withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"runningApps"]) {
    NSArray<NSRunningApplication *> *apps = NSWorkspace.sharedWorkspace.runningApplications;
    NSMutableString *response = [NSMutableString stringWithString:@"runningApps\t"];
    for (NSRunningApplication *app in apps) {
      if (!app.bundleIdentifier) continue;
      [response appendString:@"/"];
      [response appendString:app.bundleIdentifier];
      [response appendString:@" "];
      [response appendString:app.localizedName];
    }
    [self sendToPython:response withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"quitApp"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:1];
    NSString *bundleIdentifier = args[0];
    NSArray<NSRunningApplication *> *apps = NSWorkspace.sharedWorkspace.runningApplications;
    for (NSRunningApplication *app in apps) {
      if ([app.bundleIdentifier isEqualToString:bundleIdentifier]) {
        [app terminate];
        break;
      }
    }
  } else if ([commandType isEqualToString:@"forceQuitApp"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:1];
    NSString *bundleIdentifier = args[0];
    NSArray<NSRunningApplication *> *apps = NSWorkspace.sharedWorkspace.runningApplications;
    for (NSRunningApplication *app in apps) {
      if ([app.bundleIdentifier isEqualToString:bundleIdentifier]) {
        [app forceTerminate];
        break;
      }
    }
  } else if ([commandType isEqualToString:@"power.sleepScreen"]) {
    [self _runAppleScript:@"tell application \"Finder\" to sleep"];
    [self sendToPython:command withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"power.shutDown"]) {
    [self _runAppleScript:@"tell application \"Finder\" to shut down"];
    [self sendToPython:command withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"power.restart"]) {
    [self _runAppleScript:@"tell application \"Finder\" to restart"];
    [self sendToPython:command withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"power.logOut"]) {
    [self _runAppleScript:@"tell application \"Finder\" to log out"];
    [self sendToPython:command withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"mousePosition"]) {
    NSPoint pos = [NSEvent mouseLocation];
    [self sendToPython:[NSString stringWithFormat:@"mousePosition\t%f\t%f", pos.x, pos.y] withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"doLater"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:1];
    float waitTime = [args[0] floatValue];
    [self performSelector:@selector(timerCallbackWithUniqueId:) withObject:uniqueId afterDelay:waitTime];
  } else if ([commandType isEqualToString:@"repeat"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:2];
    NSString *timerId = args[0];
    float waitTime = [args[1] floatValue];
    NSTimer *timer = [NSTimer timerWithTimeInterval:waitTime repeats:TRUE block:^(NSTimer *timer) {
      [self sendToPython:@"repeat" withUniqueId:uniqueId];
    }];
    [_idToTimer setObject:timer forKey:timerId];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
  } else if ([commandType isEqualToString:@"stopRepeat"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:1];
    NSString *timerId = args[0];
    NSTimer *timer = [_idToTimer objectForKey:timerId];
    [timer invalidate];
    [self sendToPython:command withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"getFrontmostWindowFrame"]) {
    CGRect frame = [SPRSeed getFrontmostWindowFrame];
    NSString *message = [NSString stringWithFormat:@"getFrontmostWindowFrame\t%f\t%f\t%f\t%f", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height];
    [self sendToPython:message withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"setFrontmostWindowFrame"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:4];
    CGFloat x = [args[0] floatValue];
    CGFloat y = [args[1] floatValue];
    CGFloat w = [args[2] floatValue];
    CGFloat h = [args[3] floatValue];
    [SPRSeed setFrontmostWindowFrame:CGRectMake(x, y, w, h)];
    [self sendToPython:command withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"define"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:1];
    NSString *word = args[0];
    NSArray<NSArray<NSString *> *> *arr = [SPRSeed dictionaryEntryForWord:word];
    if (arr.count == 0) {
      [self sendToPython:@"" withUniqueId:uniqueId];
    } else {
      NSMutableString *message = [[NSMutableString alloc] initWithString:@"define"];
      for (int i = 0; i < arr.count; ++i) {
        [message appendString:@"\t"];
        [message appendString:[arr[i][0] stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"]];
        [message appendString:@"\t"];
        [message appendString:[arr[i][1] stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"]];
      }
      [self sendToPython:message withUniqueId:uniqueId];
    }
  } else if ([commandType isEqualToString:@"liteWindow.moveWindow"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:5];
    NSString *windowNumber = args[0];
    CGFloat x = [args[1] floatValue];
    CGFloat y = [args[2] floatValue];
    CGFloat w = [args[3] floatValue];
    CGFloat h = [args[4] floatValue];
    [SPRSeed setFrame:CGRectMake(x, y, w, h)
        ofWindowWithNumber:[NSNumber numberWithUnsignedLongLong:[windowNumber integerValue]]];
    [self sendToPython:command withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"frontmostApp"]) {
    NSRunningApplication *app = [NSWorkspace.sharedWorkspace frontmostApplication];
    NSMutableString *response = [NSMutableString stringWithString:@"frontmostApp\t"];
    [response appendString:app.bundleIdentifier];
    [response appendString:@"\t"];
    [response appendString:app.localizedName];
    [self sendToPython:response withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"getFrontmostWindowFrame"]) {
    CGRect rect = [SPRSeed getFrontmostWindowFrame];
    NSString *response = [NSString stringWithFormat:@"getFrontmostWindowFrame\t%f\t%f\t%f\t%f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height];
    [self sendToPython:response withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"setFrontmostWindowFrame"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:4];
    CGFloat x = [args[0] floatValue];
    CGFloat y = [args[1] floatValue];
    CGFloat w = [args[2] floatValue];
    CGFloat h = [args[3] floatValue];
    [SPRSeed setFrontmostWindowFrame:CGRectMake(x, y, w, h)];
    [self sendToPython:command withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"screenFrames"]){
    NSMutableString *response = [[NSMutableString alloc] initWithString:@"screenFrames"];
    for (NSScreen *screen in NSScreen.screens) {
      [response appendFormat:@"\t%f %f %f %f", screen.frame.origin.x, screen.frame.origin.y, screen.frame.size.width, screen.frame.size.height];
    }
    [self sendToPython:response withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"setClipboard"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:1];
    [NSPasteboard.generalPasteboard clearContents];
    [NSPasteboard.generalPasteboard writeObjects:@[args[0]]];
    [self sendToPython:command withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"getClipboard"]) {
    NSString *str = [NSPasteboard.generalPasteboard stringForType:NSPasteboardTypeString];
    [self sendToPython:[NSString stringWithFormat:@"getClipboard\t%@", str] withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"searchFiles"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:4];
    NSArray<NSString *> *sortStrings = [args[2] componentsSeparatedByString:@":"];
    NSMutableArray<NSSortDescriptor *> *sortDescriptors = [[NSMutableArray alloc] init];
    for (NSString *sortString in sortStrings) {
      NSString *key = [sortString substringFromIndex:1];
      BOOL isAscending = ([sortString characterAtIndex:0] != '0');
      [sortDescriptors addObject:[NSSortDescriptor sortDescriptorWithKey:key ascending:isAscending]];
    }
    NSInteger maxResults = [args[3] integerValue];
    [FileQuery findFilesMatchingFilter:args[0]
                              inScopes:[args[1] componentsSeparatedByString:@":"]
                                sortBy:sortDescriptors
                            maxResults:maxResults
                                string:uniqueId
                                target:self
                              callback:@selector(fileSearchFinishedWithResults:uniqueId:)];
/********** Window Commands **********/
  } else if ([commandType isEqualToString:@"makeWindow"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:1];
    NSString *windowId = args[0];
    [SPRSeed makeWindowWithId:windowId];
    [self sendToPython:[NSString stringWithFormat:@"makeWindow\t%@", windowId] withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"window.getFrame"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:1];
    NSString *windowId = args[0];
    CGRect frame = [SPRSeed windowForId:windowId].frame;
    NSString *response = [NSString stringWithFormat:@"window.getFrame\t%@\t%f\t%f\t%f\t%f", windowId, frame.origin.x, frame.origin.y, frame.size.width, frame.size.height];
    [self sendToPython:response withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"window.setFrame"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:5];
    NSString *windowId = args[0];
    CGFloat x = [args[1] floatValue];
    CGFloat y = [args[2] floatValue];
    CGFloat w = [args[3] floatValue];
    CGFloat h = [args[4] floatValue];
    [[SPRSeed windowForId:windowId] setFrame:CGRectMake(x, y, w, h) display:YES];
    [self sendToPython:command withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"window.close"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:1];
    NSString *windowId = args[0];
    [SPRSeed closeWindow:windowId];
    [self sendToPython:command withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"window.getVisible"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:1];
    NSString *windowId = args[0];
    BOOL visible = [[SPRSeed windowForId:windowId] isVisible];
    NSString *response = [NSString stringWithFormat:@"window.getVisible\t%@\t%d", windowId, visible];
    [self sendToPython:response withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"window.setVisible"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:2];
    NSString *windowId = args[0];
    bool newVisible = [args[1] integerValue];
    [[SPRSeed windowForId:windowId] setIsVisible:newVisible];
    [self sendToPython:command withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"window.getTitle"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:1];
    NSString *windowId = args[0];
    NSWindowTitleVisibility titleVisibility = [[SPRSeed windowForId:windowId] titleVisibility];
    BOOL isTitleVisible = (titleVisibility == NSWindowTitleVisible);
    NSString *title = [[SPRSeed windowForId:windowId] title];
    NSString *response = [NSString stringWithFormat:@"window.getTitle\t%@\t%d\t%@", windowId, isTitleVisible, title];
    [self sendToPython:response withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"window.setTitle"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:3];
    NSString *windowId = args[0];
    BOOL titleVisible = (BOOL)[args[1] intValue];
    NSWindowTitleVisibility visibility = titleVisible ? NSWindowTitleVisible : NSWindowTitleHidden;
    NSString *newTitle = args[2];
    [[SPRSeed windowForId:windowId] setTitle:newTitle];
    [[SPRSeed windowForId:windowId] setTitleVisibility:visibility];
    [[SPRSeed windowForId:windowId] setTitlebarAppearsTransparent:!titleVisible];
    [self sendToPython:command withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"window.getAlpha"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:1];
    NSString *windowId = args[0];
    CGFloat alpha = [[SPRSeed windowForId:windowId] alphaValue];
    NSString *response = [NSString stringWithFormat:@"window.getAlpha\t%@\t%f", windowId, alpha];
    [self sendToPython:response withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"window.setAlpha"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:2];
    NSString *windowId = args[0];
    float newAlpha = [args[1] floatValue];
    [[SPRSeed windowForId:windowId] setAlphaValue:newAlpha];
    [self sendToPython:command withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"window.getDraggable"]) {
  } else if ([commandType isEqualToString:@"window.setDraggable"]) {
  } else if ([commandType isEqualToString:@"window.getMovable"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:1];
    NSString *windowId = args[0];
    BOOL isMovable = [[SPRSeed windowForId:windowId] isMovable];
    NSString *response = [NSString stringWithFormat:@"window.getMovable\t%@\t%d", windowId, isMovable];
    [self sendToPython:response withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"window.setMovable"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:2];
    NSString *windowId = args[0];
    BOOL isMovable = ![args[1] isEqualToString:@"0"];
    [[SPRSeed windowForId:windowId] setMovable:isMovable];
    NSString *response = [NSString stringWithFormat:@"window.setMovable\t%@\t%d", windowId, isMovable];
    [self sendToPython:response withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"window.getInDesktop"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:1];
    NSString *windowId = args[0];
    BOOL inDesktop = [[SPRSeed windowForId:windowId] inDesktop];
    NSString *response = [NSString stringWithFormat:@"window.getInDesktop\t%@\t%d", windowId, inDesktop];
    [self sendToPython:response withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"window.setInDesktop"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:2];
    NSString *windowId = args[0];
    BOOL inDesktop = ![args[1] isEqualToString:@"0"];
    [[SPRSeed windowForId:windowId] setInDesktop:inDesktop];
    NSString *response = [NSString stringWithFormat:@"window.setInDesktop\t%@\t%d", windowId, inDesktop];
    [self sendToPython:response withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"window.getCollectionBehavior"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:1];
    NSString *windowId = args[0];
    NSUInteger behaviorBitmask = [SPRSeed windowForId:windowId].collectionBehavior;
    NSString *response = [NSString stringWithFormat:@"window.getCollectionBehavior\t%@\t%lu", windowId, (unsigned long)behaviorBitmask];
    [self sendToPython:response withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"window.setCollectionBehavior"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:2];
    NSString *windowId = args[0];
    NSUInteger behaviorBitmask = [args[1] longLongValue];
    [SPRSeed windowForId:windowId].collectionBehavior = behaviorBitmask;
    NSString *response = [NSString stringWithFormat:@"window.setCollectionBehavior\t%@\t%lu", windowId, (unsigned long)behaviorBitmask];
    [self sendToPython:response withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"window.getMinSize"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:1];
    NSString *windowId = args[0];
    NSSize size = [[SPRSeed windowForId:windowId] minSize];
    NSString *response = [NSString stringWithFormat:@"window.getMinSize\t%@\t%f\t%f", windowId, size.width, size.height];
    [self sendToPython:response withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"window.setMinSize"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:3];
    NSString *windowId = args[0];
    float width = [args[1] floatValue];
    float height = [args[2] floatValue];
    [[SPRSeed windowForId:windowId] setMinSize:CGSizeMake(width, height)];
    [self sendToPython:command withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"window.getMaxSize"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:1];
    NSString *windowId = args[0];
    NSSize size = [[SPRSeed windowForId:windowId] maxSize];
    NSString *response = [NSString stringWithFormat:@"window.getMaxSize\t%@\t%f\t%f", windowId, size.width, size.height];
    [self sendToPython:response withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"window.setMaxSize"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:3];
    NSString *windowId = args[0];
    float width = [args[1] floatValue];
    float height = [args[2] floatValue];
    [[SPRSeed windowForId:windowId] setMaxSize:CGSizeMake(width, height)];
    [self sendToPython:command withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"window.getKey"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:1];
    NSString *windowId = args[0];
    BOOL isKey = [[SPRSeed windowForId:windowId] isKeyWindow];
    NSString *response = [NSString stringWithFormat:@"window.getKey\t%@\t%d", windowId, isKey];
    [self sendToPython:response withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"window.makeKey"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:1];
    NSString *windowId = args[0];
    [[SPRSeed windowForId:windowId] makeKeyWindow];
    [self sendToPython:command withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"window.makeKeyAndFront"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:1];
    NSString *windowId = args[0];
    [NSApp activateIgnoringOtherApps:YES];
    [[SPRSeed windowForId:windowId] makeKeyAndOrderFront:NSApp];
    [self sendToPython:command withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"window.borrowOwnership"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:1];
    NSString *windowId = args[0];
    [NSApp activateIgnoringOtherApps:NO];
    if (![NSWorkspace.sharedWorkspace.frontmostApplication.bundleIdentifier isEqualToString:@"tfredding.Sprout"]) {
      windowToOriginallyFocusedApp[windowId] = NSWorkspace.sharedWorkspace.frontmostApplication;
    }
    [NSApp activateIgnoringOtherApps:YES];
    [[SPRSeed windowForId:windowId] makeKeyAndOrderFront:NSApp];
    [self sendToPython:command withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"window.returnOwnership"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:1];
    NSString *windowId = args[0];
    // [NSApp activateIgnoringOtherApps:YES];
    if ([windowToOriginallyFocusedApp objectForKey:windowId]) {
      NSRunningApplication *originalApp = [windowToOriginallyFocusedApp objectForKey:windowId];
      [originalApp activateWithOptions:NSApplicationActivateIgnoringOtherApps];
      [windowToOriginallyFocusedApp removeObjectForKey:windowId];
    }
    [[NSApplication sharedApplication] activateIgnoringOtherApps:NO];
    [[SPRSeed windowForId:windowId] orderOut:self];
    [self sendToPython:command withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"window.getSupportsUserActions"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:1];
    NSString *windowId = args[0];
    BOOL value = [[SPRSeed windowForId:windowId] supportsUserActions];
    NSString *message = [NSString stringWithFormat:@"window.getSupportsUserActions\t%@\t%d", windowId, value];
    [self sendToPython:message withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"window.setSupportsUserActions"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:2];
    NSString *windowId = args[0];
    BOOL newValue = [args[1] boolValue];
    [[SPRSeed windowForId:windowId] setSupportsUserActions:newValue];
    [self sendToPython:command withUniqueId:uniqueId];
/********** WebView Commands **********/
  } else if ([commandType isEqualToString:@"window.setIndexPath"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:2];
    NSString *windowId = args[0];
    NSString *indexPath = args[1];
    if ([indexPath characterAtIndex:0] == '~') {
      indexPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), [indexPath substringFromIndex:1]];
    }
    [SPRSeed setIndexPath:indexPath ofWindow:windowId];
    [self sendToPython:[NSString stringWithFormat:@"window.setIndexPath\t%@\t%@", windowId, indexPath] withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"window.sendMessage"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:2];
    NSString *windowId = args[0];
    NSString *message = args[1];
    message = [self stringByUnescaping:message];
    [SPRSeed sendMessage:message toWindow:windowId];
    NSString *response = [NSString stringWithFormat:@"window.sendMessage\t%@\t%@", windowId, message];
    [self sendToPython:response withUniqueId:uniqueId];
  } else {
    NSLog(@"Unrecognized Command: '%@'", command);
  }
}

- (NSString *)firstWordInString:(NSString *)command {
  NSUInteger nextTab = [command rangeOfString:@"\t"].location;
  if (nextTab == NSNotFound) return command;
  else return [command substringToIndex:nextTab];
}

- (NSArray<NSString *> *)argsFromCommand:(NSString *)command argNum:(NSUInteger)argNum {
  NSString *commandType = [self firstWordInString:command];
  if (commandType.length == command.length) return @[];
  NSString *args = [command substringFromIndex:commandType.length+1];
  NSMutableArray<NSString *> *rtn = [[NSMutableArray alloc] init];
  NSString *argsLeft = args;
  for (NSUInteger i = 0; i < argNum; ++i) {
    NSUInteger nextSpace = [argsLeft rangeOfString:@"\t"].location;
    if (nextSpace == NSNotFound) {
      [rtn addObject:argsLeft];
      [self assert:(rtn.count == argNum)
           message:[NSString stringWithFormat:@"Too few args for command '%@'", command]];
      return rtn;
    }
    if (i == argNum - 1) {
      [rtn addObject:argsLeft];
      return rtn;
    }
    [rtn addObject:[argsLeft substringToIndex:nextSpace]];
    argsLeft = [argsLeft substringFromIndex:nextSpace + 1];
  }
  return rtn;
}

- (void)hotkeyPressed:(NSNumber *)keyCodeNum withFlags:(NSNumber *)flagsNum {
  UInt32 keyCode = (UInt32)[keyCodeNum unsignedIntegerValue];
  SPRKeyFlag flags = (SPRKeyFlag)[flagsNum unsignedIntegerValue];
  BOOL cmd = ((flags & 1) != 0);
  BOOL opt = ((flags & 2) != 0);
  BOOL ctrl = ((flags & 4) != 0);
  BOOL shift = ((flags & 8) != 0);
  NSString *message = [NSString stringWithFormat:@"hotKeyPressed\t%u\t%d%d%d%d", keyCode, cmd, opt, ctrl, shift];
  [self sendToPython:message withUniqueId:[self generateUniqueId]];
}

- (void)sproutMainTerminated {
  if (self.delegate) [self.delegate didEnd];
}

- (void)assert:(BOOL)check message:(NSString *)message {
  if (check) return;
  NSLog(@"ASSERT FAILED: %@", message);
  [self terminate];
}

- (void)timerCallbackWithUniqueId:(NSString *)uniqueId {
  [self sendToPython:@"doLater" withUniqueId:uniqueId];
}

- (NSString *)_runAppleScript:(NSString *)script {
  // https://stackoverflow.com/a/4505664
  NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:script];
  NSDictionary *errDict = nil;
  NSAppleEventDescriptor *result = [appleScript executeAndReturnError:&errDict];
  return [result stringValue];
}

- (CGFloat)time {
  return [[NSDate date] timeIntervalSince1970];
}

- (NSString *)stringByEscaping:(NSString *)s {
  NSString *rtn = [s stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
  rtn = [rtn stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
  rtn = [rtn stringByReplacingOccurrencesOfString:@"\t" withString:@"\\t"];
  return rtn;
}

- (NSString *)stringByUnescaping:(NSString *)s {
  BOOL consume = YES;
  NSMutableString *rtn = [[NSMutableString alloc] init];
  for (NSUInteger i = 0; i < s.length; ++i) {
    unichar c = [s characterAtIndex:i];
    if (consume) {
      if (c == '\\') consume = NO;
      else [rtn appendFormat:@"%C", c];
    } else {
      if (c == '\\') [rtn appendString:@"\\"];
      else if (c == 't') [rtn appendString:@"\t"];
      else if (c == 'n') [rtn appendString:@"\n"];
      consume = YES;
    }
  }
  return rtn;
}

- (void)makeLaunchOnLogin {
  // This relies on a deprecated API.
  // https://stackoverflow.com/a/23627055
  NSURL *bundleURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
  LSSharedFileListRef loginItemsListRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
  NSDictionary *properties;
  properties = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"com.apple.loginitem.HideOnLaunch"];
  LSSharedFileListItemRef itemRef = LSSharedFileListInsertItemURL(loginItemsListRef,
                                                                  kLSSharedFileListItemLast,
                                                                  NULL,
                                                                  NULL,
                                                                  (__bridge CFURLRef)bundleURL,
                                                                  (__bridge CFDictionaryRef)properties,
                                                                  NULL);
  if (itemRef) {
    CFRelease(itemRef);
  }
}

- (void)fileSearchFinishedWithResults:(NSArray<NSString *> *)results uniqueId:(NSString *)uniqueId {
  NSMutableString *response = [@"searchFiles" mutableCopy];
  for (NSString *result in results) {
    [response appendString:@"\t"];
    [response appendString:result];
  }
  [self sendToPython:response withUniqueId:uniqueId];
}

@end
