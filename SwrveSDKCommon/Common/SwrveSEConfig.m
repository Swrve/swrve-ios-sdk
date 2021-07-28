#import "SwrveSEConfig.h"

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

@end
