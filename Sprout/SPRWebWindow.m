#import "SPRWebWindow.h"

#import <WebKit/WebKit.h>

#import "SPRSeed.h"

static const int keyCodeConverter[130] = {
   65,  83,  68,  60,  72,  71, 90,  88, 67,  86,
   -1,  66,  81,  87,  69,  82, 89,  84, 49,  50,
   51,  52,  54,  53, 187,  57, 55, 189, 56,  48,
  221,  79,  85, 219,  73,  80, -1,  76, 74, 222,
   75, 186, 220, 188, 191,  78, 77, 190,  9,  -1,
  192,   8,  -1,  27,  -1,  -1, -1,  -1, -1,  -1, // ` delete escape
   -1,  -1,  -1,  -1,  -1,  -1, -1,  -1, -1,  -1,
   -1,  -1,  -1,  -1,  -1,  -1, -1,  -1, -1,  -1,
   -1,  -1,  -1,  -1,  -1,  -1, -1,  -1, -1,  -1,
   -1,  -1,  -1,  -1,  -1,  -1, -1,  -1, -1,  -1,
   -1,  -1,  -1,  -1,  -1,  -1, -1,  -1, -1,  -1,
   -1,  -1,  -1,  -1,  -1,  -1, -1,  -1, -1,  -1,
   -1,  -1,  -1,  37,  39,  40, 38,  -1, -1,  -1 // arrow keys
};

@interface SPRWebView : WKWebView
@property BOOL supportsUserActions;
@end

@implementation SPRWebView
-(BOOL)acceptsFirstResponder { return YES; }
-(BOOL)canBecomeKeyView { return YES; }
- (NSView *)hitTest:(NSPoint)point { return self.supportsUserActions ? [super hitTest:point] : nil; }
@end

@implementation SPRWebWindow {
  NSString *_windowId;
  SPRWebView *_webView;
}

- (instancetype)initWithId:(NSString *)windowId {
  self = [super init];
  if (self) {
    _windowId = windowId;
    self.opaque = NO;
    self.backgroundColor = NSColor.clearColor;
    self.delegate = self;
    
    WKUserContentController *controller = [[WKUserContentController alloc] init];
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.userContentController = controller;
    _webView = [[SPRWebView alloc] initWithFrame:NSZeroRect configuration:config];
    _webView.supportsUserActions = YES;
    [controller addScriptMessageHandler:self name:@"sprout_kyaQmKP75mE6RolA"];
    _webView.navigationDelegate = self;
    // https://stackoverflow.com/a/49736463
    [_webView setValue:@NO forKey:@"drawsBackground"];
    // [_webView setValue:@YES forKey:@"drawsTransparentBackground"];
    self.contentView = self->_webView;
  }
  return self;
}

# pragma mark - Super

- (BOOL)canBecomeKeyWindow { return _webView.supportsUserActions; }
- (BOOL)canBecomeMainWindow { return YES; }
- (void)setTitlebarAppearsTransparent:(BOOL)titlebarAppearsTransparent {
  super.titlebarAppearsTransparent = titlebarAppearsTransparent;
  [self privateLayout];
}

/*
NSEventModifierFlagCapsLock           = 1 << 16, // Set if Caps Lock key is pressed.
NSEventModifierFlagShift              = 1 << 17, // Set if Shift key is pressed.
NSEventModifierFlagControl            = 1 << 18, // Set if Control key is pressed.
NSEventModifierFlagOption             = 1 << 19, // Set if Option or Alternate key is pressed.
NSEventModifierFlagCommand            = 1 << 20, // Set if Command key is pressed.
NSEventModifierFlagNumericPad         = 1 << 21, // Set if any key in the numeric keypad is pressed.
NSEventModifierFlagHelp               = 1 << 22, // Set if the Help key is pressed.
NSEventModifierFlagFunction           = 1 << 23, // Set if any function key is pressed.
*/

- (void)keyDown:(NSEvent *)event {
  // By default, WKWebView doesn't accept hotkeys, so we have to pass them in manually.
  if (event.keyCode >= 130) { NSLog(@"UNKNOWN KEYCODE 1: %d", event.keyCode); return; }
  int webKeyCode = keyCodeConverter[event.keyCode];
  if (webKeyCode == -1) { NSLog(@"UNKNOWN KEYCODE 2: %d", event.keyCode); return; }
  NSString *c = [event.characters substringToIndex:1];
  NSString *keyCode = [NSString stringWithFormat:@"%d", webKeyCode];
  NSString *cmd = ((event.modifierFlags & NSEventModifierFlagCommand) == NSEventModifierFlagCommand) ? @"true" : @"false";
  NSString *opt = ((event.modifierFlags & NSEventModifierFlagOption) == NSEventModifierFlagOption) ? @"true" : @"false";
  NSString *ctrl = ((event.modifierFlags & NSEventModifierFlagControl) == NSEventModifierFlagControl) ? @"true" : @"false";
  NSString *shift = ((event.modifierFlags & NSEventModifierFlagShift) == NSEventModifierFlagShift) ? @"true" : @"false";
  NSString *injection = [NSString stringWithFormat:@"window.spr._hotkey('%@', %@, %@, %@, %@, %@)", c, keyCode, cmd, opt, ctrl, shift];
  [_webView evaluateJavaScript:injection completionHandler:^(id result, NSError *error) {}];
}

# pragma mark - NSWindowDelegate

- (void)windowDidResize:(NSNotification *)notification {
  [self privateLayout];
}

- (void)windowDidBecomeMain:(NSNotification *)notification {
  // Might want `windowDidBecomeKey:`.
  [self.webWindowDelegate webWindowDidBecomeMain:_windowId];
}

- (void)windowDidResignMain:(NSNotification *)notification {
  // Might want `windowDidResignKey:`.
  [self.webWindowDelegate webWindowDidResignMain:_windowId];
}

# pragma mark - WKNavigationDelegate

-(void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
  // https://stackoverflow.com/a/12187302
  NSString *injection = @"\
  var spr = {\
    \"send\": (message) => {\
      window.webkit.messageHandlers.sprout_kyaQmKP75mE6RolA.postMessage(message);\
    },\
    \"receive\": (message) => {},\
    \"hotkeyCallbacks\": [],\
    \"_hotkey\": (c, keyCode, cmd, opt, ctrl, shift) => {\
      for (var i = 0; i < spr.hotkeyCallbacks.length; ++i) {\
        spr.hotkeyCallbacks[i](c, keyCode, cmd, opt, ctrl, shift);\
      }\
    }\
  };";
  [_webView evaluateJavaScript:injection completionHandler:^(id result, NSError *error) {
    [SPRSeed webWindowDidLoad:self->_windowId];
  }];
}

# pragma mark - WKScriptMessageHandler

// Called by spr.send(foo);
-(void)userContentController:(WKUserContentController *)userContentController
     didReceiveScriptMessage:(WKScriptMessage *)message {
  if ([message.body isKindOfClass:[NSString class]]) {
    // `foo` becomes message.body and can be an NSString, NSDictionary, NSArray, BOOL, or NSNumber.
    // We require a string.
    [SPRSeed didReceiveMessage:message.body fromWindow:_windowId];
  }
}

# pragma mark - Public

- (void)sendMessage:(NSString *)message {
  NSString *escapedMessage =
      [message stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
  NSString *injection =
      [NSString stringWithFormat:@" window.spr.receive(\"%@\"); ", escapedMessage];
  [_webView evaluateJavaScript:injection completionHandler:^(id result, NSError *error) {}];
}

- (void)setIndexPath:(NSString *)indexPath {
  [_webView loadFileURL:[NSURL fileURLWithPath:indexPath] allowingReadAccessToURL:[NSURL fileURLWithPath:@"/"]];
}

- (BOOL)supportsUserActions { return _webView.supportsUserActions; }

- (void)setSupportsUserActions:(BOOL)supportsUserActions {
  _webView.supportsUserActions = supportsUserActions;
  if (!_webView.supportsUserActions) [self resignKeyWindow];
}

# pragma mark - Private
/**
 Unused.
 */
- (void)loadWebsite:(NSString *)urlString {
  [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
}

- (void)privateLayout {
  CGFloat height = self.frame.size.height;
  if (!self.titlebarAppearsTransparent) {
    height = [self contentRectForFrameRect: self.frame].size.height;
  }
  _webView.frame = CGRectMake(0, 0, self.frame.size.width, height);
}

@end
