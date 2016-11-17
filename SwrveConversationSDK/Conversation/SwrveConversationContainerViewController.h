#import <UIKit/UIKit.h>

@interface SwrveConversationContainerViewController : UIViewController

@property (nonatomic)         BOOL               prefersStatusBarHidden; /*!< Allows the view controler to decide if the status bar is visible. */

-(id) initWithChildViewController:(UIViewController*)childController;

@end
