#import "Demo.h"

#import "Swrve.h"
#import "SwrveMessageController.h"

/*
 * A demo of Swrve's in-app messaging API.
 */
@interface TalkApiDemo : Demo {
    
    Swrve* swrve;
}

- (IBAction)onNotificationMessage:(id)sender;

@end
