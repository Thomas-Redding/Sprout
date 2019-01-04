#import "AppDelegate.h"
#import "SPRMainSprout.h"

@interface AppDelegate () <SPRMainSproutDelegate>
@end

@implementation AppDelegate {
  SPRMainSprout *_sproutMain;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  _sproutMain = [[SPRMainSprout alloc] init];
  _sproutMain.delegate = self;
  [_sproutMain launch];
}

#pragma mark - SproutMainDelegate

- (void)didEnd {
  [NSApplication.sharedApplication terminate:nil];
}

@end
