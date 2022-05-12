#import <UIKit/UIKit.h>

#import "SwrveMessage.h"
#import "UISwrveButton.h"

NS_ASSUME_NONNULL_BEGIN

#if TARGET_OS_TV
@interface SwrveMessageViewController : UIViewController
#else
@interface SwrveMessageViewController : UIPageViewController
#endif

@property(nonatomic, weak) SwrveMessageController *messageController;
@property(nonatomic, retain) SwrveMessage *message;
@property(nonatomic, copy) SwrveMessageResult messageResultBlock __deprecated_msg("Use embedded campaigns instead.");        /*!< Custom code to execute when a button is tapped or a message is dismissed by a user. */
@property(nonatomic, retain) NSDictionary *personalization;
@property(nonatomic, retain) NSNumber *currentPageId;
@property(nonatomic, retain) SwrveMessageFormat *currentMessageFormat; // dependent on orientation or screen size

- (id)initWithMessageController:(SwrveMessageController *)swrveMessageController
                        message:(SwrveMessage *)swrveMessage
                personalization:(NSDictionary *)personalization;

- (void)showPage:(NSNumber *)number;
- (void)onButtonPressed:(UISwrveButton*)button pageId:(NSNumber *)pageId;
- (void)queuePageViewEvent:(NSNumber *)pageId;

@end

NS_ASSUME_NONNULL_END
