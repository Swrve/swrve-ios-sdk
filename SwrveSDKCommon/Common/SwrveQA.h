#import <Foundation/Foundation.h>
#import "SwrveRESTClient.h"
#import "SwrveQACampaignInfo.h"

@interface SwrveQA : NSObject

@property(nonatomic, readwrite) bool isQALogging;
@property (atomic) BOOL resetDeviceState;

+ (id)sharedInstance;
+ (void)updateQAUser:(NSDictionary *)jsonQa andSessionToken:(NSString *)sessionToken;

+ (void)wrappedEvent:(NSDictionary *)jsonDic;
+ (void)campaignsDownloaded:(NSArray *)arrayWithCampaigns;
+ (void)campaignButtonClicked:(NSNumber *)campaignId
                    variantId:(NSNumber *)variantId
                   buttonName:(NSString *)buttonName
                   actionType:(NSString *)actionType
                  actionValue:(NSString *)actionValue;

+ (void)messageCampaignTriggered:(NSString *)eventName
                     eventPayload:(NSDictionary *)eventPayload
                        displayed:(BOOL)displayed
                 campaignInfoDict:(NSArray <SwrveQACampaignInfo*> *)qaCampaignInfoArray;

+ (void)conversationCampaignTriggered:(NSString *)eventName
                          eventPayload:(NSDictionary *)eventPayload
                             displayed:(BOOL)displayed
                      campaignInfoDict:(NSArray <SwrveQACampaignInfo*> *)qaCampaignInfoArray;

+ (void)conversationCampaignTriggeredNoDisplay:(NSString *)eventName
                                  eventPayload:(NSDictionary *)eventPayload;

+ (void)campaignTriggered:(NSString *)eventName
              eventPayload:(NSDictionary *)eventPayload
                 displayed:(BOOL)displayed
                    reason:(NSString *)reason
              campaignInfo:(NSArray<SwrveQACampaignInfo*> *)qaCampaignInfoArray;

+ (void)geoCampaignTriggered:(NSArray *)campaigns
              fromGeoPlaceId:(NSString *)geoplaceId
               andGeofenceId:(NSString *)geofenceId
               andActionType:(NSString *)actionType;

+ (void)geoCampaignsDownloaded:(NSArray *)campaigns
                fromGeoPlaceId:(NSString *)geoplaceId
                 andGeofenceId:(NSString *)geofenceId
                 andActionType:(NSString *)actionType;

@end
