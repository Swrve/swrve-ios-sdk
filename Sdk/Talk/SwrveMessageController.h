#import "SwrveMessageViewController.h"

static NSString* const AUTOSHOW_AT_SESSION_START_TRIGGER = @"Swrve.Messages.showAtSessionStart";

@class SwrveMessage;
@class SwrveButton;
@class Swrve;

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

/*! Delegate used to control how in-app messages are shown in your app. */
@protocol SwrveMessageDelegate <NSObject>

@optional

/*! Called when an event is raised by the Swrve SDK. Look up a message
 * to display. Return nil if no message should be displayed. By default
 * the SwrveMessageController will search for messages with the provided
 * trigger.
 *
 * \param eventName Trigger event.
 * \param parameters Event parameters.
 * \returns Button with the given trigger event.
 */
- (SwrveMessage*)findMessageForEvent:(NSString*) eventName withParameters:(NSDictionary *)parameters;

/*! Called when a message should be shown. Should show and react to the action
 * in the message. By default the SwrveMessageController will display the
 * message as a modal dialog. If an install action is returned by the dialog
 * it will direct the user to the app store. If you have a custom action you
 * should create a custom delegate to process it in your app.
 *
 * \param message Message to be displayed.
 */
- (void)showMessage:(SwrveMessage *)message;

/*! Called when the message will be shown to the user. The message is shown in
 * a separate UIWindow. This selector is called before that UIWindow is shown.
 *
 * \param viewController Message view controller.
 */
- (void) messageWillBeShown:(SwrveMessageViewController *) viewController;

/*! Called when the message will be hidden from the user. The message is shown
 * in a separate UIWindow. This selector is called before that UIWindow is
 * hidden.
 *
 * \param viewController Message view controller.
 */
- (void) messageWillBeHidden:(SwrveMessageViewController*) viewController;

/*! Called to animate the display of a message. Implement this selector
 * to customize the display of the message.
 *
 * \param viewController Message view controller.
 */
- (void) beginShowMessageAnimation:(SwrveMessageViewController*) viewController;

/*! Called to animate the hiding of a message. Implement this selector to
 * customize the hiding of the message. If you implement this you must call
 * [SwrveMessageController dismissMessageWindow] to dismiss the message window
 * after your animation is complete.
 *
 * \param viewController Message view controller.
 */
- (void) beginHideMessageAnimation:(SwrveMessageViewController*) viewController;

@end

/*! In-app messages controller */
@interface SwrveMessageController : NSObject<SwrveMessageDelegate>

@property (nonatomic, retain) UIColor* backgroundColor;                                 /*!< Background color of in-app messages. */
@property (nonatomic, retain) NSArray* campaigns;                                       /*!< List of campaigns available to the user. */
@property (nonatomic, retain) id <SwrveMessageDelegate> showMessageDelegate;            /*!< Implement this delegate to intercept in-app messages. */
@property (nonatomic, copy)   SwrveCustomButtonPressedCallback customButtonCallback;    /*!< Implement this delegate to process custom button actions. */
@property (nonatomic, copy)   SwrveInstallButtonPressedCallback installButtonCallback;  /*!< Implement this delegate to intercept install button actions. */
@property (nonatomic, retain) CATransition* showMessageTransition;                      /*!< Animation for displaying messages. */
@property (nonatomic, retain) CATransition* hideMessageTransition;                      /*!< Animation for hiding messages. */

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

/*! Format the given time into POSIX time. For internal use.
 *
 * \param date Date to format into text.
 * \returns Date formatted into a POSIX string.
 */
+(NSString*)getTimeFormatted:(NSDate*)date;

/*! Shuffle the given array randomly. For internal use.
 *
 \param source Array to be shuffled.
 \returns Copy of the array, now shuffled randomly.
 */
+(NSArray*)shuffled:(NSArray*)source;

/*! Called when an event is raised by the Swrve SDK. For internal use.
 *
 * \param event Event triggered.
 * \returns YES if an in-app message was shown.
 */
-(BOOL)eventRaised:(NSDictionary*)event;

/*! Call this method when you get a push notification device token from Apple.
 *
 * \param deviceToken Apple device token for your app.
 */
- (void)setDeviceToken:(NSData*)deviceToken;

/*! Process the given push notification.
 *
 * \param userInfo Push notification information.
 */
- (void)pushNotificationReceived:(NSDictionary*)userInfo;

/*! Check if the user is a QA user. For internal use.
 *
 * \returns TRUE if the current user is a QA user.
 */
- (BOOL)isQaUser;

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

@end

