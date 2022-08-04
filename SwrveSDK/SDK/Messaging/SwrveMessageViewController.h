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
