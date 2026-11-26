#import "SwrveSEConfig.h"
#import "SwrveLogger.h"

// Swrve Service Extension Config
@implementation SwrveSEConfig

+ (BOOL)isValidAppGroupId:(NSString *)appGroupId {
    return ((appGroupId != nil && [appGroupId length]) &&
            [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:appGroupId] != nil);
}

+ (void)saveAppGroupId:(NSString *)appGroupId
                userId:(NSString *)userId
        eventServerUrl:(NSString *)eventServerUrl
              deviceId:(NSString *)deviceId
          sessionToken:(NSString *)sessionToken
            appVersion:(NSString *)appVersion
              isQAUser:(BOOL)isQaUser {

    if (![self isValidAppGroupId:appGroupId]) {
        return; // We need a valid App group to proceed this method.
    }

    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:appGroupId];
    [userDefaults setObject:@{
            SwrveDeliveryRequiredConfigUserIdKey: userId,
            SwrveDeliveryRequiredConfigEventsUrlKey: eventServerUrl,
            SwrveDeliveryRequiredConfigDeviceIdKey: deviceId,
            SwrveDeliveryRequiredConfigSessionTokenKey: sessionToken,
            SwrveDeliveryRequiredConfigAppVersionKey: appVersion,
            SwrveDeliveryRequiredConfigIsQAUser: [NSNumber numberWithBool:isQaUser]
    }                forKey:SwrveDeliveryConfigKey];
}

+ (NSDictionary *)deliveryConfig:(NSString *)appGroupId {
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:appGroupId];
    return [userDefaults dictionaryForKey:SwrveDeliveryConfigKey];
}

+ (void)saveTrackingStateStopped:(NSString *)appGroupId isTrackingStateStopped:(BOOL)isTrackingStateStopped {
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:appGroupId];
    [userDefaults setBool:isTrackingStateStopped forKey:SwrveSEConfigIsTrackingStateStopped];
}

+ (BOOL)isTrackingStateStopped:(NSString *)appGroupId {
    BOOL isTrackingStateStopped = NO;
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:appGroupId];
    if ([userDefaults objectForKey:SwrveSEConfigIsTrackingStateStopped]) {
        isTrackingStateStopped = [userDefaults boolForKey:SwrveSEConfigIsTrackingStateStopped];
    }
    return isTrackingStateStopped;
}

+ (NSInteger)nextSeqnumForAppGroupId:(NSString *)appGroupId
                              userId:(NSString *)userId {
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:appGroupId];
    NSInteger seqno;
    @synchronized (self) {
        NSString *seqNumKey = [userId stringByAppendingString:@"swrve_event_seqnum"];
        // Defaults to 0 if this value is not available
        seqno = [userDefaults integerForKey:seqNumKey];
        seqno += 1;
        [userDefaults setInteger:seqno forKey:seqNumKey];
    }
    return seqno;
}

+ (void)saveCarouselItemTap:(NSString *)appGroupId
                  requestId:(NSString *)requestId
                  itemIndex:(NSInteger)itemIndex
                     action:(NSString *)action {

    if (![self isValidAppGroupId:appGroupId]) {
        [SwrveLogger error:@"SwrveSEConfig: no valid app group, carousel item tap will be lost. The extension needs the same app group as the app.", nil];
        return;
    }
    if (requestId == nil || [requestId length] == 0) {
        [SwrveLogger error:@"SwrveSEConfig: no notification request id, carousel item tap will be lost.", nil];
        return;
    }

    NSMutableDictionary *record = [NSMutableDictionary dictionary];
    [record setObject:requestId forKey:SwrveCarouselItemTapRequestIdKey];
    [record setObject:@(itemIndex) forKey:SwrveCarouselItemTapIndexKey];
    // Absent for open_app. Deliberately not defaulted to an empty string: the app distinguishes
    // "no deeplink" from "no tap" by the presence of the record, not by this key.
    if (action != nil && [action length] > 0) {
        [record setObject:action forKey:SwrveCarouselItemTapActionKey];
    }

    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:appGroupId];
    [userDefaults setObject:record forKey:SwrveSEConfigCarouselItemTapKey];
}

+ (NSDictionary *)consumeCarouselItemTap:(NSString *)appGroupId
                               requestId:(NSString *)requestId {

    if (![self isValidAppGroupId:appGroupId]) {
        return nil;
    }

    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:appGroupId];
    NSDictionary *record = [userDefaults dictionaryForKey:SwrveSEConfigCarouselItemTapKey];
    if (record == nil) {
        return nil;
    }

    // Only consume on a match. This runs for a direct press on *any* Swrve notification, not just
    // carousel ones, so removing unconditionally would let an unrelated notification destroy a tap
    // that is still waiting to be delivered.
    NSString *recordedId = [record objectForKey:SwrveCarouselItemTapRequestIdKey];
    if (requestId == nil || ![recordedId isEqualToString:requestId]) {
        [SwrveLogger debug:@"SwrveSEConfig: carousel item tap is for request %@, current is %@, leaving it in place", recordedId, requestId];
        return nil;
    }

    [userDefaults removeObjectForKey:SwrveSEConfigCarouselItemTapKey];
    return record;
}

+ (BOOL)hasCarouselPageBeenViewed:(NSString *)appGroupId
                        requestId:(NSString *)requestId
                        itemIndex:(NSInteger)itemIndex {

    if (![self isValidAppGroupId:appGroupId] || requestId == nil || [requestId length] == 0) {
        return NO;
    }
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:appGroupId];
    NSDictionary *stored = [userDefaults dictionaryForKey:SwrveSEConfigCarouselPageViewsKey];
    NSDictionary *storedViewed = [stored objectForKey:@"viewed"];
    if (![storedViewed isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    NSArray *viewed = [storedViewed objectForKey:requestId];
    return ([viewed isKindOfClass:[NSArray class]] && [viewed containsObject:@(itemIndex)]);
}

+ (void)markCarouselPageViewed:(NSString *)appGroupId
                     requestId:(NSString *)requestId
                     itemIndex:(NSInteger)itemIndex {

    if (![self isValidAppGroupId:appGroupId]) {
        [SwrveLogger error:@"SwrveSEConfig: no valid app group, carousel page view cannot be de-duplicated.", nil];
        return;
    }
    if (requestId == nil || [requestId length] == 0) {
        [SwrveLogger error:@"SwrveSEConfig: no notification request id, carousel page view cannot be de-duplicated.", nil];
        return;
    }

    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:appGroupId];
    NSDictionary *stored = [userDefaults dictionaryForKey:SwrveSEConfigCarouselPageViewsKey];

    // Insertion order is the eviction order, so the record is rebuilt as an ordered pair of arrays
    // rather than relying on NSDictionary ordering.
    NSMutableArray *requestIds = [NSMutableArray array];
    NSMutableDictionary *viewedByRequestId = [NSMutableDictionary dictionary];
    NSArray *storedOrder = [stored objectForKey:@"order"];
    NSDictionary *storedViewed = [stored objectForKey:@"viewed"];
    if ([storedOrder isKindOfClass:[NSArray class]] && [storedViewed isKindOfClass:[NSDictionary class]]) {
        [requestIds addObjectsFromArray:storedOrder];
        [viewedByRequestId addEntriesFromDictionary:storedViewed];
    }

    NSArray *viewed = [viewedByRequestId objectForKey:requestId];
    if ([viewed isKindOfClass:[NSArray class]] && [viewed containsObject:@(itemIndex)]) {
        return;
    }

    NSMutableArray *updated = [NSMutableArray arrayWithArray:([viewed isKindOfClass:[NSArray class]] ? viewed : @[])];
    [updated addObject:@(itemIndex)];
    [viewedByRequestId setObject:updated forKey:requestId];

    [requestIds removeObject:requestId];
    [requestIds addObject:requestId];
    while ([requestIds count] > SwrveSEConfigCarouselPageViewsLimit) {
        [viewedByRequestId removeObjectForKey:[requestIds firstObject]];
        [requestIds removeObjectAtIndex:0];
    }

    [userDefaults setObject:@{@"order": [requestIds copy], @"viewed": [viewedByRequestId copy]}
                     forKey:SwrveSEConfigCarouselPageViewsKey];
}

@end
