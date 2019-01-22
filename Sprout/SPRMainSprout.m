#import "SPRMainSprout.h"
#import "SPRWebWindow.h"

@implementation SPRMainSprout {
  NSTask *_task;
  NSPipe *_inPipe;
  NSPipe *_outPipe;
}

# pragma mark - Public

- (void)launch {
  NSString *pathToSproutMain = [NSBundle.mainBundle pathForResource:@"main-sprout" ofType:@"py"];
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
         selector:@selector(listen)
             name:NSFileHandleDataAvailableNotification
           object:_outPipe.fileHandleForReading];
  [_outPipe.fileHandleForReading waitForDataInBackgroundAndNotify];
  [_task launch];
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
- (void)widgetDidLoad:(NSString *)widgetId {
  // TODO: Use this event.
  [self input:[NSString stringWithFormat:@"widgetDidLoad %@", widgetId]];
}
- (void)didReceiveMessage:(NSString *)message fromWidget:(NSString *)widgetId {
  [self input:[NSString stringWithFormat:@"widgetMessage %@ %@", widgetId, message]];
}

# pragma mark - Private

- (void)input:(NSString *)string {
  NSString *flushString = [NSString stringWithFormat:@"%@\n", string];
  NSData *data = [flushString dataUsingEncoding:NSUTF8StringEncoding];
  [_inPipe.fileHandleForWriting writeData:data];
}

- (void)didOutput:(NSString *)string {
  NSArray<NSString *> *commands = [string componentsSeparatedByString:@"\n"];
  for (NSString *command in commands) {
    NSRange range = [command rangeOfString:@" "];
    if (range.location == NSNotFound) {
      NSLog(@"No Command: '%@'", command);
      return;
    }
    NSString *type = [command substringToIndex:range.location];
    NSString *argsString = [command substringFromIndex:range.location + 1];
    if ([type isEqualToString:@"print"]) {
      NSLog(@"Print: '%@'", argsString);
    } else if ([type isEqualToString:@"registerHotkey"]) {
      NSArray<NSString *> *args = [argsString componentsSeparatedByString:@" "];
      if (args.count != 2) return;
      NSUInteger keyCode = [args[0] integerValue];
      NSString *flags = args[1];
      if (flags.length != 4) return;
      SPRKeyFlag keyFlag = 0;
      if ([flags characterAtIndex:0] != '0') keyFlag |= SPRKeyFlagCommand;
      if ([flags characterAtIndex:1] != '0') keyFlag |= SPRKeyFlagOption;
      if ([flags characterAtIndex:2] != '0') keyFlag |= SPRKeyFlagControl;
      if ([flags characterAtIndex:3] != '0') keyFlag |= SPRKeyFlagShift;
      [SPRSeed registerHotKeyFromKeyCode:(UInt32)keyCode
                                 keyFlag:keyFlag
                                toTarget:self
                             andSelector:@selector(hotkeyPressed:withFlags:)];
    } else if ([type isEqualToString:@"widget"]) {
      range = [argsString rangeOfString:@" "];
      if (range.location == NSNotFound) return;
      NSString *widgetId = [argsString substringToIndex:range.location];
      NSString *path = [argsString substringFromIndex:range.location + 1];
      [SPRSeed makeWidgetWithId:widgetId fromPath:path];
    } else if ([type isEqualToString:@"sendMessageToWidget"]) {
      range = [argsString rangeOfString:@" "];
      if (range.location == NSNotFound) return;
      NSString *widgetId = [argsString substringToIndex:range.location];
      NSString *message = [argsString substringFromIndex:range.location + 1];
      [SPRSeed sendWidget:widgetId message:message];
      // Do nothing.
    } else if ([type isEqualToString:@"setWidgetProperty"]) {
      range = [argsString rangeOfString:@" "];
      if (range.location == NSNotFound) return;
      NSString *widgetId = [argsString substringToIndex:range.location];
      NSString *keyValue = [argsString substringFromIndex:range.location + 1];
      range = [keyValue rangeOfString:@" "];
      if (range.location == NSNotFound) return;
      NSString *key = [keyValue substringToIndex:range.location];
      NSString *value = [keyValue substringFromIndex:range.location + 1];
      [SPRSeed setValueFromWidget:widgetId key:key value:value];
      // TODO: fish.
    } else if ([type isEqualToString:@"getWidgetProperty"]) {
      range = [argsString rangeOfString:@" "];
      if (range.location == NSNotFound) return;
      NSString *widgetId = [argsString substringToIndex:range.location];
      NSString *key = [argsString substringFromIndex:range.location + 1];
      [SPRSeed getValueFromWidget:widgetId key:key];
      // TODO: fish.
    } else {
      NSLog(@"Unrecognized Command: '%@'", command);
    }
  }
}

- (void)terminate {
  [_task terminate];
}

- (void)hotkeyPressed:(NSNumber *)keyCodeNum withFlags:(NSNumber *)flagsNum {
  UInt32 keyCode = (UInt32)[keyCodeNum unsignedIntegerValue];
  SPRKeyFlag flags = (SPRKeyFlag)[flagsNum unsignedIntegerValue];
  BOOL cmd = (flags & 1) == 1;
  BOOL opt = (flags & 2) == 1;
  BOOL ctrl = (flags & 4) == 1;
  BOOL shift = (flags & 8) == 1;
  [self input:[NSString stringWithFormat:@"hotKeyPressed %u %d%d%d%d", keyCode, cmd, opt, ctrl, shift]];
}

- (void)listen {
  NSData *data = _outPipe.fileHandleForReading.availableData;
  NSString *outStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  [_outPipe.fileHandleForReading waitForDataInBackgroundAndNotify];
  [self didOutput:outStr];
}

- (void)sproutMainTerminated {
  if (self.delegate) [self.delegate didEnd];
}

@end

