#import <Foundation/Foundation.h>

@class Swrve;

static NSString* SWRVE_AD_CAMPAIGN_URL     =   @"api/1/ad_journey_campaign";
static NSString* SWRVE_AD_INSTALL          =   @"install";
static NSString* SWRVE_AD_REENGAGE         =   @"reengage";
static NSString* SWRVE_AD_SOURCE           =   @"ad_source";
static NSString* SWRVE_AD_CAMPAIGN         =   @"ad_campaign";
static NSString* SWRVE_AD_CONTENT          =   @"ad_content";

@interface SwrveDeeplinkManager : NSObject

- (instancetype)initWithSwrve:(Swrve *)sdk;
- (void)handleDeeplink:(NSURL *)url;
- (void)handleDeferredDeeplink:(NSURL *)url;
+ (BOOL)isSwrveDeeplink:(NSURL *)url;
- (void)handleNotificationToCampaign:(NSString *)campaignId;
- (void)fetchNotificationCampaigns:(NSMutableSet *)campaignIds;

@property (atomic) NSString *actionType;

@end
