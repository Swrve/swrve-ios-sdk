#import "SwrveLocationCampaign.h"

@implementation SwrveLocationCampaign

@synthesize locationCampaignId = _locationCampaignId;
@synthesize startDate;
@synthesize endDate;
@synthesize version;
@synthesize message;

- (id)initCampaign:(NSString *)locationCampaignId withDictionary:(NSDictionary *)dictionary {

    if (self = [super init]) {
        _locationCampaignId = locationCampaignId;
        startDate = [self convertToNSDate:[dictionary objectForKey:@"start"]];
        endDate = [self convertToNSDate:[dictionary objectForKey:@"end"]];
        version = [dictionary objectForKey:@"version"];
        message = [[SwrveLocationMessage alloc] initWithDictionary:dictionary[@"message"]];
    };

    return self;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.locationCampaignId=%@", self.locationCampaignId];
    [description appendFormat:@", self.dateStart=%@", self.startDate];
    [description appendFormat:@", self.dateEnd=%@", self.endDate];
    [description appendFormat:@", self.version=%@", self.version];
    [description appendFormat:@", self.message=%@", self.message];
    [description appendString:@">"];
    return description;
}

- (NSDate *)convertToNSDate:(NSNumber *)date {
    if (date == (id)[NSNull null]) {
        return nil;
    } else {
        double seconds = [date doubleValue] / 1000.0;
        return [NSDate dateWithTimeIntervalSince1970:seconds];
    }
}

@end
