#import "SwrveMessage.h"
#import "SwrveConversation.h"
#import "SwrveMessageViewController.h"

#import <Foundation/Foundation.h>

/*! Delegate used to control how in-app messages are shown in your app. */
@protocol SwrveMessageDelegate <NSObject>

@optional

/*! Called when an event is raised by the Swrve SDK. Look up a message
 * to display. Return nil if no message should be displayed. By default
 * the SwrveMessageController will search for messages with the provided
 * trigger.
 *
 * \param eventName Trigger event.
 * \param payload Event payload.
 * \returns Message with the given trigger event.
 */
- (SwrveMessage*)messageForEvent:(NSString*) eventName withPayload:(NSDictionary *)payload;

/*! Called when an event is raised by the Swrve SDK. Look up a conversation
 * to display. Return nil if no conversation should be displayed. By default
 * the SwrveMessageController will search for conversations with the provided
 * trigger.
 *
 * \param eventName Trigger event.
 * \param payload Event payload.
 * \returns Conversation with the given trigger event.
 */
- (SwrveConversation*)conversationForEvent:(NSString*) eventName withPayload:(NSDictionary *)payload;

/*! Called when a message should be shown. Should show and react to the action
 * in the message. By default the SwrveMessageController will display the
 * message as a modal dialog. If an install action is returned by the dialog
 * it will direct the user to the app store. If you have a custom action you
 * should create a custom delegate to process it in your app.
 *
 * \param message Message to be displayed.
 */
- (void)showMessage:(SwrveMessage *)message;

/*! Called when a message should be shown. Should show and react to the action
 * in the message. By default the SwrveMessageController will display the
 * message as a modal dialog. If an install action is returned by the dialog
 * it will direct the user to the app store. If you have a custom action you
 * should create a custom delegate to process it in your app.
 *
 * \param message Message to be displayed.
 * \param personalisation Dictionary of Strings which can be used to personalise the given message
 */
- (void)showMessage:(SwrveMessage *)message withPersonalisation:(NSDictionary *)personalisation;

/*! Called when a conversation should be shown. Should show and react to the action
 * in the conversation.
 *
 * \param conversation Conversation to be displayed.
 */
- (void)showConversation:(SwrveConversation *)conversation;

/*! Called when the message will be shown to the user. The message is shown in
 * a separate UIWindow. This selector is called before that UIWindow is shown.
 *
 * \param viewController Message view controller.
 */
- (void) messageWillBeShown:(UIViewController *) viewController;

/*! Called when the message will be hidden from the user. The message is shown
 * in a separate UIWindow. This selector is called before that UIWindow is
 * hidden.
 *
 * \param viewController Message view controller.
 */
- (void) messageWillBeHidden:(UIViewController*) viewController;

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
