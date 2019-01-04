#import "SPRSeed.h"

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SPRMainSproutDelegate

/* A method called when main-sprout.py is termianted.  */
- (void)didEnd;

@end

@interface SPRMainSprout : NSObject

/* Launch main-sprout.py */
- (void)launch;

/* Terminate main-sprout.py */
- (void)terminate;

/* An object to notify when main-sprout.py is termianted.  */
@property id<SPRMainSproutDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
