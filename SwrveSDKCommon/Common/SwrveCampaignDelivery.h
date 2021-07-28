#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SwrveCampaignDelivery : NSObject

#if TARGET_OS_IOS

- (id)initAppGroupId:(NSString *)appgroupid;

- (void)sendPushDelivery:(NSDictionary *)userInfo;

#endif //TARGET_OS_IOS

@end

NS_ASSUME_NONNULL_END
