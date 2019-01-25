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
  [self sendToPython:[NSString stringWithFormat:@"window.didLoad %@", windowId] withUniqueId:[self generateUniqueId]];
}
- (void)didReceiveMessage:(NSString *)message fromWindow:(NSString *)windowId {
  [self sendToPython:[NSString stringWithFormat:@"window.request %@ %@", windowId, message] withUniqueId:[self generateUniqueId]];
}

# pragma mark - I/O

- (void)sendToPython:(NSString *)string withUniqueId:(NSString *)uniqueId {
  NSString *flushString = [NSString stringWithFormat:@"%@ %@\n", uniqueId, string];
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
  } else if ([commandType isEqualToString:@"makeWindow"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:1];
    NSString *windowId = args[0];
    [SPRSeed makeWindowWithId:windowId];
    [self sendToPython:[NSString stringWithFormat:@"makeWindow %@", windowId] withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"window.setFrame"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:5];
    NSString *windowId = args[0];
    CGFloat x = [args[1] floatValue];
    CGFloat y = [args[2] floatValue];
    CGFloat w = [args[3] floatValue];
    CGFloat h = [args[4] floatValue];
    [SPRSeed setFrame:CGRectMake(x, y, w, h) ofWindow:windowId];
    [self sendToPython:command withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"window.getFrame"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:1];
    NSString *windowId = args[0];
    CGRect frame = [SPRSeed getFrameOfWindow:windowId];
    NSString *response = [NSString stringWithFormat:@"window.getFrame %@ %f %f %f %f", windowId, frame.origin.x, frame.origin.y, frame.size.width, frame.size.height];
    [self sendToPython:response withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"window.close"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:1];
    NSString *windowId = args[0];
    [SPRSeed closeWindow:windowId];
    NSString *response = [NSString stringWithFormat:@"window.close %@", windowId];
    [self sendToPython:response withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"window.setIndexPath"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:2];
    NSString *windowId = args[0];
    NSString *indexPath = args[1];
    if ([indexPath characterAtIndex:0] == '~') {
      indexPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), [indexPath substringFromIndex:1]];
    }
    [SPRSeed setIndexPath:indexPath ofWindow:windowId];
    [self sendToPython:[NSString stringWithFormat:@"window.setIndexPath %@ %@", windowId, indexPath] withUniqueId:uniqueId];
  } else if ([commandType isEqualToString:@"window.sendMessage"]) {
    NSArray<NSString *> *args = [self argsFromCommand:command argNum:2];
    NSString *windowId = args[0];
    NSString *message = args[1];
    [SPRSeed sendMessage:message toWindow:windowId];
    NSString *response = [NSString stringWithFormat:@"window.sendMessage %@ %@", windowId, message];
    [self sendToPython:response withUniqueId:uniqueId];
  } else {
    NSLog(@"Unrecognized Command: '%@'", command);
  }
}

- (NSString *)firstWordInString:(NSString *)command {
  NSUInteger nextSpace = [command rangeOfString:@" "].location;
  if (nextSpace == NSNotFound) return command;
  else return [command substringToIndex:nextSpace];
}

- (NSArray<NSString *> *)argsFromCommand:(NSString *)command argNum:(NSUInteger)argNum {
  NSString *commandType = [self firstWordInString:command];
  if (commandType.length == command.length) return @[];
  NSString *args = [command substringFromIndex:commandType.length+1];
  NSMutableArray<NSString *> *rtn = [[NSMutableArray alloc] init];
  NSString *argsLeft = args;
  for (NSUInteger i = 0; i < argNum; ++i) {
    NSUInteger nextSpace = [argsLeft rangeOfString:@" "].location;
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

