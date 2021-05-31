#import "SwrveMessage.h"
#import "SwrveInAppMessageConfig.h"

@class SwrveMessage;

/*! Manage an in-app message on screen */
@interface SwrveMessageViewController : UIViewController

@property (nonatomic, weak) SwrveMessageController* messageController;   /*!< Message controller. */
@property (nonatomic, retain) SwrveMessage*      message;   /*!< Message to render. */
@property (nonatomic, copy)   SwrveMessageResult block;     /*!< Custom code to execute when a button is tapped or a message is dismissed by a user. */
@property (nonatomic)         BOOL               prefersIAMStatusBarHidden; /*!< Allows the view controler to decide if the status bar is visible. */
@property (nonatomic, retain) NSDictionary*      personalizationDict; /*!< NSDictionary of key value pairs used for personalization. */
@property (nonatomic, retain) SwrveInAppMessageConfig *inAppConfig; /*!< Configuration for personalized text, colors and styling */

/*! Called by the view when a button is pressed */
-(IBAction)onButtonPressed:(id)sender;

@end
