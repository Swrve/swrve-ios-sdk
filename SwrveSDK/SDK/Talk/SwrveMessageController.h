#import "SwrveMessageDelegate.h"

static NSString* const AUTOSHOW_AT_SESSION_START_TRIGGER = @"Swrve.Messages.showAtSessionStart";
const static int CAMPAIGN_VERSION            = 6;
const static int CAMPAIGN_RESPONSE_VERSION   = 2;

@class SwrveBaseCampaign;
@class SwrveMessage;
@class SwrveConversation;
@class SwrveButton;
@class Swrve;
@class SwrveConversationsNavigationController;
@class SwrveConversationItemViewController;

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

/*! Initialize the message controller.
 *
 * \param swrve Swrve SDK instance.
 * \returns Initialized message controller.
 */
- (id)initWithSwrve:(Swrve*)swrve;

/*! Find an in-app message for the given trigger event that also satisfies the rules
 * set up in the dashboard.
 *
 * \param event Trigger event name.
 * \returns In-app message for the given tirgger.
 */
- (SwrveMessage*)getMessageForEvent:(NSString *)event;

/*! Find an in-app conversation for the given trigger event that also satisfies the rules
 * set up in the dashboard.
 *
 * \param event Trigger event name.
 * \returns In-app conversation for the given tirgger.
 */
- (SwrveConversation*)getConversationForEvent:(NSString *)event;

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
- (NSString*)getAppStoreURLForGame:(long)appID;

#pragma mark - push support block
#if !defined(SWRVE_NO_PUSH)

/*! Call this method when you get a push notification device token from Apple.
 *
 * \param deviceToken Apple device token for your app.
 */
- (void)setDeviceToken:(NSData*)deviceToken;

/*! Process the given push notification. Internally, it calls -pushNotificationReceived:atApplicationState: with the current application state.
 *
 * \param userInfo Push notification information.
 */
- (void)pushNotificationReceived:(NSDictionary*)userInfo;

/*! Process the given push notification.
 *
 * \param userInfo Push notification information.
 * \param applicationState Application state at the time when the push notificatin was received.
 */
- (void)pushNotificationReceived:(NSDictionary*)userInfo atApplicationState:(UIApplicationState)applicationState;

/*! Process the given silent push.
 *
 * \param userInfo Push information.
 */
- (void)silentPushReceived:(NSDictionary *)userInfo withCompletionHandler:(void (^)(UIBackgroundFetchResult, NSDictionary*))completionHandler;
#endif //!defined(SWRVE_NO_PUSH)
#pragma mark -

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
-(BOOL)showMessageCenterCampaign:(SwrveBaseCampaign*)campaign;

/*! Remove this campaign. It won't be returned anymore by the method getCampaigns.
 *
 * \param campaign Campaing that will be removed.
 */
-(void)removeMessageCenterCampaign:(SwrveBaseCampaign*)campaign;


/*! PRIVATE: Save campaigns current state*/
-(void)saveCampaignsState;

/*! PRIVATE: ensure any currently displaying conversations are dismissed*/
-(void) cleanupConversationUI;

/*! PRIVATE: Format the given time into POSIX time.
 *
 * \param date Date to format into text.
 * \returns Date formatted into a POSIX string.
 */
+(NSString*)getTimeFormatted:(NSDate*)date;

/*! PRIVATE: Shuffle the given array randomly.
 *
 \param source Array to be shuffled.
 \returns Copy of the array, now shuffled randomly.
 */
+(NSArray*)shuffled:(NSArray*)source;

/*! PRIVATE: Called when an event is raised by the Swrve SDK.
 *
 * \param event Event triggered.
 * \returns YES if an in-app message was shown.
 */
-(BOOL)eventRaised:(NSDictionary*)event;

/*! PRIVATE: Check if the user is a QA user.
 *
 * \returns TRUE if the current user is a QA user.
 */
- (BOOL)isQaUser;

/*! PRIVATE: Determine if the conversation filters are supporter at this moment.
 *
 * \param filters Filters we need to support to display the campaign.
 * \returns nil if all devices are supported or the name of the filter that is not supported.
 */
-(NSString*) supportsDeviceFilters:(NSArray*)filters;

/*! PRIVATE: Called when the app became active */
-(void) appDidBecomeActive;

#pragma mark Properties

@property (nonatomic) Swrve*  analyticsSDK;                                             /*!< Analytics SDK reference. */
@property (nonatomic, retain) UIColor* inAppMessageBackgroundColor;                     /*!< Background color of in-app messages. */
@property (nonatomic, retain) UIColor* conversationLightboxColor;                       /*!< Background color of conversations. */
@property (nonatomic, retain) id <SwrveMessageDelegate> showMessageDelegate;            /*!< Implement this delegate to intercept in-app messages. */
@property (nonatomic, copy)   SwrveCustomButtonPressedCallback customButtonCallback;    /*!< Implement this delegate to process custom button actions. */
@property (nonatomic, copy)   SwrveInstallButtonPressedCallback installButtonCallback;  /*!< Implement this delegate to intercept install button actions. */
@property (nonatomic, retain) CATransition* showMessageTransition;                      /*!< Animation for displaying messages. */
@property (nonatomic, retain) CATransition* hideMessageTransition;                      /*!< Animation for hiding messages. */

@property (nonatomic, retain) SwrveConversationItemViewController* swrveConversationItemViewController;

#pragma mark -

@end

