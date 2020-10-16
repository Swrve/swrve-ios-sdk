#import "SwrveCampaignDelivery.h"
#import "SwrveCommon.h"
#import "SwrveRESTClient.h"
#import "SwrveUtils.h"
#import "SwrveNotificationConstants.h"
#import "SwrveQA.h"
#import "SwrveEvents.h"

// Main key for storage NSDictionary with info related with SwrveCampaing items.
NSString *const SwrveDeliveryConfigKey = @"swrve.delivery_rest_config";

// Dictionary Keys of the items required for network calls
NSString *const SwrveDeliveryRequiredConfigUserIdKey = @"swrve.userId";
NSString *const SwrveDeliveryRequiredConfigEventsUrlKey = @"swrve.events_url";
NSString *const SwrveDeliveryRequiredConfigDeviceIdKey = @"swrve.device_id";
NSString *const SwrveDeliveryRequiredConfigSessionTokenKey = @"swrve.session_token";
NSString *const SwrveDeliveryRequiredConfigAppVersionKey = @"swrve.app_version";
NSString *const SwrveDeliveryRequiredConfigIsQAUser = @"swrve.is_qa_user";

@implementation SwrveCampaignDelivery

+ (BOOL)isValidAppGroupId:(NSString *)appGroupId {
    return ((appGroupId != nil && [appGroupId length]) && [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:appGroupId] != nil);
}

+ (void)saveConfigForPushDeliveryWithUserId:(NSString *)userId
                         WithEventServerUrl:(NSString *)eventServerUrl
                               WithDeviceId:(NSString *)deviceId
                           WithSessionToken:(NSString *)sessionToken
                             WithAppVersion:(NSString *)appVersion
                              ForAppGroupID:(NSString *)appGroupId
                                   isQAUser:(BOOL)isQaUser {
    if (![self isValidAppGroupId:appGroupId]) {
        return; // We need a valid App group to procced this method.
    }
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:appGroupId];
    // Save NSDictionary into NSUserDefaults
    [userDefaults setObject:@{
        SwrveDeliveryRequiredConfigUserIdKey: userId,
        SwrveDeliveryRequiredConfigEventsUrlKey: eventServerUrl,
        SwrveDeliveryRequiredConfigDeviceIdKey: deviceId,
        SwrveDeliveryRequiredConfigSessionTokenKey: sessionToken,
        SwrveDeliveryRequiredConfigAppVersionKey: appVersion,
        SwrveDeliveryRequiredConfigIsQAUser:[NSNumber numberWithBool:isQaUser]
    } forKey:SwrveDeliveryConfigKey];
}

+ (NSInteger)nextEventSequenceWithUserId:(NSString *)userId forUserDefaults:(NSUserDefaults *)defaults {
    NSInteger seqno;
    @synchronized (self) {
        NSString *seqNumKey = [userId stringByAppendingString:@"swrve_event_seqnum"];
        // Defaults to 0 if this value is not available
        seqno = [defaults integerForKey:seqNumKey];
        seqno += 1;
        [defaults setInteger:seqno forKey:seqNumKey];
    }
    return seqno;
}

#if !defined(SWRVE_NO_PUSH) && TARGET_OS_IOS

+ (NSDictionary *)eventData:(NSDictionary *) userInfo forSeqno:(NSInteger)seqno {

    // Define if it's a silent push.
    NSString *pushId = [userInfo objectForKey:SwrveNotificationIdentifierKey];
    BOOL isSilentPush = NO;
    if ([userInfo objectForKey:@"_sp"]) {
        pushId = [userInfo objectForKey:@"_sp"];
        isSilentPush = YES;
    }
    return @{
        @"type":@"generic_campaign_event",
        @"time":[NSNumber numberWithUnsignedLongLong:[SwrveUtils getTimeEpoch]],
        @"seqnum":[NSString stringWithFormat: @"%ld", (long)seqno],
        @"actionType":@"delivered",
        @"campaignType":@"push",
        @"payload":@{
                @"silent": [NSNumber numberWithBool:isSilentPush]
        },
        @"id":pushId
    };
}

+ (void)sendPushDelivery:(NSDictionary *)userInfo withAppGroupID:(NSString *)appGroupId {
    if (![self isValidAppGroupId:appGroupId] || ![userInfo objectForKey:SwrveNotificationIdentifierKey]) {
        return; // We need a valid App group to procced this method, and must contain a "SwrveNotificationIdentifierKey" to proceed.
    }
    
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:appGroupId];
    NSDictionary *deliveryConfig = [userDefaults dictionaryForKey:SwrveDeliveryConfigKey];
    NSInteger seqno = [self nextEventSequenceWithUserId:[deliveryConfig objectForKey:SwrveDeliveryRequiredConfigUserIdKey] forUserDefaults:userDefaults];

    userDefaults = nil; //fast dealoc of NSUserDefaults - We do have limited memory at our SE calls.
    DebugLog(@"Swrve Stored Info at app group %@: %@", appGroupId, deliveryConfig);
    SwrveRESTClient *restClient = [[SwrveRESTClient alloc] initWithTimeoutInterval:10];

    NSMutableDictionary *eventBatch = [NSMutableDictionary new];
    [eventBatch setValue:[deliveryConfig objectForKey:SwrveDeliveryRequiredConfigUserIdKey] forKey:@"user"];
    [eventBatch setValue:[deliveryConfig objectForKey:SwrveDeliveryRequiredConfigDeviceIdKey] forKey:@"unique_device_id"];
    [eventBatch setValue:[deliveryConfig objectForKey:SwrveDeliveryRequiredConfigAppVersionKey] forKey:@"app_version"];

    NSMutableArray *eventData = [NSMutableArray new];
    NSDictionary *pushDeliveryData = [self eventData:userInfo forSeqno:seqno];
    [eventData addObject: pushDeliveryData];

    // If is a QA user we also append the QA LogEvent.
    if([[deliveryConfig objectForKey:SwrveDeliveryRequiredConfigIsQAUser] boolValue]) {
        [eventData addObject:[SwrveEvents qalogWrappedEvent:pushDeliveryData]];
    }
    [eventBatch setValue:[eventData copy] forKey:@"data"];

    NSDictionary *sw = [userInfo objectForKey:SwrveNotificationContentIdentifierKey];
    NSNumber *contentVersion = [sw objectForKey:@"version"];
    [eventBatch setValue:contentVersion forKey:@"version"];
    [eventBatch setValue:[deliveryConfig objectForKey:SwrveDeliveryRequiredConfigSessionTokenKey] forKey:@"session_token"];

    NSString *batchImpressionEvent = nil;
    NSError *jsonError;
    NSData *jsonEventBatchNSData = [NSJSONSerialization dataWithJSONObject:eventBatch options:0 error:&jsonError];
    if (jsonError) {
        DebugLog(@"Swrve Something went wrong when parsing the \"Push Delivery json event\" - invalid json format", nil);
        return;
    }

    batchImpressionEvent = [[NSString alloc] initWithData:jsonEventBatchNSData encoding:NSUTF8StringEncoding];
    NSData *jsonData = [batchImpressionEvent dataUsingEncoding:NSUTF8StringEncoding];
    NSURL *baseBatchUrl = [NSURL URLWithString:[deliveryConfig objectForKey:SwrveDeliveryRequiredConfigEventsUrlKey]];
    NSURL *batchURL = [NSURL URLWithString:@"1/batch" relativeToURL:baseBatchUrl];

    [restClient sendHttpPOSTRequest:batchURL
                           jsonData:jsonData
                  completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
#pragma unused(response, data)
        if(error == nil) {
            DebugLog(@"Swrve Something went wrong with Push Send Delivery: %@", error.description);
        }
    }];
}

#endif // !defined(SWRVE_NO_PUSH) && TARGET_OS_IOS

@end
