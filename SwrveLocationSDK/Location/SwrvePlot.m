#import "SwrvePlot.h"
#import "SwrveCommon.h"
#import "SwrvePlotManager.h"

@implementation SwrvePlot

+ (void)initializeWithLaunchOptions:(NSDictionary *)launchOptions delegate:(id <PlotDelegate>)delegate {

    NSString *locationSDKVersion = [NSString stringWithFormat:@"%d", SWRVE_LOCATION_SDK_VERSION];
    [[SwrveCommon getSwrveCommon] setLocationVersion:locationSDKVersion];

    NSDictionary *dictionary = [[NSMutableDictionary alloc] init];
    [dictionary setValue:locationSDKVersion forKey:PROP_LOCATION_SDK_VERSION]; // this is the version of this location sdk
    [dictionary setValue:[Plot version] forKey:PROP_PLOT_VERSION]; // this is the plot sdk version
    [[SwrveCommon getSwrveCommon] userUpdate:dictionary];

    [Plot initializeWithLaunchOptions:launchOptions delegate:delegate];
    [Plot setIntegerSegmentationProperty:SWRVE_LOCATION_SDK_VERSION forKey:PROP_LOCATION_SDK_VERSION];
}

+ (NSMutableArray *)filterLocationCampaigns:(PlotFilterNotifications *)filterNotifications {
    return [[[SwrvePlotManager alloc] init] filterLocationCampaigns:filterNotifications];
}

+ (int)engageLocationCampaign:(UILocalNotification *)localNotification withData:(NSString *)locationMessageJson {
    return [[[SwrvePlotManager alloc] init] engageLocationCampaign:localNotification withData:locationMessageJson];
}

@end
