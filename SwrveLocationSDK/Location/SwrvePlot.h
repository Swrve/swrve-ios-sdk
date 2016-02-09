#import "Plot.h"
#import <Foundation/Foundation.h>

static int const SWRVE_LOCATION_SDK_VERSION      = 1;
static NSString* const PROP_LOCATION_SDK_VERSION = @"swrve.location_sdk";
static NSString* const PROP_PLOT_VERSION         = @"swrve.plot_sdk";

@class SwrveLocationManager;

@interface SwrvePlot : NSObject

/**
 * Before you can make use of the other functionality within Plot, you have to call an initialization method (this one is preferred). It will read the configuration from
 * the config file (plotconfig.json), please make sure this file is defined. Normally you want to call this method inside -(BOOL)application:didFinishLaunchingWithOptions:.
 * When the app is launched because the user tapped on a notification, then that notification will be opened.
 * @param launchOptions Specific options used on launch, can be used to pass options as user.
 * @param delegate Plot delegate used.
 */
+ (void)initializeWithLaunchOptions:(NSDictionary *)launchOptions delegate:(id <PlotDelegate>)delegate;


/**
 * Used for Location Campaigns and is called when device crosses a geofence.
 * @param filterNotifications Contains the swrve location campaign details for which this geofence is part of.
 * @returns the notification(s) sent. May be empty if none sent.
 */
+ (NSMutableArray *)filterLocationCampaigns:(PlotFilterNotifications *)filterNotifications;

/**
 * Used for Location Campaigns and is called when user taps on notification.
 * @param localNotification The notification that the user engaged with.
 * @param locationMessageJson The variant message json that the user engaged with.
 * @returns
 */
+ (int)engageLocationCampaign:(UILocalNotification *)localNotification withData:(NSString *)locationMessageJson;

@end
