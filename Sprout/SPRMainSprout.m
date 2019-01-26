#import "SPRMainSprout.h"

#include <time.h>
#include <stdlib.h>

#import "SPRWebWindow.h"

@implementation SPRMainSprout {
  NSTask *_task;
  NSPipe *_inPipe;
  NSPipe *_outPipe;
}

# pragma mark - Public

- (void)launch {
  NSString *pathToSproutMain = [NSBundle.mainBundle pathForResource:@"SproutObjcInterface" ofType:@"py"];
  _task = [[NSTask alloc] init];
  _task.launchPath = @"/usr/local/bin/python";
  _task.arguments = @[ pathToSproutMain ];
  _inPipe = [[NSPipe alloc] init];
  _outPipe = [[NSPipe alloc] init];
  _task.standardInput = _inPipe;
  _task.standardOutput = _outPipe;
  [SPRSeed setDelegate:self];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(sproutMainTerminated)
                                               name:NSTaskDidTerminateNotification
                                             object:_task];
  [NSNotificationCenter.defaultCenter
      addObserver:self
         selector:@selector(pythonSentMessage)
             name:NSFileHandleDataAvailableNotification
           object:_outPipe.fileHandleForReading];
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
  // TODO: Use this event.
}
- (void)windowRemoved {
  // TODO: Use this event.
}
- (void)windowDidLoad:(NSString *)windowId {
  // TODO: Use this event.
  [self sendToPython:[NSString stringWithFormat:@"window.didLoad\t%@", windowId] withUniqueId:[self generateUniqueId]];
}
- (void)didReceiveMessage:(NSString *)message fromWindow:(NSString *)windowId {
  [self sendToPython:[NSString stringWithFormat:@"window.request\t%@\t%@", windowId, message] withUniqueId:[self generateUniqueId]];
}

# pragma mark - I/O

- (void)sendToPython:(NSString *)string withUniqueId:(NSString *)uniqueId {
  NSString *flushString = [NSString stringWithFormat:@"%@\t%@\n", uniqueId, string];
  NSLog(@"sendToPython:%@", flushString);
  NSData *data = [flushString dataUsingEncoding:NSUTF8StringEncoding];
  [_inPipe.fileHandleForWriting writeData:data];
}

- (void)pythonSentMessage {
  NSData *data = _outPipe.fileHandleForReading.availableData;
  NSString *outStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  [_outPipe.fileHandleForReading waitForDataInBackgroundAndNotify];
  NSArray<NSString *> *lines = [outStr componentsSeparatedByString:@"\n"];
  for (NSString *line in lines) {
    if (line.length == 0) continue;
    [self handleLineFromPython:line];
  }
}

# pragma mark - Private

- (NSString *)generateUniqueId {
  srand(time(NULL));
  int r = rand() % 1000000;
  return [NSString stringWithFormat:@"%d", r];
}

- (void)handleLineFromPython:(NSString *)line {
  NSLog(@"handleLineFromPython:%@", line);
  NSString *uniqueId = [self firstWordInString:line];
  NSString *command = [line substringFromIndex:uniqueId.length + 1];
  NSString *commandType = [self firstWordInString:command];
  if ([commandType isEqualToString:@"print"]) {
    NSLog(@"Python Print: '%@'", [command substringFromIndex:commandType.length + 1]);
  } else if ([commandType isEqualToString:@"quit"]) {
    [self terminate];
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
  } else if ([commandType isEqualToString:@"searchFiles"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:4];
    NSUInteger maxResults = [args[0] integerValue];
    NSString *flags = args[1];
    NSArray<NSString *> *extensions = [args[2] componentsSeparatedByString:@" "];
    NSString *path = args[3];
    SPRFileSearchQuery *query = [[SPRFileSearchQuery alloc] init];
    query.maxResults = maxResults;
    query.descendSubdirs = ([flags characterAtIndex:0] != '0');
    query.searchHidden = ([flags characterAtIndex:1] != '0');
    query.excludeDirs = ([flags characterAtIndex:2] != '0');
    query.excludeFiles = ([flags characterAtIndex:3] != '0');
    query.extensions = [NSSet setWithArray:extensions];
    query.path = path;
    NSArray<NSString *> *matches = [SPRSeed searchFilesWithQuery:query];
    NSMutableString *response = @"searchFiles".mutableCopy;
    for (NSString *match in matches) {
      [response appendString:@"\t"];
      [response appendString:match];
    }
    [self sendToPython:response withUniqueId:uniqueId];
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
    [[SPRSeed windowForId:windowId] setTitleVisibility:visibility];
    [[SPRSeed windowForId:windowId] setTitle:newTitle];
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
  } else if ([commandType isEqualToString:@"window.setMovable"]) {
  } else if ([commandType isEqualToString:@"window.getInteractable"]) {
  } else if ([commandType isEqualToString:@"window.setInteractable"]) {
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
    [[SPRSeed windowForId:windowId] makeKeyAndOrderFront:NSApp];
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
  BOOL cmd = (flags & 1) == 1;
  BOOL opt = (flags & 2) == 1;
  BOOL ctrl = (flags & 4) == 1;
  BOOL shift = (flags & 8) == 1;
  [self sendToPython:[NSString stringWithFormat:@"hotKeyPressed %u %d%d%d%d", keyCode, cmd, opt, ctrl, shift]
        withUniqueId:[self generateUniqueId]];
}

- (void)sproutMainTerminated {
  if (self.delegate) [self.delegate didEnd];
}

- (void)assert:(BOOL)check message:(NSString *)message {
  if (check) return;
  NSLog(@"ASSERT FAILED: %@", message);
  [self terminate];
}

@end
