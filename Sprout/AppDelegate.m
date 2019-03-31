#import "AppDelegate.h"
#import "SPRMainSprout.h"

@interface AppDelegate () <SPRMainSproutDelegate>
@end

@implementation AppDelegate {
  // SPRMainSprout *_sproutMain;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  NSWindow *w = [[NSWindow alloc] init];
  WKWebView *webView = [[WKWebView alloc] init];
  webView.frame = CGRectMake(0, 0, 400, 400);
  BOOL web = NO;
  if (web) {
    NSURL *url = [NSURL URLWithString:@"https://www.google.com/"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [webView loadRequest:request];
    // webView.navigationDelegate = self;
  } else {
    NSString *path = @"~/Desktop/q/index.html";
    if ([path characterAtIndex:0] == '~') {
      path = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), [path substringFromIndex:1]];
    }
    [webView loadFileURL:[NSURL fileURLWithPath:path]
 allowingReadAccessToURL:[NSURL fileURLWithPath:@"/"]];
  }
  w.contentView = webView;
  [w display];
  [w setFrame:CGRectMake(400, 400, 400, 400) display:YES];
  [w makeKeyAndOrderFront:self];
  
  
  /*
  _sproutMain = [[SPRMainSprout alloc] init];
  _sproutMain.delegate = self;
  [_sproutMain launch];*/
  /*[NSEvent addGlobalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^(NSEvent *event) {
    NSLog(@"TFR:%@", event);
  }];*/
}

-(void)applicationWillTerminate:(NSNotification *)notification {
  // [_sproutMain terminate];
}

#pragma mark - SproutMainDelegate

- (void)didEnd {
  [NSApplication.sharedApplication terminate:nil];
}

@end
