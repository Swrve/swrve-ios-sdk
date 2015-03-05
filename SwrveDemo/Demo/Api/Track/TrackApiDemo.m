#import "DemoFramework.h"
#import "TrackApiDemo.h"
#import "UserSettings.h"

@implementation TrackApiDemo

@synthesize labelMemory;

-(id) init
{
    return [super initWithNibName:@"TrackApiDemo" bundle:nil];
}

-(void) onEnterDemo
{
    if([Swrve sharedInstance] != nil ) {
        return;
    }
    
    // Initialize Swrve.  We will give you your API key after you sign up with the
    // service.  You can find them here: http://dashboard.swrve.com/help/docs.
    
    // These keys are specific to your Swrve app.
    int appId = [UserSettings getAppId].intValue;
    NSString *apiKey = [UserSettings getAppApiKey];
    
    //
    // Add any custom configuration here
    //
    
    // To send events to the debug API set your user as a QA user
    
    // Take the user id override from the demo settings
    NSString* userOverride = [DemoFramework getDemoResourceManager].userIdOverride;
    // Create the SDK
    swrve = [Swrve sharedInstanceWithAppID:appId apiKey:apiKey userID:userOverride];
    
    // You can also initialise without a user
    // swrve = [Swrve sharedInstanceWithAppID:appId apiKey:apiKey];
}

-(void) onExitDemo
{
    // When you exit your app, or move it to the background, send the session
    // end event and send the cached events to Swrve.
    [swrve sendQueuedEvents];
    
    // Do not close the swrve object until after all events have been sent.
    //[swrve shutdown];
}


- (IBAction)onEvent:(id)sender
{
    #pragma unused(sender)
    // Send this event when you want to track user behavior that is specific to your
    // app.  The name of the event should describe the users action.  For example,
    //
    //      Gameplay.Leveled_Up
    //      Gameplay.Started_Level
    //      Gameplay.Player_Died
    //
    //      Tutorial.Started
    //      Tutorial.Completed_Step_1
    //      Tutorial.Completed_Step_2
    //      Tutorial.Finished
    //
    //      UI.Pause_Pressed
    //
    // Use '.'s in the event name to indicate a hierarchy.  Only use letters, numbers
    // dashes, underscores and dots.  DO NOT USE SPACES.
    [swrve event: @"Swrve.Demo.Gameplay.Player_Died"];
    
    // Use event payloads if you want to add more context to the event and understand
    // why the user is doing what they are doing.  Event payloads are key / value pairs,
    // for example,
    //
    //      Gameplay.Leveled_Up         { "player_level" : "10", "last_enemy_killed" : "zombie" }
    //      Gameplay.Started_Level      { "level_name" : "no_mercy" }
    //      Gameplay.Player_Died        { "enemy_name" : "slug", "player_level" : "5" }
    //
    //      Tutorial.Started
    //      Tutorial.Completed_Step_1   { "sec_since_last_step" : "5" }
    //      Tutorial.Completed_Step_2   { "sec_since_last_step" : "5" }
    //      Tutorial.Finished
    //
    //      UI.Pause_Pressed            { "button_name" : "paused" }
    //
    // Not all events need payloads.  Only use them when additional detail will help you
    // run more effective AB tests.
    //
    // Finally, event payloads should NOT represent user state.  Use the swrve_user_update
    // function for that.
    //
    // See http://dashboard.swrve.com/help/docs/events_api#events for more
    // information.
    [swrve event:@"Swrve.Demo.Gameplay.Player_Died"
         payload: [NSDictionary dictionaryWithObjectsAndKeys:
                   @"slug", @"enemy_name",
                   @"5",@"player_level",
                   nil]];
}

- (IBAction)onUserUpdate:(id)sender
{
    #pragma unused(sender)
    // Send this event at the beginning and end of each session to track user
    // attributes.  We will keep track of these attributes, and how they change
    // on our servers.  After we receive them you can build segments to target
    // specific types of users, say spenders or level 10, with Swrve Talk
    // messages and AB tests.
    //
    // See http://dashboard.swrve.com/help/docs/events_api#user for more
    // information.
    [swrve userUpdate:[NSDictionary dictionaryWithObjectsAndKeys:
                       [NSNumber numberWithInt:100], @"health",
                       [NSNumber numberWithInt:20], @"gold",
                       nil]];
}
                
- (IBAction)onCurrencyGiven:(id)sender
{
    #pragma unused(sender)
    // Send this event whenever your app gives users virtual currency.  This
    // include currency given at start up, daily rewards, killing enemys, 
    // winning spins, etc.  You do not need to send this event when users
    // purchase currency - the swrve_iap_with_rewards event will track this.
    //
    // See http://dashboard.swrve.com/help/docs/events_api#currency-given for more
    // information.
    [swrve currencyGiven:@"gold" givenAmount:20];
}

- (IBAction)onPurchase:(id)sender
{
    #pragma unused(sender)
    // Send this event when the user purchases a virtual item for virtual
    // currency.  Before you can send this event you must have the virtual
    // currency configured in your app.  Add the currency to the settings page
    // for you app here http://dashboard.swrve.com/apps/<app number>/settings
    //
    // See http://dashboard.swrve.com/help/docs/events_api#purchase for more
    // information.
    [swrve purchaseItem:@"someItem" currency:@"gold" cost:20 quantity:1];
}

- (IBAction)onFlushEvents:(id)sender
{
    #pragma unused(sender)
    // Call this function to send events to Swrve.  You should call this
    // function at least once every session.  We recommend you call it in
    // UIApplicationDelegate:applicationWillResignActive right after calling
    // swrve_session_end.
    //
    [swrve sendQueuedEvents];
}

- (IBAction)onSaveEvents:(id)sender
{
    #pragma unused(sender)
    // Call this function periodically to reduce the amount of runtime memory
    // the Swrve SDK consumes.  By calling this function you flush the runtime
    // event queue to disk.  Each time you save events to disk they accumulate
    // and are send to us when you call swrve_send_queued_events.
    [swrve saveEventsToDisk];
}


@end
