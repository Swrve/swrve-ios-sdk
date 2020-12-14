#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SwrveCampaignDelivery : NSObject

+ (void)saveConfigForPushDeliveryWithUserId:(NSString *)userId
                         WithEventServerUrl:(NSString *)eventServerUrl
                               WithDeviceId:(NSString *)deviceId
                           WithSessionToken:(NSString *)sessionToken
                             WithAppVersion:(NSString *)appVersion
                              ForAppGroupID:(NSString *)appGroupId
                                   isQAUser:(BOOL)isQaUser;

#if !defined(SWRVE_NO_PUSH) && TARGET_OS_IOS
+ (void)sendPushDelivery:(NSDictionary *)userInfo withAppGroupID:(NSString *)appGroupId;
#endif //!defined(SWRVE_NO_PUSH)

@end

NS_ASSUME_NONNULL_END
