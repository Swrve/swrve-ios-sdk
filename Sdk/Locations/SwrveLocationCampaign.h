#import <Foundation/Foundation.h>
#import "SwrveLocationMessage.h"

@interface SwrveLocationCampaign : NSObject

@property(atomic, strong) NSString *locationCampaignId;
@property(atomic, strong) NSDate *startDate;
@property(atomic, strong) NSDate *endDate;
@property(atomic, strong) NSNumber *version;
@property(atomic, strong) SwrveLocationMessage *message;

- (id)initCampaign:(NSNumber *)campaignId withDictionary:(NSDictionary *)dictionary;

- (NSString *)description;

@end
