#import "TalkApiDemo.h"
#import "SwrveMessage.h"
#import "DemoFramework.h"
#import "UserSettings.h"

@implementation TalkApiDemo

-(id) init
{
    return [super initWithNibName:@"TalkApiDemo" bundle:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

-(void) onEnterDemo
{
    // Initialize Swrve.  We will give you your API key after you sign up with the
    // service.  You can find them here: http://dashboard.swrve.com/help/docs.
    
    // These keys are specific to your Swrve app.
    int appId = [UserSettings getAppId].intValue;
    NSString *apiKey = [UserSettings getAppApiKey];
    // Take the user id override from the demo settings
    NSString* userOverride = [DemoFramework getDemoResourceManager].userIdOverride;
    swrve = [[Swrve alloc]initWithAppID:appId apiKey:apiKey userID:userOverride];
    
    // You can also initialise without a user
    // swrve = [[Swrve alloc]initWithAppID:appId apiKey:apiKey];
}

-(void) onExitDemo
{
    // When you exit your app, or move it to the background, send the session
    // end event and send the cached events to Swrve.
    [swrve sendQueuedEvents];
    
    // Do not close the swrve object until after all events have been sent.
    //[swrveTrack shutdown];
}

- (IBAction)onNotificationMessage:(id)sender
{
    #pragma unused(sender)
    [swrve event:@"Swrve.Demo.OfferMessage"];
}

@end
