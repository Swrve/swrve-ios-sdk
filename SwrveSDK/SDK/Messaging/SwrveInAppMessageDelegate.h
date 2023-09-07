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

/*! Use this delegate to get callbacks for supported actions within Swrve In-App Messages
 *  It is important to handle each message action as this delegate can be called multiple times eg for an Impression and Button actions such as Custom, Dismiss or Clipboard

 @param messageAction the message action, see SwrveMessageAction for supported types
 @param messageDetails the message details, see SwrveMessageDetails for meta data
 @param selectedButton the selected button, see SwrveMessageButtonDetails for meta data, this will be nil if messageAction is an Impression
 
 @code
 - (void)onAction:(SwrveMessageAction)messageAction messageDetails:(SwrveMessageDetails *)messageDetails selectedButton:(SwrveMessageButtonDetails *)selectedButton {

     switch (messageAction) {
         case SwrveImpression:
            break;
         case SwrveActionCustom:
             
             // If there is a deeplink, we will call open url internally unless SwrveDeeplinkDelegate is implemented, if it is, the deeplink url will be passed to the SwrveDeeplinkDelegate.
         
             break;
         case SwrveActionDismiss:
             break;
         case SwrveActionClipboard:
             break;
         default:
             break;
     }
 }
 @endcode
 */
- (void)onAction:(SwrveMessageAction)messageAction messageDetails:(SwrveMessageDetails *)messageDetails selectedButton:(nullable SwrveMessageButtonDetails *)selectedButton;

@end

NS_ASSUME_NONNULL_END


