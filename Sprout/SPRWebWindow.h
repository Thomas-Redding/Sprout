#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SPRWebWindow : NSWindow <NSWindowDelegate, WKNavigationDelegate, WKScriptMessageHandler>

- (instancetype)initWithId:(NSString *)widgetId path:(NSString *)path;
- (void)sendMessage:(NSString *)string;
- (void)setKey:(NSString *)key withValue:(NSString *)value;
- (NSString *)getValueFromKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
