#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SPRWebWindow : NSWindow <NSWindowDelegate, WKNavigationDelegate, WKScriptMessageHandler>

- (instancetype)initWithId:(NSString *)widgetId;
- (void)setIndexPath:(NSString *)indexPath;
- (void)sendMessage:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
