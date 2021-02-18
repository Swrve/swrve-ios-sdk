#import "TestableDummySwrve.h"
#import "SwrvePrivateAccess.h"

@implementation TestableDummySwrve

+(TestableDummySwrve*) sharedInstanceWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey config:(SwrveConfig*)swrveConfig {
#pragma unused(swrveConfig)
    TestableDummySwrve* instance = [TestableDummySwrve alloc];
    [SwrveSDK resetSwrveSharedInstance];
    [SwrveSDK addSharedInstance:(Swrve*)instance];
    
    SwrveConfig *newConfig = [[SwrveConfig alloc] init];
    return [instance initWithAppID:swrveAppID apiKey:swrveAPIKey config:newConfig];
}

@end
