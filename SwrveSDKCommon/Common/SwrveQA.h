#import <Foundation/Foundation.h>
#import "SwrveRESTClient.h"
#import "SwrveQACampaignInfo.h"
#import "SwrveQAImagePersonalizationInfo.h"

@interface SwrveQA : NSObject

@property(nonatomic, readwrite) bool isQALogging;
@property (atomic) BOOL resetDeviceState;

+ (id)sharedInstance;
+ (void)updateQAUser:(NSDictionary *)jsonQa andSessionToken:(NSString *)sessionToken;
+ (void)wrappedEvent:(NSDictionary *)jsonDic;
+ (void)assetFailedToDownload:(NSString *)assetName
                  resolvedUrl:(NSString *)resolvedUrl
                       reason:(NSString *)reason;

+ (void)assetFailedToDisplay:(SwrveQAImagePersonalizationInfo *) qaImagePersonalizationInfo;

+ (void)embeddedPersonalizationFailed:(NSNumber *) campaignId
                            variantId:(NSNumber *) variantId
                       unresolvedData:(NSString *) unresolvedData
                               reason:(NSString *) reason;

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

@end
