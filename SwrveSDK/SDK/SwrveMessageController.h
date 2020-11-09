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
typedef BOOL (^SwrveInstallButtonPressedCallback)(NSString *appStoreUrl);

/*! A block that will be called when a custom button in an in-app message
 * is pressed.
 */
typedef void (^SwrveCustomButtonPressedCallback)(NSString *action);

/*! A block that will be called when a dismiss button in an in-app message
 * is pressed.
 */
typedef void (^SwrveDismissButtonPressedCallback)(NSString *campaignSubject, NSString *buttonName);

/*! A block that will be called when a clipboard button in an in-app message
 * is pressed.
 */
typedef void (^SwrveClipboardButtonPressedCallback)(NSString *processedText);

/*! A block that will be called when an event triggers an in-app message with personalisation
 * \param eventPayload the payload associated with the message
 * \returns NSDictionary of key / value strings used for personalising the IAM
 */
typedef NSDictionary *(^SwrveMessagePersonalisationCallback)(NSDictionary *eventPayload);

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000

@interface SwrveMessageController : NSObject <SwrveMessageDelegate, SwrveMessageEventHandler, CAAnimationDelegate>
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
- (SwrveMessage *)messageForEvent:(NSString *)event;

/*! Find an in-app conversation for the given trigger event that also satisfies the rules
 * set up in the dashboard.
 *
 * \param event Trigger event name.
 * \returns In-app conversation for the given tirgger.
 */
- (SwrveConversation *)conversationForEvent:(NSString *)event;

/*! Notify that the user pressed an in-app message button.
 *
 * \param button Button pressed by the user.
 */
- (void)buttonWasPressedByUser:(SwrveButton *)button;

/*! Notify that a message was shown to the user.
 *
 * \param message Message that was shown to the user.
 */
- (void)messageWasShownToUser:(SwrveMessage *)message;

/*! Obtain the app store URL configured for the given app.
 *
 * \param appID App ID of the target app.
 * \returns App store url for the given app.
 */
- (NSString *)appStoreURLForAppId:(long)appID;

/*! Creates a new fullscreen UIWindow, adds messageViewController to it and makes
 * it visible. If a message window is already displayed, nothing is done.
 *
 * \param messageViewController Message view controller.
 */
- (void)showMessageWindow:(UIViewController *)messageViewController;

/*! Dismisses the message if it is visible. If the message window is not visible
 * nothing is done.
 */
- (void)dismissMessageWindow;

/*! Get the list active Message Center campaigns targeted for this user.
 * It will exclude campaigns that have been deleted with the
 * removeCampaign method and those that do not support the current orientation.
 *
 * To obtain all Message Center campaigns independent of their orientation support
 * use the messageCenterCampaignsThatSupportOrientation(UIInterfaceOrientationUnknown) method.
 *
 * \returns List of active Message Center campaigns.
 */
- (NSArray *)messageCenterCampaigns;

/*! Get the list active Message Center campaigns targeted for this user and might have personalisation that can be resolved.
 * It will exclude campaigns that have been deleted with the
 * removeCampaign method and those that do not support the current orientation.
 *
 * To obtain all Message Center campaigns independent of their orientation support
 * use the messageCenterCampaignsThatSupportOrientation(UIInterfaceOrientationUnknown) method.
 *
 * \param personalisation Personalisation properties for in-app messages.
 * \returns List of active Message Center campaigns.
 */
- (NSArray *)messageCenterCampaignsWithPersonalisation:(NSDictionary *)personalisation;

#if TARGET_OS_IOS /** exclude tvOS **/

/*! Get the list active Message Center campaigns targeted for this user.
 * It will exclude campaigns that have been deleted with the
 * removeCampaign method and those that do not support the given orientation.
 *
 * \param orientation Required orientation.
 * \returns List of active Message Center campaigns that support the given orientation.
 */
- (NSArray *)messageCenterCampaignsThatSupportOrientation:(UIInterfaceOrientation)orientation;

/*! Get the list active Message Center campaigns targeted for this user and might have personalisation that can be resolved.
 * It will exclude campaigns that have been deleted with the
 * removeCampaign method and those that do not support the given orientation.
 *
 * \param orientation Required orientation.
 * \param personalisation Personalisation properties for in-app messages.
 * \returns List of active Message Center campaigns that support the given orientation.
*/
- (NSArray *)messageCenterCampaignsThatSupportOrientation:(UIInterfaceOrientation)orientation withPersonalisation:(NSDictionary *)personalisation;

#endif

/*! Display the given campaign without the need to trigger an event and skipping
 * the configured rules.
 * \param campaign Campaign that will be displayed.
 * \returns if the campaign was shown.
 */
- (BOOL)showMessageCenterCampaign:(SwrveCampaign *)campaign;

/*! Display the given campaign without the need to trigger an event and skipping
 * the configured rules.
 * \param campaign Campaign that will be displayed.
 * \param personalisation Dictionary <String, String> used to personalise the campaign
 * \returns if the campaign was shown.
 */
- (BOOL)showMessageCenterCampaign:(SwrveCampaign *)campaign withPersonalisation:(NSDictionary *)personalisation;

/*! Remove the given campaign. It won't be returned anymore by the method messageCenterCampaigns.
 *
 * \param campaign Campaign that will be removed.
 */
- (void)removeMessageCenterCampaign:(SwrveCampaign *)campaign;

/*! Mark the campaign as seen. This is done automatically by Swrve but you can call this if you are rendering the messages on your own.
 *
 * \param campaign Campaign that will be marked as seen.
 */
- (void)markMessageCenterCampaignAsSeen:(SwrveCampaign *)campaign;

#pragma mark Properties

@property(nonatomic, retain) SwrveInAppMessageConfig *inAppMessageConfig;                  /*!< Configuration for the InApp Messaging*/
@property(nonatomic, weak) id <SwrveMessageDelegate> showMessageDelegate;                  /*!< Implement this delegate to intercept in-app messages. */
@property(nonatomic, copy) SwrveCustomButtonPressedCallback customButtonCallback;        /*!< Implement this delegate to process custom button actions. */
@property(nonatomic, copy) SwrveDismissButtonPressedCallback dismissButtonCallback;      /*!< Implement this delegate to process dismiss button action. */
@property(nonatomic, copy) SwrveInstallButtonPressedCallback installButtonCallback;      /*!< Implement this delegate to intercept install button actions. */
@property(nonatomic, copy) SwrveClipboardButtonPressedCallback clipboardButtonCallback;  /*!< Implement this delegate to intercept clipboard button actions. */
@property(nonatomic, copy) SwrveMessagePersonalisationCallback personalisationCallback;  /*!< Implement this delegate to intercept IAM calls with personalisation . */
@property(nonatomic, retain) CATransition *showMessageTransition;                          /*!< Animation for displaying messages. */
@property(nonatomic, retain) CATransition *hideMessageTransition;                          /*!< Animation for hiding messages. */
@property(nonatomic, retain) NSMutableArray *conversationsMessageQueue;                   /*!< Conversation / Message queue */

#pragma mark -

@end
