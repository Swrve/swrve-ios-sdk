#import "SwrveQAImagePersonalizationInfo.h"

@implementation SwrveQAImagePersonalizationInfo

@synthesize campaignID;
@synthesize variantID;
@synthesize assetName;
@synthesize hasFallback;
@synthesize unresolvedUrl;
@synthesize resolvedUrl;
@synthesize reason;

- (id) initWithCampaign:(NSUInteger)campaignId
              variantID:(NSUInteger)variantId
              assetName:(NSString *)aName
            hasFallback:(BOOL)fallback
          unresolvedUrl:(NSString *)unresolvedURL
            resolvedUrl:(NSString *)resolvedURL
                 reason:(NSString *)logReason {
    
    self = [super init];
    
    if (self != nil) {
        self.campaignID = campaignId;
        self.variantID = variantId;
        self.assetName = aName;
        self.hasFallback = fallback;
        self.unresolvedUrl = unresolvedURL;
        self.resolvedUrl = resolvedURL;
        self.reason = logReason;
    }
    return self;
}

@end
