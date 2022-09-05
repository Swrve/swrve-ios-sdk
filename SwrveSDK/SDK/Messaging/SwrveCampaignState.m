#import "SwrveCampaignState.h"

@implementation SwrveCampaignState

@synthesize campaignID;
@synthesize impressions;
@synthesize status;
@synthesize showMsgsAfterDelay;
@synthesize downloadDate;

- (id)initWithID:(NSUInteger)ID date:(NSDate *)date {
    if (self = [super init]) {
        self.campaignID = ID;
        self.status = SWRVE_CAMPAIGN_STATUS_UNSEEN;
        self.downloadDate = date;
    }
    return self;
}

- (id)initWithJSON:(NSDictionary *)data {
    if (self = [super init]) {
        NSNumber *idJson = [data objectForKey:@"ID"];
        if (idJson != nil) {
            self.campaignID = idJson.unsignedIntegerValue;
        }
        NSNumber *impressionsJson = [data objectForKey:@"impressions"];
        if (impressionsJson != nil) {
            self.impressions = impressionsJson.unsignedIntegerValue;
        }
        NSNumber *statusJson = [data objectForKey:@"status"];
        if (statusJson != nil) {
            self.status = (SwrveCampaignStatus) statusJson.unsignedIntegerValue;
        }

        NSDate *date = [data objectForKey:@"downloadDate"];
        if (date == nil) {
            self.downloadDate = [NSDate date];
        } else {
            self.downloadDate = date;
        }
    }

    return self;
}

- (NSDictionary *)asDictionary {
    NSMutableDictionary *state = [NSMutableDictionary new];
    [state setValue:[NSNumber numberWithUnsignedInteger:self.campaignID] forKey:@"ID"];
    [state setValue:[NSNumber numberWithUnsignedInteger:self.impressions] forKey:@"impressions"];
    [state setValue:[NSNumber numberWithUnsignedInteger:self.status] forKey:@"status"];
    if (self.downloadDate != nil) {
        [state setObject:self.downloadDate forKey:@"downloadDate"];
    }
    return state;
}

@end
