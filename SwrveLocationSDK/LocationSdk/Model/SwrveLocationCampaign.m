#import "SwrveLocationCampaign.h"

@implementation SwrveLocationCampaign

@synthesize locationCampaignId = _locationCampaignId;
@synthesize version;
@synthesize message;

- (id)initCampaign:(NSString *)locationCampaignId withDictionary:(NSDictionary *)dictionary {

    if (self = [super init]) {
        _locationCampaignId = locationCampaignId;
        version = [dictionary objectForKey:@"version"];
        message = [[SwrveLocationMessage alloc] initWithDictionary:dictionary[@"message"]];
    };

    return self;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.locationCampaignId=%@", self.locationCampaignId];
    [description appendFormat:@", self.version=%@", self.version];
    [description appendFormat:@", self.message=%@", self.message];
    [description appendString:@">"];
    return description;
}

@end
