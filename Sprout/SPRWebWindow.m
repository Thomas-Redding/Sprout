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
    self.movable = NO;
    [self setOpaque:NO];
    self.titlebarAppearsTransparent = YES;
    self.delegate = self;
    
    WKUserContentController *controller = [[WKUserContentController alloc] init];
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.userContentController = controller;
    _webView = [[WKWebView alloc] initWithFrame:NSZeroRect configuration:config];
    [_webView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [controller addScriptMessageHandler:self name:@"sprout_kyaQmKP75mE6RolA"];
    _webView.navigationDelegate = self;
    self.contentView = self->_webView;
    
    // Make visible.
    CGSize size = NSScreen.mainScreen.frame.size;
    CGFloat width = MIN(800, size.width);
    CGFloat height = MIN(600, size.height);
    [self setFrame:NSMakeRect((size.width-width)/2, (size.height-height)/2, width, height) display:YES];
    [self center];
    [self makeKeyAndOrderFront:NSApp];
    self->_webView.frame = NSMakeRect(0, 0, self.frame.size.width, self.frame.size.height);
  }
  return self;
}

# pragma mark - Super

-(BOOL)canBecomeKeyWindow { return YES; }
-(BOOL)canBecomeMainWindow { return YES; }

# pragma mark - NSWindowDelegate

- (void)windowDidResize:(NSNotification *)notification {
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

@end
