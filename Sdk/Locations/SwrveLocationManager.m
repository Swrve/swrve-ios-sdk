#import "SwrveLocationManager.h"
#import "Swrve.h"

@implementation SwrveLocationManager

@synthesize locationCampaigns;

- (id)initWithDictionary:(NSDictionary *)locationCampaignsDict {

    if (self = [super init]) {
        [self updateWithDictionary:locationCampaignsDict];
    }

    return self;
}

- (void)updateWithDictionary:(NSDictionary *)locationCampaignsDict {

    locationCampaigns = [[NSMutableDictionary alloc] init];
    for (id locationCampaignId in locationCampaignsDict) {
        NSDictionary *dictionary = [locationCampaignsDict objectForKey:locationCampaignId];
        SwrveLocationCampaign *locationCampaign = [[SwrveLocationCampaign alloc] initCampaign:locationCampaignId withDictionary:dictionary];
        [locationCampaigns setObject:locationCampaign forKey:locationCampaignId];
    }
}

- (SwrveLocationCampaign *)getLocationCampaign:(NSString *)locationCampaignId {
    if (locationCampaigns != nil) {
        return [locationCampaigns objectForKey:locationCampaignId];
    }
    return nil;
}

@end
