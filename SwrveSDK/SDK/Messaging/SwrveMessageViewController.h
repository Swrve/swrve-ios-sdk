#import <UIKit/UIKit.h>

#if __has_include(<SwrveSDK/SwrveUIButton.h>)
#import <SwrveSDK/SwrveUIButton.h>
#import <SwrveSDK/Swrve.h>
#import <SwrveSDK/SwrveButton.h>
#import <SwrveSDK/SwrveImage.h>
#import <SwrveSDK/SwrveMessageController.h>
#import <SwrveSDK/SwrveMessagePage.h>
#import <SwrveSDK/SwrveSDKUtils.h>
#else
#import "SwrveUIButton.h"
#import "Swrve.h"
#import "SwrveButton.h"
#import "SwrveImage.h"
#import "SwrveMessageController.h"
#import "SwrveMessagePage.h"
#import "SwrveSDKUtils.h"
#endif

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
- (void)queueVideoEvent:(NSNumber *)pageId mediaId:(NSNumber *)mediaId action:(NSString *)action;

@end

NS_ASSUME_NONNULL_END
