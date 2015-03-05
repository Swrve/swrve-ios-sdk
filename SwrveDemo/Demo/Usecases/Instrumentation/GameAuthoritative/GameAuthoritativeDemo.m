#import "GameAuthoritativeDemo.h"
#import "UserSettings.h"

@implementation GameAuthoritativeDemo
{
    NSDate* startTime;
    NSDate* stopTime;
}

@synthesize timeToLoadLabel;

-(id) init
{
    return [super initWithNibName:@"GameAuthoritativeDemo" bundle:nil];
}

-(void) onEnterDemo
{
    // Initialize Swrve Tracking SDK.
    int appId = [UserSettings getAppId].intValue;
    NSString *apiKey = [UserSettings getAppApiKey];
    // Take the user id override from the demo settings
    NSString* userOverride = [DemoFramework getDemoResourceManager].userIdOverride;
    swrve = [[Swrve alloc]initWithAppID:appId apiKey:apiKey userID:userOverride];
    
    //
    // First define the resources you want to override with Swrve.  Store these
    // in a central location and give them reasonable defaults.
    //
    DemoResource* resourceA = [[DemoResource alloc] init:@"resource_a"
                                            withAttributes:@{ @"attribute_a" : @"A",
                                                              @"attribute_b" : @"B",
                                                              @"attribute_c" : @"C",
                                                              @"attribute_d" : @"D"}];
    DemoResource* resourceB = [[DemoResource alloc] init:@"resource_b"
                                            withAttributes:@{ @"attribute_a" : @"A",
                                                              @"attribute_b" : @"B",
                                                              @"attribute_c" : @"C",
                                                              @"attribute_d" : @"D"}];
    DemoResource* resourceC = [[DemoResource alloc] init:@"resource_c"
                                            withAttributes:@{ @"attribute_a" : @"A",
                                                              @"attribute_b" : @"B",
                                                              @"attribute_c" : @"C",
                                                              @"attribute_d" : @"D"}];
    resourceManager = [[DemoResourceManager alloc] init];
    [resourceManager addResource:resourceA];
    [resourceManager addResource:resourceB];
    [resourceManager addResource:resourceC];
    resourceManager.delegate = self;
    
    //
    // Next apply changes from running AB tests.  This is an asynchronous call
    // that returns quickly (500ms or less).
    //
    // If the resource manager cannot reach Swrve, the last known good AB test
    // diffs are applied to local data.  If there is no last known good diff
    // no changes are made.  If Swrve is reached only from active AB tests are
    // applied.
    //
    // This approach is fast and reliable since only the minimal changes are
    // being sent and applied locally to the game.
    //
    // In the case where the app received and applied AB test changes but is now
    // offline, the manager will keep the user's experience consisent and will
    // apply the AB test changes it received last from Swrve's servers.
    //
    [resourceManager applyAbTestDifferencesAsync:swrve];
    
    //
    // In general you would let your app load as normal here.  However if you
    // need resources before you can continue you can implement the
    // DemoResourceManagerDelegate delegate and be notified of when the AB
    // test changes have been applied.  See the applyAbTestDifferencesAsyncIsComplete
    // function below for an example.
    //
    
    startTime = [NSDate date];
}

-(void) applyAbTestDifferencesAsyncIsComplete
{
    //
    // At this point AB test changes have been applied and you can use the
    // resources from the manager to control you app.
    //
    DemoResource* resource = [resourceManager lookupResource:@"resource_a"];
    NSString* attribute = [resource getAttributeAsString:@"attribute_a"];
    NSLog(@"Attribute value is %@", attribute);
    
    stopTime = [NSDate date];
    double interval = [stopTime timeIntervalSince1970] - [startTime timeIntervalSince1970];
    self.timeToLoadLabel.text = [NSString stringWithFormat:@"AB tests downloaded and applied ins %.2f seconds.", interval];
    
    [UIView beginAnimations:nil context:NULL];
    self.timeToLoadLabel.alpha = 1.0;
    [UIView setAnimationDuration:0.5];
    [UIView commitAnimations];
}

@end

