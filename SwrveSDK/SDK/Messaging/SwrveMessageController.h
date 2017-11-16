#import "SwrveMessageDelegate.h"

@class SwrveCampaign;
@class SwrveMessage;
@class SwrveConversation;
@class SwrveButton;

/*! A block that will be called when an install button in an in-app message
 * is pressed.
 *
 * Returning FALSE stops the normal flow preventing
 * Swrve to process the install action. Return TRUE otherwise.
 */
typedef BOOL (^SwrveInstallButtonPressedCallback) (NSString* appStoreUrl);

/*! A block that will be called when a custom button in an in-app message
 * is pressed.
 */
typedef void (^SwrveCustomButtonPressedCallback) (NSString* action);

/*! In-app messages controller */
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000
@interface SwrveMessageController : NSObject<SwrveMessageDelegate, SwrveMessageEventHandler, CAAnimationDelegate>
#else
@interface SwrveMessageController : NSObject<SwrveCampaignsSDK, SwrveMessageDelegate, SwrveMessageEventHandler>
#endif

- (instancetype)init NS_UNAVAILABLE;

/*! Find an in-app message for the given trigger event that also satisfies the rules
 * set up in the dashboard.
 *
 * \param event Trigger event name.
 * \returns In-app message for the given tirgger.
 */
- (SwrveMessage*)messageForEvent:(NSString *)event;

/*! Find an in-app conversation for the given trigger event that also satisfies the rules
 * set up in the dashboard.
 *
 * \param event Trigger event name.
 * \returns In-app conversation for the given tirgger.
 */
- (SwrveConversation*)conversationForEvent:(NSString *)event;

/*! Notify that the user pressed an in-app message button.
 *
 * \param button Button pressed by the user.
 */
-(void)buttonWasPressedByUser:(SwrveButton*)button;

/*! Notify that a message was shown to the user.
 *
 * \param message Message that was shown to the user.
 */
-(void)messageWasShownToUser:(SwrveMessage*)message;

/*! Obtain the app store URL configured for the given app.
 *
 * \param appID App ID of the target app.
 * \returns App store url for the given app.
 */
- (NSString*)appStoreURLForAppId:(long)appID;

/*! Creates a new fullscreen UIWindow, adds messageViewController to it and makes
 * it visible. If a message window is already displayed, nothing is done.
 *
 * \param messageViewController Message view controller.
 */
- (void) showMessageWindow:(UIViewController*) messageViewController;

/*! Dismisses the message if it is visible. If the message window is not visible
 * nothing is done.
 */
- (void) dismissMessageWindow;

/*! Get the list active Message Center campaigns targeted for this user.
 * It will exclude campaigns that have been deleted with the
 * removeCampaign method and those that do not support the current orientation.
 *
 * To obtain all Message Center campaigns independent of their orientation support
 * use the messageCenterCampaignsThatSupportOrientation(UIInterfaceOrientationUnknown) method.
 *
 * \returns List of active Message Center campaigns.
 */
-(NSArray*) messageCenterCampaigns;

/*! Get the list active Message Center campaigns targeted for this user.
 * It will exclude campaigns that have been deleted with the
 * removeCampaign method and those that do not support the given orientation.
 *
 * \returns List of active Message Center campaigns that support the given orientation.
 */
-(NSArray*) messageCenterCampaignsThatSupportOrientation:(UIInterfaceOrientation)orientation;

/*! Display the given campaign without the need to trigger an event and skipping
 * the configured rules.
 * \param campaign Campaign that will be displayed.
 * \returns if the campaign was shown.
 */
-(BOOL)showMessageCenterCampaign:(SwrveCampaign*)campaign;

/*! Remove this campaign. It won't be returned anymore by the method messageCenterCampaigns.
 *
 * \param campaign Campaign that will be removed.
 */
-(void)removeMessageCenterCampaign:(SwrveCampaign*)campaign;

#pragma mark Properties

@property (nonatomic, retain) UIColor* inAppMessageBackgroundColor;                     /*!< Background color of in-app messages. */
@property (nonatomic, retain) id <SwrveMessageDelegate> showMessageDelegate;            /*!< Implement this delegate to intercept in-app messages. */
@property (nonatomic, copy)   SwrveCustomButtonPressedCallback customButtonCallback;    /*!< Implement this delegate to process custom button actions. */
@property (nonatomic, copy)   SwrveInstallButtonPressedCallback installButtonCallback;  /*!< Implement this delegate to intercept install button actions. */
@property (nonatomic, retain) CATransition* showMessageTransition;                      /*!< Animation for displaying messages. */
@property (nonatomic, retain) CATransition* hideMessageTransition;                      /*!< Animation for hiding messages. */

#pragma mark -

@end
