#include <Foundation/Foundation.h>
#import "SwrveLocationCampaign.h"

@interface SwrveLocationManager : NSObject

@property(atomic) NSMutableDictionary *locationCampaigns;

- (id)initWithDictionary:(NSDictionary *)locationCampaignsDict;

- (void)updateWithDictionary:(NSDictionary *)json;

- (SwrveLocationCampaign *)getLocationCampaign:(NSString *)locationCampaignId;

@end
