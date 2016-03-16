#import <Foundation/Foundation.h>

@class SwrveCommonConversation;

@protocol SwrveCommonMessageController <NSObject>

/*! Notify that a message was shown to the user.
 *
 * \param message Message that was shown to the user.
 */
-(void)conversationWasShownToUser:(SwrveCommonConversation*)conversation;

/*! Notify that the latest conversation was dismissed. */
- (void) conversationClosed;

@end
