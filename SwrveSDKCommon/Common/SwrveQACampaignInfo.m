#import "SwrveQACampaignInfo.h"

@implementation SwrveQACampaignInfo

@synthesize campaignID;
@synthesize variantID;
@synthesize type;
@synthesize displayed;
@synthesize reason;

- (id) initWithCampaignID:(NSUInteger)campaignId
            variantID:(NSUInteger)variantId
                 type:(SwrveCampaignType)campType
            displayed:(BOOL) isDisplayed
               reason:(NSString *)logReason {
    self = [super init];
    if (self != nil) {
        self.campaignID = campaignId;
        self.variantID = variantId;
        self.type = campType;
        self.displayed = isDisplayed;
        self.reason = logReason;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[SwrveQACampaignInfo class]]) {
        return NO;
    } else {
        SwrveQACampaignInfo *campaignObject = (SwrveQACampaignInfo *)object;
        return(self.campaignID  == campaignObject.campaignID &&
               self.variantID == campaignObject.variantID &&
               self.type == campaignObject.type &&
               self.isDisplayed == campaignObject.isDisplayed &&
               [self.reason isEqualToString:campaignObject.reason]);
    }
}

@end
