#import "SwrveQAImagePersonalizationInfo.h"

@implementation SwrveQAImagePersonalizationInfo

@synthesize campaignID;
@synthesize variantID;
@synthesize assetName;
@synthesize hasFallback;
@synthesize unresolvedUrl;
@synthesize resolvedUrl;
@synthesize reason;

- (id)initWithCampaign:(NSUInteger)campaignId
             variantID:(NSUInteger)variantId
           hasFallback:(BOOL)fallback
         unresolvedUrl:(NSString *)unresolvedURL {

    self = [super init];

    if (self != nil) {
        self.campaignID = campaignId;
        self.variantID = variantId;
        self.hasFallback = fallback;
        self.unresolvedUrl = unresolvedURL;
    }
    return self;
}

@end
