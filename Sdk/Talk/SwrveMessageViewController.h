#import "SwrveMessage.h"

@class SwrveMessage;

/*! Manage an in-app message on screen */
@interface SwrveMessageViewController : UIViewController

@property (nonatomic, retain) SwrveMessage*      message;   /*!< Message to render. */
@property (nonatomic, copy)   SwrveMessageResult block;     /*!< Custom code to execute when a button is tapped or a message is dismissed by a user. */

/*! Called by the view when a button is pressed */
-(IBAction)onButtonPressed:(id)sender;

@end
