#import "SwrveQA.h"
#import "SwrveCommon.h"
#import "SwrveLocalStorage.h"
#import "SwrveQAEventsQueueManager.h"
#import "SwrveQAImagePersonalizationInfo.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface SwrveQA ()

@property(nonatomic) SwrveQAEventsQueueManager *queueManager;

@end

@implementation SwrveQA

@synthesize queueManager = _queueManager;

#pragma mark Properties

@synthesize isQALogging = _isQALogging;
@synthesize resetDeviceState = _resetDeviceState;

#pragma mark Init

static SwrveQA *shared = nil;
static dispatch_once_t onceToken;

+ (id)sharedInstance {
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
        // Start with previously cached user by passing nill.
        [shared updateQAUser:nil andSessionToken:[[SwrveCommon sharedInstance] sessionToken]];
    });

    return shared;
}

#pragma mark Helpers

+ (void)updateQAUser:(NSDictionary *)jsonQa andSessionToken:(NSString *)sessionToken {
    [[SwrveQA sharedInstance] updateQAUser:jsonQa andSessionToken:sessionToken];
}

// Passing "jsonQa" as nill, will try load last valid QA user info from cache or start as non QA user.
- (void)updateQAUser:(NSDictionary *)jsonQa andSessionToken:(NSString *)sessionToken {
    if (jsonQa == nil) {
        NSDictionary *cachedQA = [SwrveLocalStorage qaUser];
        if (cachedQA != nil) {
            self.isQALogging = [[cachedQA objectForKey:@"logging"] boolValue];
            self.resetDeviceState = [[cachedQA objectForKey:@"reset_device_state"] boolValue];
        } else {
            self.isQALogging = NO;
            self.resetDeviceState = NO;
        }
    } else {
        self.isQALogging = [[jsonQa objectForKey:@"logging"] boolValue];
        self.resetDeviceState = [[jsonQa objectForKey:@"reset_device_state"] boolValue];
        [SwrveLocalStorage saveQaUser:jsonQa];
    }

    // When we update our current user as QA we also flush the current events if are any available.
    @synchronized (self.queueManager) {
        if (self.queueManager != nil) {
            [self.queueManager flushEvents];
        }
        if (self.isQALogging) {
            self.queueManager = [[SwrveQAEventsQueueManager alloc] initWithSessionToken:sessionToken];
        }
    }
}

#pragma mark SDK Logs

+ (void)wrappedEvent:(NSDictionary *) jsonDic {
    SwrveQA *swrveQA = [SwrveQA sharedInstance];
    if (!swrveQA || ![swrveQA isQALogging] || jsonDic == nil) {
        return;
    }
    NSMutableDictionary *qaLogEvent = [SwrveEvents qalogWrappedEvent:jsonDic];
    [swrveQA.queueManager queueEvent:qaLogEvent];
}

+ (void)assetFailedToDownload:(NSString *)assetName
                  resolvedUrl:(NSString *)resolvedUrl
                       reason:(NSString *)reason {
    SwrveQA *swrveQA = [SwrveQA sharedInstance];
    if (!swrveQA || ![swrveQA isQALogging] || assetName == nil || resolvedUrl == nil) {
        return;
    }
    
    NSMutableDictionary *qaAssetDownloadFailedInfo = [NSMutableDictionary new];
    [qaAssetDownloadFailedInfo setValue:assetName forKey:@"asset_name"];
    [qaAssetDownloadFailedInfo setValue:resolvedUrl forKey:@"image_url"];
    [qaAssetDownloadFailedInfo setValue:reason forKey:@"reason"];
    
    NSMutableDictionary *qaLogEvent = [SwrveEvents qaLogEvent:qaAssetDownloadFailedInfo logType:@"asset-failed-to-download"];
    [swrveQA.queueManager queueEvent:qaLogEvent];
}

+ (void)assetFailedToDisplay:(SwrveQAImagePersonalizationInfo *) qaImagePersonalizationInfo {
    SwrveQA *swrveQA = [SwrveQA sharedInstance];
    if (!swrveQA || ![swrveQA isQALogging] || qaImagePersonalizationInfo == nil) {
        return;
    }
    
    NSMutableDictionary *qaAssetDisplayFailedInfo = [NSMutableDictionary new];
    [qaAssetDisplayFailedInfo setValue:[NSNumber numberWithUnsignedInteger:qaImagePersonalizationInfo.campaignID] forKey:@"campaign_id"];
    [qaAssetDisplayFailedInfo setValue:[NSNumber numberWithUnsignedInteger:qaImagePersonalizationInfo.variantID] forKey:@"variant_id"];
    [qaAssetDisplayFailedInfo setValue:qaImagePersonalizationInfo.unresolvedUrl forKey:@"unresolved_url"];
    [qaAssetDisplayFailedInfo setValue:[NSNumber numberWithBool:qaImagePersonalizationInfo.hasFallback] forKey:@"has_fallback"];
    [qaAssetDisplayFailedInfo setValue:qaImagePersonalizationInfo.reason forKey:@"reason"];
    
    if(qaImagePersonalizationInfo.assetName != nil && [qaImagePersonalizationInfo.assetName length] > 1) {
        [qaAssetDisplayFailedInfo setValue:qaImagePersonalizationInfo.assetName forKey:@"asset_name"];
    }
    
    if(qaImagePersonalizationInfo.resolvedUrl != nil && [qaImagePersonalizationInfo.resolvedUrl length] > 1) {
        [qaAssetDisplayFailedInfo setValue:qaImagePersonalizationInfo.resolvedUrl forKey:@"image_url"];
    }

    NSMutableDictionary *qaLogEvent = [SwrveEvents qaLogEvent:qaAssetDisplayFailedInfo logType:@"asset-failed-to-display"];
    [swrveQA.queueManager queueEvent:qaLogEvent];
}

+ (void)embeddedPersonalizationFailed:(NSNumber *) campaignId
                            variantId:(NSNumber *) variantId
                       unresolvedData:(NSString *) unresolvedData
                               reason:(NSString *) reason {
    
    SwrveQA *swrveQA = [SwrveQA sharedInstance];
    if (!swrveQA || ![swrveQA isQALogging] || campaignId == nil || variantId == nil || unresolvedData == nil || reason == nil) {
        return;
    }
    
    NSMutableDictionary *qaAssetDisplayFailedInfo = [NSMutableDictionary new];
    [qaAssetDisplayFailedInfo setValue:campaignId forKey:@"campaign_id"];
    [qaAssetDisplayFailedInfo setValue:variantId forKey:@"variant_id"];
    [qaAssetDisplayFailedInfo setValue:unresolvedData forKey:@"unresolved_data"];
    [qaAssetDisplayFailedInfo setValue:reason forKey:@"reason"];
    
    NSMutableDictionary *qaLogEvent = [SwrveEvents qaLogEvent:qaAssetDisplayFailedInfo logType:@"embedded-personalization-failed"];
    [swrveQA.queueManager queueEvent:qaLogEvent];
}

+ (void)campaignsDownloaded:(NSArray *)campaigns {
    SwrveQA *swrveQA = [SwrveQA sharedInstance];
    if (!swrveQA || ![swrveQA isQALogging] || campaigns == nil) {
        return;
    }

    NSMutableDictionary *qaLogEvent = [SwrveEvents qalogCampaignsDownloaded:campaigns];
    [swrveQA.queueManager queueEvent:qaLogEvent];
}

+ (void)campaignButtonClicked:(NSNumber *)campaignId
                    variantId:(NSNumber *)variantId
                   buttonName:(NSString *)buttonName
                   actionType:(NSString *)actionType
                  actionValue:(NSString *)actionValue {
    SwrveQA *swrveQA = [SwrveQA sharedInstance];
    if (!swrveQA || ![swrveQA isQALogging] || campaignId == nil || variantId == nil) {
        return;
    }
    
    NSMutableDictionary *qaCampaignButtonInfo = [NSMutableDictionary new];
    [qaCampaignButtonInfo setValue:campaignId forKey:@"campaign_id"];
    [qaCampaignButtonInfo setValue:variantId forKey:@"variant_id"];
    [qaCampaignButtonInfo setValue:buttonName forKey:@"button_name"];
    [qaCampaignButtonInfo setValue:actionType forKey:@"action_type"];
    
    if(actionValue != nil && [actionValue length] > 1) {
        [qaCampaignButtonInfo setValue:actionValue forKey:@"action_value"];
    }

    NSMutableDictionary *qaLogEvent = [SwrveEvents qalogCampaignButtonClicked:qaCampaignButtonInfo];
    [swrveQA.queueManager queueEvent:qaLogEvent];
}



+ (void) messageCampaignTriggered:(NSString *)eventName
                     eventPayload:(NSDictionary *)eventPayload
                        displayed:(BOOL)displayed
                     campaignInfoDict:(NSArray <SwrveQACampaignInfo *> *)qaCampaignInfoArray
{
    SwrveQA *swrveQA = [SwrveQA sharedInstance];
    if (!swrveQA || ![swrveQA isQALogging] || eventName == nil ) {
        return;
    }
    
    NSString *noCampaignTriggeredReason = displayed ? @"" : @"The loaded campaigns returned no message";
    
    [self campaignTriggered:eventName eventPayload:eventPayload displayed:displayed reason:noCampaignTriggeredReason campaignInfo:qaCampaignInfoArray];
}

+ (void)conversationCampaignTriggered:(NSString *)eventName
                         eventPayload:(NSDictionary *)eventPayload
                            displayed:(BOOL)displayed
                     campaignInfoDict:(NSArray <SwrveQACampaignInfo *> *)qaCampaignInfoArray {
    SwrveQA *swrveQA = [SwrveQA sharedInstance];
    if (!swrveQA || ![swrveQA isQALogging] || eventName == nil) {
        return;
    }

    NSString *noCampaignTriggeredReason = displayed ? @"" : @"The loaded campaigns returned no conversations";

    [self campaignTriggered:eventName eventPayload:eventPayload displayed:displayed reason:noCampaignTriggeredReason campaignInfo:qaCampaignInfoArray];
}

+ (void)conversationCampaignTriggeredNoDisplay:(NSString *)eventName
                                  eventPayload:(NSDictionary *)eventPayload {
    SwrveQA *swrveQA = [SwrveQA sharedInstance];
    if (!swrveQA || ![swrveQA isQALogging] || eventName == nil) {
        return;
    }

    NSString *noCampaignTriggeredReason = @"No Conversation triggered because In App Message displayed";
    [self campaignTriggered:eventName eventPayload:eventPayload displayed:false reason:noCampaignTriggeredReason campaignInfo:nil];
}

+ (void) campaignTriggered:(NSString *)eventName
              eventPayload:(NSDictionary *)eventPayload
                 displayed:(BOOL)displayed
                    reason:(NSString *)reason
              campaignInfo:(NSArray<SwrveQACampaignInfo *> *)qaCampaignInfoArray {
    NSMutableDictionary *logDetailsJson = [NSMutableDictionary new];
    [logDetailsJson setValue:eventName forKey:@"event_name"];
    [logDetailsJson setValue:eventPayload forKey:@"event_payload"];
    [logDetailsJson setValue:[NSNumber numberWithBool:displayed] forKey:@"displayed"];
    [logDetailsJson setValue:reason forKey:@"reason"];
    
    NSMutableArray *logDetailsCampaignArray = [NSMutableArray new];

    if ([qaCampaignInfoArray count] > 0){
        for(SwrveQACampaignInfo *campaign in qaCampaignInfoArray) {
            NSMutableDictionary *entry = [NSMutableDictionary new];
            [entry setValue:[NSNumber numberWithUnsignedInteger:campaign.campaignID] forKey:@"id"];
            [entry setValue:[NSNumber numberWithUnsignedInteger:campaign.variantID] forKey:@"variant_id"];
            [entry setValue:swrveCampaignTypeToString(campaign.type) forKey:@"type"];
            [entry setValue:[NSNumber numberWithBool:campaign.displayed] forKey:@"displayed"];
            [entry setValue:campaign.reason forKey:@"reason"];
            
            [logDetailsCampaignArray addObject:entry];
        }
    }
    
    [logDetailsJson setObject:logDetailsCampaignArray forKey:@"campaigns"];
    NSMutableDictionary *qaLogEvent = [SwrveEvents qaLogEvent:logDetailsJson logType:@"campaign-triggered"];
    [[[SwrveQA sharedInstance] queueManager] queueEvent:qaLogEvent];
}

@end
