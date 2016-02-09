#include <Foundation/Foundation.h>
#import "Plot.h"
#import "SwrveLocationCampaign.h"
#import "SwrveLocationManager.h"

@interface SwrvePlotManager : NSObject

@property(atomic) NSMutableDictionary *locationCampaigns;

- (NSMutableArray*)filterLocationCampaigns:(PlotFilterNotifications *)filterNotifications;

- (int) engageLocationCampaign:(UILocalNotification*)localNotification withData:(NSString*)locationMessageJson;

@end
