#import "SwrveCampaignInfluence.h"
#import "SwrveCommon.h"
#import "SwrveNotificationConstants.h"

NSString *const SwrveInfluencedWindowMinsKey = @"_siw";
NSString *const SwrveInfluenceDataKey = @"swrve.influence_data_v2";

@implementation SwrveCampaignInfluence

+ (void)saveInfluencedData:(NSDictionary *)userInfo withId:(NSString *)campaignId withAppGroupID:(NSString *)appGroupId atDate:(NSDate *)date API_AVAILABLE(ios(7.0)) {
    // Check if the push requires influence tracking
    id influencedWindowMinsRaw = [userInfo objectForKey:SwrveInfluencedWindowMinsKey];
    if (influencedWindowMinsRaw && ![influencedWindowMinsRaw isKindOfClass:[NSNull class]]) {
        int influenceWindowMins = 720;
        if ([influencedWindowMinsRaw isKindOfClass:[NSString class]]) {
            influenceWindowMins = [influencedWindowMinsRaw intValue];
        } else if ([influencedWindowMinsRaw isKindOfClass:[NSNumber class]]) {
            influenceWindowMins = [((NSNumber *) influencedWindowMinsRaw) intValue];
        }

        // Save influence data
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if (appGroupId) {
            // if there is an appGroupID then check there instead
            defaults = [[NSUserDefaults alloc] initWithSuiteName:appGroupId];
        }
        [defaults synchronize];

        NSMutableDictionary *influencedData = [[defaults dictionaryForKey:SwrveInfluenceDataKey] mutableCopy];
        if (influencedData == nil) { // if nothing is there. create a new one
            influencedData = [NSMutableDictionary new];
        }

        // set id passed in
        long maxWindowTimeSeconds = (long) [[date dateByAddingTimeInterval:influenceWindowMins * 60] timeIntervalSince1970];

        // Define if it's a silent push or a normal push.
        BOOL isSilentPush = NO;
        if ([userInfo objectForKey:SwrveNotificationSilentPushIdentifierKey]) {
            isSilentPush = YES;
        }
        // Add the new influence into cache!
        [influencedData setValue:@{
            @"trackingId": campaignId,
            @"silent": [NSNumber numberWithBool: isSilentPush],
            @"maxInfluencedMillis": [NSNumber numberWithLong:maxWindowTimeSeconds]
        } forKey:campaignId];

        // set influenced data to either the appGroup or the NSUserDefaults of the main app
        [defaults setObject:influencedData forKey:SwrveInfluenceDataKey];
        [defaults synchronize];
    }
}

+ (void)removeInfluenceDataForId:(NSString *)notificationId fromAppGroupId:(NSString *)appGroupId API_AVAILABLE(ios(8.0)) {
    // remove from core app
    NSUserDefaults *coreAppUserDefaults = [NSUserDefaults standardUserDefaults];
    [self removeInfluenceDataFromUserDefaults:coreAppUserDefaults forId:notificationId];

    // remove from  app group
    NSUserDefaults *appGroupUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:appGroupId];
    [self removeInfluenceDataFromUserDefaults:appGroupUserDefaults forId:notificationId];
}

+ (void)removeInfluenceDataFromUserDefaults:(NSUserDefaults *)userDefaults forId:(NSString *)notificationId {
    NSMutableDictionary *influenceDataDictionary = [[userDefaults dictionaryForKey:SwrveInfluenceDataKey] mutableCopy];
    if ([influenceDataDictionary objectForKey:notificationId]) {
        [influenceDataDictionary removeObjectForKey:notificationId];
        [[NSUserDefaults standardUserDefaults] setValue:influenceDataDictionary forKey:SwrveInfluenceDataKey];
    }
}

+ (void)processInfluenceDataWithDate:(NSDate *)now API_AVAILABLE(ios(8.0)) {

    NSDictionary *influencedData;
    NSDictionary *mainAppInfluence = [[NSUserDefaults standardUserDefaults] dictionaryForKey:SwrveInfluenceDataKey];
    NSDictionary *serviceExtensionInfluence = nil;

    id <SwrveCommonDelegate> swrveCommon = (id <SwrveCommonDelegate>) [SwrveCommon sharedInstance];

    if (swrveCommon != nil && swrveCommon.appGroupIdentifier != nil) {
        serviceExtensionInfluence = [[[NSUserDefaults alloc] initWithSuiteName:swrveCommon.appGroupIdentifier] dictionaryForKey:SwrveInfluenceDataKey];
    }

    if (mainAppInfluence != nil) {
        influencedData = mainAppInfluence;
    } else if (serviceExtensionInfluence != nil) {
        influencedData = serviceExtensionInfluence;
    }

    if (influencedData != nil) {
        double nowSeconds = [now timeIntervalSince1970];
        for (NSString *trackingId in influencedData) {

            // Read details about the influenced item to be queued.
            NSDictionary *influenceItem = [influencedData objectForKey:trackingId];
            id maxInfluenceWindow = [influenceItem objectForKey:@"maxInfluencedMillis"];
            BOOL isSilentPush = NO;
            if ([influenceItem objectForKey:@"silent"]) {
                isSilentPush = [[influenceItem objectForKey:@"silent"] boolValue];
            }

            if ([maxInfluenceWindow isKindOfClass:[NSNumber class]]) {
                long maxWindowTimeSeconds = [(NSNumber *) maxInfluenceWindow longValue];

                if (maxWindowTimeSeconds > 0 && maxWindowTimeSeconds >= nowSeconds) {
                    // Send an influenced event for this tracking id
                    if (swrveCommon != nil) {
                        NSInteger trackingIdLong = [trackingId integerValue];
                        NSMutableDictionary *influencedEvent = [NSMutableDictionary new];
                        [influencedEvent setValue:[NSNumber numberWithLong:trackingIdLong] forKey:@"id"];
                        [influencedEvent setValue:@"push" forKey:@"campaignType"];
                        [influencedEvent setValue:@"influenced" forKey:@"actionType"];

                        // Influence payload.
                        NSMutableDictionary *eventPayload = [NSMutableDictionary new];
                        [eventPayload setValue:[NSString stringWithFormat:@"%i", (int) ((maxWindowTimeSeconds - nowSeconds) / 60)] forKey:@"delta"];
                        [eventPayload setValue:[NSNumber numberWithBool:isSilentPush] forKey:@"silent"];
                        [influencedEvent setValue:eventPayload forKey:@"payload"];

                        [swrveCommon queueEvent:@"generic_campaign_event" data:influencedEvent triggerCallback:false];
                    } else {
                        [SwrveLogger error:@"Could not find a shared instance to send the influence data", nil];
                    }
                }
            }
        }

        [[NSUserDefaults standardUserDefaults] removeObjectForKey:SwrveInfluenceDataKey];
        [[[NSUserDefaults alloc] initWithSuiteName:swrveCommon.appGroupIdentifier] removeObjectForKey:SwrveInfluenceDataKey];
    }
}

@end
