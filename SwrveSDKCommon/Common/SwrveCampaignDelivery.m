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

    [self sendEvent:[self pushDeliveryEvent:userInfo userId:userId]
           userInfo:userInfo
     deliveryConfig:deliveryConfig
           taskName:@"PushDelivery"];
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
    
    NSMutableDictionary *payload = [NSMutableDictionary new];
    [payload setObject:[NSNumber numberWithBool:displayed] forKey:@"displayed"];
    [payload setObject:reason forKey:@"reason"];
    [payload setObject: [NSNumber numberWithBool:isSilentPush] forKey:@"silent"];
    NSMutableDictionary *trackingPayload = [SwrveUtils pushTrackingPayload:userInfo];
    if (trackingPayload != nil) {
        [payload addEntriesFromDictionary:trackingPayload];
    }

    return @{
            @"type": @"generic_campaign_event",
            @"time": [NSNumber numberWithUnsignedLongLong:[SwrveUtils getTimeEpoch]],
            @"seqnum": [NSString stringWithFormat:@"%ld", (long) seqnum],
            @"actionType": @"delivered",
            @"campaignType": @"push",
            @"payload": payload,
            @"id": pushId
    };
}


- (void)sendCarouselPageView:(NSDictionary *)userInfo
                   requestId:(NSString *)requestId
                   itemIndex:(NSInteger)itemIndex {

    if (![SwrveSEConfig isValidAppGroupId:appGroupId]) {
        [SwrveLogger warning:@"Swrve not sending carousel page view because of invalid app group id.", nil];
        return;
    }

    id pushIdentifier = [userInfo objectForKey:SwrveNotificationIdentifierKey];
    if (pushIdentifier == nil || [pushIdentifier isKindOfClass:[NSNull class]]) {
        [SwrveLogger warning:@"Swrve not sending carousel page view because it is not a Swrve push.", nil];
        return;
    }

    if ([SwrveSEConfig isTrackingStateStopped:appGroupId]) {
        [SwrveLogger debug:@"Swrve not sending carousel page view because sdk tracking is stopped."];
        return;
    }

    NSDictionary *deliveryConfig = [SwrveSEConfig deliveryConfig:self.appGroupId];
    NSString *userId = [deliveryConfig objectForKey:SwrveDeliveryRequiredConfigUserIdKey];
    NSString *eventsUrl = [deliveryConfig objectForKey:SwrveDeliveryRequiredConfigEventsUrlKey];
    if (userId == nil || eventsUrl == nil) {
        // The app writes this config into the App Group when it starts. Without it there is nowhere
        // to send the event and no user to attribute it to, and the POST would fail silently.
        [SwrveLogger error:@"Swrve cannot send carousel page view: no delivery config in app group %@. The host app must start with the same app group before the extension can send events.", self.appGroupId];
        return;
    }

    if ([SwrveSEConfig hasCarouselPageBeenViewed:appGroupId requestId:requestId itemIndex:itemIndex]) {
        [SwrveLogger debug:@"Swrve carousel item %ld already reported for request %@", (long) itemIndex, requestId];
        return;
    }

    NSDictionary *event = [self carouselPageViewEvent:userInfo userId:userId itemIndex:itemIndex];
    [SwrveLogger debug:@"Swrve sending carousel page view for item %ld of push %@ to %@", (long) itemIndex, [userInfo objectForKey:SwrveNotificationIdentifierKey], eventsUrl];

    // Recorded only once the event is actually away. A content extension gets no background task
    // (`startBackgroundTaskCommon:` is a no-op without a UIApplication), so a request in flight dies
    // when the notification is dismissed — marking beforehand would burn the item with nothing
    // retrying. The caller's in-memory guard covers repeat sends while this one is still open.
    NSString *markAppGroupId = self.appGroupId;
    [self sendEvent:event userInfo:userInfo deliveryConfig:deliveryConfig taskName:@"CarouselPageView" onSuccess:^{
        [SwrveSEConfig markCarouselPageViewed:markAppGroupId requestId:requestId itemIndex:itemIndex];
    }];
}

- (NSDictionary *)carouselPageViewEvent:(NSDictionary *)userInfo userId:(NSString *)userId itemIndex:(NSInteger)itemIndex {

    NSInteger seqnum = [SwrveSEConfig nextSeqnumForAppGroupId:self.appGroupId userId:userId];

    NSMutableDictionary *payload = [NSMutableDictionary new];
    [payload setObject:@YES forKey:@"carousel"];
    // `slide` is the wire field name even though the SDK says "item" everywhere else. 0-based,
    // matching `contextId` and the index used everywhere inside the SDK.
    [payload setObject:@(itemIndex) forKey:@"slide"];
    NSMutableDictionary *trackingPayload = [SwrveUtils pushTrackingPayload:userInfo];
    if (trackingPayload != nil) {
        [payload addEntriesFromDictionary:trackingPayload];
    }
    NSString *deeplink = [self carouselItemDeeplink:userInfo itemIndex:itemIndex];
    if (deeplink != nil) {
        [payload setObject:deeplink forKey:@"deeplink"];
    }

    return @{
            @"type": @"generic_campaign_event",
            @"time": [NSNumber numberWithUnsignedLongLong:[SwrveUtils getTimeEpoch]],
            @"seqnum": [NSString stringWithFormat:@"%ld", (long) seqnum],
            @"actionType": @"slide_view",
            @"campaignType": @"push",
            @"contextId": [NSString stringWithFormat:@"%ld", (long) itemIndex],
            @"payload": payload,
            @"id": [userInfo objectForKey:SwrveNotificationIdentifierKey]
    };
}

/// The item's own action, never the push's deeplink, and only for open_url, as the tap record saves it.
- (NSString *)carouselItemDeeplink:(NSDictionary *)userInfo itemIndex:(NSInteger)itemIndex {
    NSDictionary *sw = [userInfo objectForKey:SwrveNotificationContentIdentifierKey];
    id items = [sw isKindOfClass:[NSDictionary class]] ? [sw objectForKey:SwrveNotificationCarouselKey] : nil;
    if (![items isKindOfClass:[NSArray class]] || itemIndex < 0 || itemIndex >= (NSInteger) [items count]) {
        return nil;
    }
    id item = [items objectAtIndex:(NSUInteger) itemIndex];
    if (![item isKindOfClass:[NSDictionary class]]
        || ![[item objectForKey:SwrveNotificationButtonActionTypeKey] isEqual:SwrveNotificationCustomButtonUrlIdentiferKey]) {
        return nil;
    }
    id action = [item objectForKey:SwrveNotificationButtonActionKey];
    return ([action isKindOfClass:[NSString class]] && [action length] > 0) ? action : nil;
}

/// Posts one event as a batch, using the config the app shared through the App Group.
- (void)sendEvent:(NSDictionary *)event
         userInfo:(NSDictionary *)userInfo
   deliveryConfig:(NSDictionary *)deliveryConfig
         taskName:(NSString *)taskName {
    [self sendEvent:event userInfo:userInfo deliveryConfig:deliveryConfig taskName:taskName onSuccess:nil];
}

- (void)sendEvent:(NSDictionary *)event
         userInfo:(NSDictionary *)userInfo
   deliveryConfig:(NSDictionary *)deliveryConfig
         taskName:(NSString *)taskName
        onSuccess:(void (^)(void))onSuccess {

    NSMutableDictionary *eventBatch = [NSMutableDictionary new];
    [eventBatch setValue:[deliveryConfig objectForKey:SwrveDeliveryRequiredConfigUserIdKey] forKey:@"user"];
    [eventBatch setValue:[deliveryConfig objectForKey:SwrveDeliveryRequiredConfigDeviceIdKey] forKey:@"unique_device_id"];
    [eventBatch setValue:[deliveryConfig objectForKey:SwrveDeliveryRequiredConfigAppVersionKey] forKey:@"app_version"];

    NSMutableArray *events = [NSMutableArray new];
    [events addObject:event];
    [SwrveLogger debug:@"Swrve %@ event: %@", taskName, event];

    BOOL isQAUser = [[deliveryConfig objectForKey:SwrveDeliveryRequiredConfigIsQAUser] boolValue];
    if (isQAUser) {
        NSDictionary *qaEvent = [SwrveEvents qalogWrappedEvent:event];
        [events addObject:qaEvent];
        [SwrveLogger debug:@"Swrve %@ QA event: %@", taskName, qaEvent];
    }
    
    [eventBatch setValue:[events copy] forKey:@"data"];

    NSDictionary *sw = [userInfo objectForKey:SwrveNotificationContentIdentifierKey];
    [eventBatch setValue:[sw objectForKey:@"version"] forKey:@"version"];
    [eventBatch setValue:[deliveryConfig objectForKey:SwrveDeliveryRequiredConfigSessionTokenKey] forKey:@"session_token"];

    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:eventBatch options:0 error:&jsonError];
    if (jsonError) {
        [SwrveLogger error:@"Swrve Something went wrong when parsing the %@ json event - invalid json format", taskName];
        return;
    }
    [SwrveLogger debug:@"Swrve %@ batch: %@", taskName, [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];

    NSURL *baseBatchUrl = [NSURL URLWithString:[deliveryConfig objectForKey:SwrveDeliveryRequiredConfigEventsUrlKey]];
    NSURL *batchURL = [NSURL URLWithString:@"1/batch" relativeToURL:baseBatchUrl];

    __block UIBackgroundTaskIdentifier task = UIBackgroundTaskInvalid;
    task = [SwrveUtils startBackgroundTaskCommon:task withName:taskName];

    SwrveRESTClient *restClient = [[SwrveRESTClient alloc] initWithTimeoutInterval:10];
    [restClient sendHttpPOSTRequest:batchURL
                           jsonData:jsonData
                  completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                      if (error != nil) {
                          [SwrveLogger error:@"Swrve Something went wrong sending %@: %@", taskName, error.description];

                      } else {
                          BOOL accepted = YES;
                          // A rejected batch answers with a non-200 and an explanation. Without this
                          // the event looks sent and simply never appears.
                          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                          if ([httpResponse isKindOfClass:[NSHTTPURLResponse class]] && [httpResponse statusCode] != 200) {
                              NSString *body = data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : @"";
                              [SwrveLogger error:@"Swrve %@ rejected with status %ld: %@", taskName, (long) [httpResponse statusCode], body];
                                  accepted = NO;
                          }
                          if (accepted && onSuccess != nil) {
                              onSuccess();
                          }
                      }
                      [SwrveUtils stopBackgroundTaskCommon:task withName:taskName];
                  }];
}

#endif //TARGET_OS_IOS

@end
