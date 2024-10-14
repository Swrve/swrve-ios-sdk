#import <UIKit/UIKit.h>
#import "SwrveUIButton.h"
#import "Swrve.h"
#import "SwrveButton.h"
#import "SwrveImage.h"
#import "SwrveMessageController.h"
#import "SwrveMessagePage.h"
#import "SwrveSDKUtils.h"

@class SwrveEmbeddedMessage;

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
@property(nonatomic, retain, nullable) SwrveMessageFormat *currentMessageFormat; // dependent on orientation or screen size

- (id)initWithMessageController:(SwrveMessageController *)swrveMessageController
                        message:(SwrveMessage *)swrveMessage
                personalization:(nullable NSDictionary *)personalization;

- (void)showPage:(NSNumber *)number;
- (void)onButtonPressed:(SwrveUIButton*)button pageId:(NSNumber *)pageId;
- (void)queuePageViewEvent:(NSNumber *)pageId;

@end

NS_ASSUME_NONNULL_END
