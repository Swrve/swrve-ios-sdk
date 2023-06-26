#import <Foundation/Foundation.h>
#import "SwrveMessageDetails.h"
#import "SwrveMessageButtonDetails.h"

NS_ASSUME_NONNULL_BEGIN

///*! Actions associated with in app messages*/
typedef enum {
    SwrveActionDismiss = 0,
    SwrveActionCustom = 1,
    SwrveActionClipboard = 2,
    SwrveImpression = 3
} SwrveMessageAction;

@protocol SwrveInAppMessageDelegate <NSObject>

@optional

- (void)onAction:(SwrveMessageAction)messageAction messageDetails:(SwrveMessageDetails *)messageDetails selectedButton:(nullable SwrveMessageButtonDetails *)selectedButton;

@end

NS_ASSUME_NONNULL_END


