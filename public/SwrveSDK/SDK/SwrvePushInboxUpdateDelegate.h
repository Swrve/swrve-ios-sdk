#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SwrvePushInboxUpdateDelegate <NSObject>

/*! This method is invoked when Push Inbox Messages have been initially loaded and each time they are updated.
 */
- (void)messagesUpdated;

@end
NS_ASSUME_NONNULL_END
