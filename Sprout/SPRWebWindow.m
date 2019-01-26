#import "SPRWebWindow.h"

#import <WebKit/WebKit.h>

#import "SPRSeed.h"

@implementation SPRWebWindow {
  NSString *_windowId;
  WKWebView *_webView;
}

- (instancetype)initWithId:(NSString *)windowId {
  self = [super init];
  if (self) {
    _windowId = windowId;
    [self setOpaque:NO];
    // self.titlebarAppearsTransparent = YES;
    self.delegate = self;
    
    WKUserContentController *controller = [[WKUserContentController alloc] init];
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.userContentController = controller;
    _webView = [[WKWebView alloc] initWithFrame:NSZeroRect configuration:config];
    [controller addScriptMessageHandler:self name:@"sprout_kyaQmKP75mE6RolA"];
    _webView.navigationDelegate = self;
    self.contentView = self->_webView;
  }
  return self;
}

# pragma mark - Super

- (BOOL)canBecomeKeyWindow { return YES; }
- (BOOL)canBecomeMainWindow { return YES; }
- (void)setTitlebarAppearsTransparent:(BOOL)titlebarAppearsTransparent {
  super.titlebarAppearsTransparent = titlebarAppearsTransparent;
  [self privateLayout];
}

# pragma mark - NSWindowDelegate

- (void)windowDidResize:(NSNotification *)notification {
  [self privateLayout];
}

# pragma mark - WKNavigationDelegate

// - (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
-(void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
  NSString *injection = @"\
  var spr = {\
    \"send\": (message) => {\
      window.webkit.messageHandlers.sprout_kyaQmKP75mE6RolA.postMessage(message);\
    },\
    \"receive\": (message) => {}\
  };";
  [_webView evaluateJavaScript:injection completionHandler:^(id result, NSError *error) {
    [SPRSeed windowDidLoad:self->_windowId];
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
