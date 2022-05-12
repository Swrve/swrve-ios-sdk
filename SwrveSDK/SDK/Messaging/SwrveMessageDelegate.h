#import "SwrveBaseMessage.h"
#import "SwrveMessage.h"
#import "SwrveEmbeddedMessage.h"
#import "SwrveConversation.h"
#import "SwrveMessageViewController.h"

#import <Foundation/Foundation.h>

/*! Delegate used to control how in-app messages are shown in your app. */
@protocol SwrveMessageDelegate <NSObject>

@optional

/*! Called when a message should be shown. Should show and react to the action
 * in the message. By default the SwrveMessageController will display the
 * message as a modal dialog. If an install action is returned by the dialog
 * it will direct the user to the app store. If you have a custom action you
 * should create a custom delegate to process it in your app.
 *
 * \param message Message to be displayed.
 */
- (void)showMessage:(SwrveMessage *)message __deprecated_msg("Use embedded campaigns instead.");

/*! Called when a message should be shown. Should show and react to the action
 * in the message. By default the SwrveMessageController will display the
 * message as a modal dialog. If an install action is returned by the dialog
 * it will direct the user to the app store. If you have a custom action you
 * should create a custom delegate to process it in your app.
 *
 * \param message Message to be displayed.
 * \param personalization Dictionary of Strings which can be used to personalise the given message
 */
- (void)showMessage:(SwrveMessage *)message withPersonalization:(NSDictionary *)personalization __deprecated_msg("Use embedded campaigns instead.");

/*! Called when a conversation should be shown. Should show and react to the action
 * in the conversation.
 *
 * \param conversation Conversation to be displayed.
 */
- (void)showConversation:(SwrveConversation *)conversation __deprecated_msg("Use embedded campaigns instead.");

/*! Called when the message will be shown to the user. The message is shown in
 * a separate UIWindow. This selector is called before that UIWindow is shown.
 *
 * \param viewController Message view controller.
 */
- (void)messageWillBeShown:(UIViewController *) viewController __deprecated_msg("Use embedded campaigns instead.");

/*! Called when the message will be hidden from the user. The message is shown
 * in a separate UIWindow. This selector is called before that UIWindow is
 * hidden.
 *
 * \param viewController Message view controller.
 */
- (void)messageWillBeHidden:(UIViewController*) viewController __deprecated_msg("Use embedded campaigns instead.");

/*! Called to animate the display of a message. Implement this selector
 * to customize the display of the message.
 *
 * \param viewController Message view controller.
 */
- (void)beginShowMessageAnimation:(SwrveMessageViewController*) viewController __deprecated_msg("Use embedded campaigns instead.");

/*! Called to animate the hiding of a message. Implement this selector to
 * customize the hiding of the message. If you implement this you must call
 * [SwrveMessageController dismissMessageWindow] to dismiss the message window
 * after your animation is complete.
 *
 * \param viewController Message view controller.
 */
- (void)beginHideMessageAnimation:(SwrveMessageViewController*) viewController __deprecated_msg("Use embedded campaigns instead.");

@end
