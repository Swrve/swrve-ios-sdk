#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Main key for storage NSDictionary with info related with SwrveCampaignDelivery items.
static NSString *const SwrveDeliveryConfigKey = @"swrve.delivery_rest_config";

// Dictionary Keys of the items stored in SwrveDeliveryConfig
static NSString *const SwrveDeliveryRequiredConfigUserIdKey = @"swrve.userId";
static NSString *const SwrveDeliveryRequiredConfigEventsUrlKey = @"swrve.events_url";
static NSString *const SwrveDeliveryRequiredConfigDeviceIdKey = @"swrve.device_id";
static NSString *const SwrveDeliveryRequiredConfigSessionTokenKey = @"swrve.session_token";
static NSString *const SwrveDeliveryRequiredConfigAppVersionKey = @"swrve.app_version";
static NSString *const SwrveDeliveryRequiredConfigIsQAUser = @"swrve.is_qa_user";

// Other dictionary keys stored in SwrveSEConfig
static NSString *const SwrveSEConfigIsTrackingStateStopped = @"swrve.is_tracking_state_stopped";

// Swrve Service Extension Config
@interface SwrveSEConfig : NSObject

+ (BOOL) isValidAppGroupId:(NSString *)appId;

+ (void)saveAppGroupId:(NSString *)appGroupId
                userId:(NSString *)userId
        eventServerUrl:(NSString *)eventServerUrl
              deviceId:(NSString *)deviceId
          sessionToken:(NSString *)sessionToken
            appVersion:(NSString *)appVersion
              isQAUser:(BOOL)isQaUser;

+ (NSDictionary *)deliveryConfig:(NSString *)appGroupId;

+ (void)saveTrackingStateStopped:(NSString *)appGroupId isTrackingStateStopped:(BOOL)isTrackingStateStopped;

+ (BOOL)isTrackingStateStopped:(NSString *)appGroupId;

+ (NSInteger)nextSeqnumForAppGroupId:(NSString *)appGroupId
                              userId:(NSString *)userId;

@end

NS_ASSUME_NONNULL_END
