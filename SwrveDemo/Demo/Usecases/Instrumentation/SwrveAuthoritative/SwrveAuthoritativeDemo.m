#import "SwrveAuthoritativeDemo.h"
#import "UserSettings.h"

@implementation SwrveAuthoritativeDemo
{
    NSDate* startTime;
    NSDate* stopTime;
}

@synthesize timeToLoadLabel;

-(id) init
{
    return [super initWithNibName:@"SwrveAuthoritativeDemo" bundle:nil];
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
    // Next download additional assets from Swrve.  Calling applyAllResourcesAsync
    // will download all resources in your Swrve Dashboard (with AB test diffs
    // applied).
    //
    // If the resource manager cannot reach Swrve, the last known good resource
    // data is applied to local data.  If there is no last known good data
    // no changes are made.  If Swrve is reached the local data store is
    // overriden with the data in the Swrve dashboard.
    //
    // This approach is slower but allows you to use the Swrve Dashboard to add
    // or remove data to or from your app after release.  That said it also
    // makes you more dependent on the Swrve service.  If the Swrve service goes
    // down the app will rely on the last known good configuration.
    //
    [resourceManager applyAllResourcesAsync:swrve];
    
    //
    // In general you would let your app load as normal here.  However if you
    // need resources before you can continue you can implement the
    // DemoResourceManagerDelegate delegate and be notified of when the AB
    // test changes have been applied.  See the applyAllResourcesAsyncComplete
    // function below for an example.
    //
    
    startTime = [NSDate date];
}

-(void) applyAllResourcesAsyncComplete
{
    //
    // At this point AB test changes have been applied and you can use the
    // resources from the manager to control you app.
    //
    // However, if you're syncing with the remove repository you need to be
    // very careful.  Objects can be added and removed so you need to add extra
    // logic to handle these cases.
    //
    
    DemoResource* resource = [resourceManager lookupResource:@"resource_a"];
    if( resource == nil )
    {
        NSLog(@"Local resource removed because it didn't exist in remote repository.");
    }
    
    stopTime = [NSDate date];
    double interval = [stopTime timeIntervalSince1970] - [startTime timeIntervalSince1970];
    self.timeToLoadLabel.text = [NSString stringWithFormat:@"All data downloaded and applied in %.2f seconds.", interval];
    
    [UIView beginAnimations:nil context:NULL];
    self.timeToLoadLabel.alpha = 1.0;
    [UIView setAnimationDuration:0.5];
    [UIView commitAnimations];
    
}

@end

