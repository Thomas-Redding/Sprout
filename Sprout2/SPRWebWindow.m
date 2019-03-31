#import "SPRWebWindow.h"

#import <WebKit/WebKit.h>

#import "SPRSeed.h"

@interface SPRWebView : WKWebView
@property BOOL supportsUserActions;
@end

@implementation SPRWebView
-(BOOL)acceptsFirstResponder { return YES; }
-(BOOL)canBecomeKeyView { return YES; }
// - (NSView *)hitTest:(NSPoint)point { return self.supportsUserActions ? [super hitTest:point] : nil; }
-(void)mouseDown:(NSEvent *)theEvent {}
@end

@implementation SPRWebWindow {
  CGPoint _initialMousePos;
  NSString *_windowId;
  SPRWebView *_webView;
  BOOL _inDesktop;
}

- (instancetype)initWithId:(NSString *)windowId {
  self = [super init];
  if (self) {
    _windowId = windowId;
    self.opaque = NO;
    self.backgroundColor = NSColor.clearColor;
    self.delegate = self;
    _inDesktop = NO;
    
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

- (void)setInDesktop:(BOOL)inDesktop {
  if (_inDesktop == inDesktop) return;
  _inDesktop = inDesktop;
  if (_inDesktop) {
    self.level = kCGDesktopIconWindowLevel - 1;
  } else {
    self.level = 0;
  }
}
-(BOOL)inDesktop {
  return _inDesktop;
}

- (BOOL)canBecomeKeyWindow { return _webView.supportsUserActions; }
- (BOOL)canBecomeMainWindow { return YES; }
- (void)setTitlebarAppearsTransparent:(BOOL)titlebarAppearsTransparent {
  // https://github.com/electron/electron/issues/15008
  super.titlebarAppearsTransparent = titlebarAppearsTransparent;
  if (titlebarAppearsTransparent) {
    self.styleMask = (self.styleMask & !NSWindowStyleMaskTitled);
  } else {
    self.styleMask = (self.styleMask | NSWindowStyleMaskTitled);
    [self setMovableByWindowBackground:NO];
  }
  [self privateLayout];
}

- (void)sendEvent:(NSEvent *)event {
  if(event.type == NSEventTypeLeftMouseDown) {
    _initialMousePos = NSEvent.mouseLocation;
  } else if(event.type == NSEventTypeLeftMouseDragged) {
    CGPoint mouse = NSEvent.mouseLocation;
    CGFloat dx = mouse.x - _initialMousePos.x;
    CGFloat dy = mouse.y - _initialMousePos.y;
    CGPoint newOrigin = CGPointMake(self.frame.origin.x + dx, self.frame.origin.y + dy);
    _initialMousePos = mouse;
    [self setFrameOrigin:newOrigin];
  }
  [super sendEvent:event];
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
  escapedMessage = [escapedMessage stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
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
