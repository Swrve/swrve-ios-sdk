#import "DemoResourceManager.h"

/*
 * Base class for all demos
 */
@interface Demo : UIViewController

/*
 * This method is called after initialization by the main DemoFramework 
 * App Delegate.  Create any resources needed for the demo here.  The
 * DemoFramework will take care of syncing any changes because of AB tests.
 */
-(void) createResources:(DemoResourceManager *) resourceManager;

/*
 * This method is called after the demo's view has loaded and it has
 * been pushed onto the nav controller stack.
 */
-(void) onEnterDemo;

/*
 * This method is called after a demo has been popped off of the nav
 * controller stack.
 */
-(void) onExitDemo;

@end
