SwrveCampaignDelivery

@interface SwrveCampaignDelivery ()

// Force exterl public keys
extern NSString *const SwrveDeliveryRequiredConfigKey;
extern NSString *const SwrveDeliveryRequiredConfigUserIdKey;
extern NSString *const SwrveDeliveryRequiredConfigEventsUrlKey;
extern NSString *const SwrveDeliveryRequiredConfigDeviceIdKey;
extern NSString *const SwrveDeliveryRequiredConfigSessionTokenKey;
extern NSString *const SwrveDeliveryRequiredConfigAppVersionKey;

// Force public interface for private methods.
+ (BOOL) isValidAppGroupId:(NSString *)appId;
+ (NSDictionary *)createEventData:(NSDictionary *) userInfo;

@end
