#import "SwrveBaseMessage.h"
#import "SwrveMessage.h"
#import "SwrveEmbeddedMessage.h"
#import "SwrveConversation.h"
#import "SwrveMessageViewController.h"
#import "SwrveEmbeddedMessageConfig.h"

@class SwrveCampaign;
@class SwrveMessage;
@class SwrveBaseMessage;
@class SwrveEmbeddedMessage;
@class SwrveConversation;
@class SwrveButton;

@interface SwrveMessageController : NSObject <SwrveMessageEventHandler, CAAnimationDelegate>

/*! Find a base message which could an in-app or embedded for the given trigger event
 * that also satisfies the rules set up in the dashboard.
 *
 * \param event Trigger event name.
 * \returns SwrveBaseMessage for the given trigger.
 */
- (SwrveBaseMessage *)baseMessageForEvent:(NSString *)event;

/*! Inform that am embedded message has been served and processed. This function should be called
 * by your implementation to update the campaign information and send the appropriate data to
 * Swrve.
 *
 * \param message embedded message that has been processed
 */
- (void)embeddedMessageWasShownToUser:(SwrveEmbeddedMessage *)message;

/*! Process an embedded message engagement event. This function should be called by your
 * implementation to inform Swrve of a button event.
 *
 * \param message embedded message that has been processed
 * \param button  button that was pressed
 */
- (void)embeddedButtonWasPressed:(SwrveEmbeddedMessage *)message buttonName:(NSString *)button;

/*! Get the personalized data string from a SwrveEmbeddedMessage campaign with a map of custom
 * personalization properties.
 *
 * \param message Embedded message campaign to personalize
 * \param personalizationProperties  personalizationProperties Custom properties which are used for personalization.
 * \return The data string with personalization properties applied. Null is returned if personalization fails with the custom properties passed in.
 */
- (NSString *)personalizeEmbeddedMessageData:(SwrveEmbeddedMessage *)message withPersonalization:(NSDictionary *)personalizationProperties;

/*! Get the personalized data string from a piece of text with a map of custom personalization properties.
 *
 * \param text String value which will be personalized
 * \param personalizationProperties  personalizationProperties Custom properties which are used for personalization.
 * \return The data string with personalization properties applied. Null is returned if personalization fails with the custom properties passed in.
 */
- (NSString *)personalizeText:(NSString *)text withPersonalization:(NSDictionary *)personalizationProperties;

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

/*! Get the list active Message Center campaigns targeted for this user and might have personalization that can be resolved.
 * It will exclude campaigns that have been deleted with the
 * removeCampaign method and those that do not support the current orientation.
 *
 * To obtain all Message Center campaigns independent of their orientation support
 * use the messageCenterCampaignsThatSupportOrientation(UIInterfaceOrientationUnknown) method.
 *
 * \param personalization Personalization properties for in-app messages.
 * \returns List of active Message Center campaigns.
 */
- (NSArray *)messageCenterCampaignsWithPersonalization:(NSDictionary *)personalization;

/*! Get Message Center campaign targeted for this user and might have personalization that can be resolved.
 * It will exclude campaigns that have been deleted with the
 * removeCampaign method and those that do not support the current orientation.
 *
 * \param personalization Personalization properties for in-app messages.
 * \param campaignID  ID of campaign
 * \returns Message Center Campaign
 */
- (SwrveCampaign *)messageCenterCampaignWithID:(NSUInteger)campaignID andPersonalization:(NSDictionary *)personalization;

#if TARGET_OS_IOS /** exclude tvOS **/

/*! Get the list active Message Center campaigns targeted for this user.
 * It will exclude campaigns that have been deleted with the
 * removeCampaign method and those that do not support the given orientation.
 *
 * \param orientation Required orientation.
 * \returns List of active Message Center campaigns that support the given orientation.
 */
- (NSArray *)messageCenterCampaignsThatSupportOrientation:(UIInterfaceOrientation)orientation;

/*! Get the list active Message Center campaigns targeted for this user and might have personalization that can be resolved.
 * It will exclude campaigns that have been deleted with the
 * removeCampaign method and those that do not support the given orientation.
 *
 * \param orientation Required orientation.
 * \param personalization Personalization properties for in-app messages.
 * \returns List of active Message Center campaigns that support the given orientation.
*/
- (NSArray *)messageCenterCampaignsThatSupportOrientation:(UIInterfaceOrientation)orientation withPersonalization:(NSDictionary *)personalization;

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
 * \param personalization Dictionary <String, String> used to personalise the campaign
 * \returns if the campaign was shown.
 */
- (BOOL)showMessageCenterCampaign:(SwrveCampaign *)campaign withPersonalization:(NSDictionary *)personalization;

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

@property(nonatomic, retain) SwrveInAppMessageConfig *inAppMessageConfig;                /*!< Configuration for the InApp Messaging*/
@property(nonatomic, retain) SwrveEmbeddedMessageConfig *embeddedMessageConfig;          /*!< Configuration for the Embedded Messaging*/
@property(nonatomic, copy) SwrveCustomButtonPressedCallback customButtonCallback;        /*!< Implement this delegate to process custom button actions. */
@property(nonatomic, copy) SwrveDismissButtonPressedCallback dismissButtonCallback;      /*!< Implement this delegate to process dismiss button action. */
@property(nonatomic, copy) SwrveClipboardButtonPressedCallback clipboardButtonCallback;  /*!< Implement this delegate to intercept clipboard button actions. */
@property(nonatomic, copy) SwrveMessagePersonalizationCallback personalizationCallback;  /*!< Implement this delegate to intercept IAM calls with personalization . */

#pragma mark -

@end
