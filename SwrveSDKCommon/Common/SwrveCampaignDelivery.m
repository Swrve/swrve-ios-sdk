#import "SwrveCampaignDelivery.h"
#import "SwrveCommon.h"
#import "SwrveRESTClient.h"
#import "SwrveUtils.h"
#import "SwrveNotificationConstants.h"
#import "SwrveEvents.h"
#import "SwrveSEConfig.h"

@interface SwrveCampaignDelivery ()
#if TARGET_OS_IOS
@property(nonatomic, retain) NSString *appGroupId;
#endif //TARGET_OS_IOS
@end

@implementation SwrveCampaignDelivery

#if TARGET_OS_IOS

@synthesize appGroupId;

- (id)initAppGroupId:(NSString *)appgroupid {
    self = [super init];
    if (self) {
        self.appGroupId = appgroupid;
    }
    return self;
}

- (void)sendPushDelivery:(NSDictionary *)userInfo {
    if (![SwrveSEConfig isValidAppGroupId:appGroupId]) {
        [SwrveLogger warning:@"Swrve not sending push delivery event because of invalid app group id.", nil];
        return;
    } else {
        id pushIdentifier = [userInfo objectForKey:SwrveNotificationIdentifierKey];
        id silentPushIdentifier = [userInfo objectForKey:SwrveNotificationSilentPushIdentifierKey];
        BOOL isSwrveRegularPush = pushIdentifier && ![pushIdentifier isKindOfClass:[NSNull class]];
        BOOL isSwrveSilentPush = silentPushIdentifier && ![silentPushIdentifier isKindOfClass:[NSNull class]];
        if (!(isSwrveRegularPush || isSwrveSilentPush)) {
            [SwrveLogger warning:@"Swrve not sending push delivery event because it is not a Swrve push.", nil];
            return;
        }
    }

    NSDictionary *deliveryConfig = [SwrveSEConfig deliveryConfig:self.appGroupId];
    [SwrveLogger debug:@"Swrve deliveryConfig from app group %@: %@", self.appGroupId, deliveryConfig];
    NSString *userId = [deliveryConfig objectForKey:SwrveDeliveryRequiredConfigUserIdKey];

    NSMutableDictionary *eventBatch = [NSMutableDictionary new];
    [eventBatch setValue:userId forKey:@"user"];
    [eventBatch setValue:[deliveryConfig objectForKey:SwrveDeliveryRequiredConfigDeviceIdKey] forKey:@"unique_device_id"];
    [eventBatch setValue:[deliveryConfig objectForKey:SwrveDeliveryRequiredConfigAppVersionKey] forKey:@"app_version"];

    NSMutableArray *events = [NSMutableArray new];
    NSDictionary *pushDeliveryEvent = [self pushDeliveryEvent:userInfo userId:userId];
    [events addObject:pushDeliveryEvent];

    // If is a QA user we also append the QA LogEvent.
    if ([[deliveryConfig objectForKey:SwrveDeliveryRequiredConfigIsQAUser] boolValue]) {
        [events addObject:[SwrveEvents qalogWrappedEvent:pushDeliveryEvent]];
    }
    [eventBatch setValue:[events copy] forKey:@"data"];

    NSDictionary *sw = [userInfo objectForKey:SwrveNotificationContentIdentifierKey];
    NSNumber *contentVersion = [sw objectForKey:@"version"];
    [eventBatch setValue:contentVersion forKey:@"version"];
    [eventBatch setValue:[deliveryConfig objectForKey:SwrveDeliveryRequiredConfigSessionTokenKey] forKey:@"session_token"];

    NSString *batchImpressionEvent = nil;
    NSError *jsonError;
    NSData *jsonEventBatchNSData = [NSJSONSerialization dataWithJSONObject:eventBatch options:0 error:&jsonError];
    if (jsonError) {
        [SwrveLogger error:@"Swrve Something went wrong when parsing the \"Push Delivery json event\" - invalid json format", nil];
        return;
    }

    batchImpressionEvent = [[NSString alloc] initWithData:jsonEventBatchNSData encoding:NSUTF8StringEncoding];
    NSData *jsonData = [batchImpressionEvent dataUsingEncoding:NSUTF8StringEncoding];
    NSURL *baseBatchUrl = [NSURL URLWithString:[deliveryConfig objectForKey:SwrveDeliveryRequiredConfigEventsUrlKey]];
    NSURL *batchURL = [NSURL URLWithString:@"1/batch" relativeToURL:baseBatchUrl];
    
    __block UIBackgroundTaskIdentifier handleContentTask = UIBackgroundTaskInvalid;
    __block NSString *taskName = @"PushDelivery";
    // if called from service ext flow for rich push, startBackgroundTaskCommon will return UIBackgroundTaskInvalid and have no affect
    handleContentTask = [SwrveUtils startBackgroundTaskCommon:handleContentTask withName:taskName];
    
    SwrveRESTClient *restClient = [[SwrveRESTClient alloc] initWithTimeoutInterval:10];
    [restClient sendHttpPOSTRequest:batchURL
                           jsonData:jsonData
                  completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
#pragma unused(response, data)
                      if (error != nil) {
                          [SwrveLogger error:@"Swrve Something went wrong with Push Send Delivery: %@", error.description];
                      }
                      [SwrveUtils stopBackgroundTaskCommon:handleContentTask withName:taskName];
                  }];
}

- (NSDictionary *)pushDeliveryEvent:(NSDictionary *)userInfo userId:(NSString *)userId {

    NSInteger seqnum = [SwrveSEConfig nextSeqnumForAppGroupId:self.appGroupId userId:userId];

    NSString *pushId = [userInfo objectForKey:SwrveNotificationIdentifierKey];
    BOOL isSilentPush = NO;
    BOOL displayed = YES;
    if ([userInfo objectForKey:SwrveNotificationSilentPushIdentifierKey]) {
        pushId = [userInfo objectForKey:SwrveNotificationSilentPushIdentifierKey];
        isSilentPush = YES;
        displayed = NO;
    }

    NSString *reason = @"";
    if ([SwrveUtils isDifferentUserForAuthenticatedPush:userInfo userId:userId]) {
        displayed = NO;
        reason = @"different_user";
    } else {
        if ([SwrveUtils isAuthenticatedPush:userInfo]) {
            if ([SwrveSEConfig isTrackingStateStopped:self.appGroupId]) {
                displayed = NO;
                reason = @"stopped";
            }
        }
    }

    return @{
            @"type": @"generic_campaign_event",
            @"time": [NSNumber numberWithUnsignedLongLong:[SwrveUtils getTimeEpoch]],
            @"seqnum": [NSString stringWithFormat:@"%ld", (long) seqnum],
            @"actionType": @"delivered",
            @"campaignType": @"push",
            @"payload": @{
                    @"displayed": [NSNumber numberWithBool:displayed],
                    @"reason": reason,
                    @"silent": [NSNumber numberWithBool:isSilentPush]
            },
            @"id": pushId
    };
}

#endif //TARGET_OS_IOS

@end
