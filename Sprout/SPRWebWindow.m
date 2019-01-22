#import "SPRWebWindow.h"

#import <WebKit/WebKit.h>

#import "SPRSeed.h"

@implementation SPRWebWindow {
  NSString *_widgetId;
  WKWebView *_webView;
}

- (instancetype)initWithId:(NSString *)widgetId path:(NSString *)path {
  self = [super init];
  if (self) {
    _widgetId = widgetId;
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
    [self loadFromRoot:path];
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

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
  NSString *injection = @"\
  var spr = {\
  \"send\": (message) => {\
  window.webkit.messageHandlers.sprout_kyaQmKP75mE6RolA.postMessage(message);\
  },\"receive\": (message) => {\
  },\"foo\": 12\
  };";
  [_webView evaluateJavaScript:injection completionHandler:^(id result, NSError *error) {
    CGSize size = NSScreen.mainScreen.frame.size;
    CGFloat width = MIN(800, size.width);
    CGFloat height = MIN(600, size.height);
    [self setFrame:NSMakeRect((size.width-width)/2, (size.height-height)/2, width, height) display:YES];
    [self center];
    [self makeKeyAndOrderFront:NSApp];
    
    
    self->_webView.frame = NSMakeRect(0, 0, self.frame.size.width, self.frame.size.height);
    [SPRSeed widgetDidLoad:self->_widgetId];
  }];
}

# pragma mark - WKScriptMessageHandler

// Called by spr.send(foo);
-(void)userContentController:(WKUserContentController *)userContentController
     didReceiveScriptMessage:(WKScriptMessage *)message {
  if ([message.body isKindOfClass:[NSString class]]) {
    // `foo` becomes message.body and can be an NSString, NSDictionary, NSArray, BOOL, or NSNumber.
    // We require a string.
    [SPRSeed didReceiveMessage:message.body fromWidget:_widgetId];
  }
}

# pragma mark - Public

- (void)sendMessage:(NSString *)message {
  NSString *escapedMessage =
  [message stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
  NSString *injection =
      [NSString stringWithFormat:@"if(spr.receive) spr.receive(\"%@\");", escapedMessage];
  [_webView evaluateJavaScript:injection completionHandler:^(id result, NSError *error) {}];
}

- (void)setKey:(NSString *)key withValue:(NSString *)value {
  if ([key isEqualToString:@"x"]) {
    CGFloat x = [value floatValue];
    [self setFrameOrigin:CGPointMake(x, self.frame.origin.y)];
  } else if ([key isEqualToString:@"y"]) {
    CGFloat y = [value floatValue];
    [self setFrameOrigin:CGPointMake(self.frame.origin.x, y)];
  } else if ([key isEqualToString:@"width"]) {
    CGFloat width = [value floatValue];
    CGRect newRect =
        CGRectMake(self.frame.origin.x, self.frame.origin.y, width, self.frame.size.height);
    [self setFrame:newRect display:YES];
  } else if ([key isEqualToString:@"height"]) {
    CGFloat height = [value floatValue];
    CGRect newRect =
        CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, height);
    [self setFrame:newRect display:YES];
  }
}

- (NSString *)getValueFromKey:(NSString *)key {
  if ([key isEqualToString:@"x"]) {
    return [NSString stringWithFormat:@"%f", self.frame.origin.x];
  } else if ([key isEqualToString:@"y"]) {
    return [NSString stringWithFormat:@"%f", self.frame.origin.y];
  } else if ([key isEqualToString:@"width"]) {
    return [NSString stringWithFormat:@"%f", self.frame.size.width];
  } else if ([key isEqualToString:@"height"]) {
    return [NSString stringWithFormat:@"%f", self.frame.size.height];
  }
  return nil;
}

# pragma mark - Private
/**
 Unused.
 */
- (void)loadWebsite:(NSString *)urlString {
  [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
}

- (void)loadFromRoot:(NSString *)rootPath {
  NSURL *x = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/index.html", rootPath]];
  NSURL *y = [NSURL fileURLWithPath:rootPath];
  [_webView loadFileURL:x allowingReadAccessToURL:y];
}

@end
