#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SPRWebWindowDelegate
- (void)webWindowDidBecomeMain:(NSString *)windowId;
- (void)webWindowDidResignMain:(NSString *)windowId;
@end

@interface SPRWebWindow : NSWindow <NSWindowDelegate, WKNavigationDelegate, WKScriptMessageHandler>

- (instancetype)initWithId:(NSString *)widgetId;
- (void)setIndexPath:(NSString *)indexPath;
- (void)sendMessage:(NSString *)string;

@property BOOL supportsUserActions;
@property BOOL isWidget;
@property id<SPRWebWindowDelegate> webWindowDelegate;

@end

NS_ASSUME_NONNULL_END
