//
//  AppDelegate.m
//  Sprout
//
//  Created by Thomas Redding on 1/4/19.
//  Copyright © 2019 Thomas Redding. All rights reserved.
//

#import "AppDelegate.h"
#import "SPRSeed.h"

@protocol SproutMainDelegate
- (void)didEnd;
@end

@interface SproutMain : NSObject
- (void)start;
- (void)end;
- (void)input:(NSString *)string;
@property id<SproutMainDelegate> delegate;
@end

@implementation SproutMain {
  NSTask *_task;
  NSPipe *_inPipe;
  NSPipe *_outPipe;
}

# pragma mark - Public

- (void)start {
  NSString *pathToSproutMain = [NSBundle.mainBundle pathForResource:@"main-sprout" ofType:@"py"];
  _task = [[NSTask alloc] init];
  _task.launchPath = @"/usr/local/bin/python";
  _task.arguments = @[ pathToSproutMain ];
  _inPipe = [[NSPipe alloc] init];
  _outPipe = [[NSPipe alloc] init];
  _task.standardInput = _inPipe;
  _task.standardOutput = _outPipe;
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

- (void)input:(NSString *)string {
  NSString *flushString = [NSString stringWithFormat:@"%@\n", string];
  NSData *data = [flushString dataUsingEncoding:NSUTF8StringEncoding];
  [_inPipe.fileHandleForWriting writeData:data];
}

# pragma mark - Private

- (void)didOutput:(NSString *)string {
  NSRange range = [string rangeOfString:@" "];
  if (range.location == NSNotFound) {
    NSLog(@"No Command: '%@'", string);
    return;
  }
  NSString *type = [string substringToIndex:range.location];
  NSString *argsString = [string substringFromIndex:range.location + 1];
  if ([type isEqualToString:@"registerHotkey"]) {
    NSLog(@"Register Hot Key Command: '%@';", string);
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
  } else {
    NSLog(@"Unrecognized Command: '%@'", string);
  }
}

- (void)end {
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



@interface AppDelegate () <SproutMainDelegate>
@end

@implementation AppDelegate {
  NSUInteger _count;
  SproutMain *_sproutMain;
  NSTimer *_timer;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  _sproutMain = [[SproutMain alloc] init];
  _sproutMain.delegate = self;
  [_sproutMain start];
  _timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                            target:self
                                          selector:@selector(timer)
                                          userInfo:nil
                                           repeats:YES];
  _count = 0;
}

#pragma mark - Private

- (void)timer {
       if (_count == 0) [_sproutMain input:@"one"];
  else if (_count == 1) [_sproutMain input:@"two"];
  else if (_count == 2) [_sproutMain input:@"three"];
  else if (_count == 3) [_sproutMain input:@"four"];
  else if (_count == 4) [_sproutMain input:@"five"];
  else if (_count == 5) [_sproutMain input:@"six"];
  else [_timer invalidate];
  ++_count;
}

#pragma mark - SproutMainDelegate

- (void)didEnd {
  NSLog(@"didEnd");
  [NSApplication.sharedApplication terminate:nil];
}

@end
