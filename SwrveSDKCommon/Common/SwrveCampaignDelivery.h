#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SwrveCampaignDelivery : NSObject

#if TARGET_OS_IOS

- (id)initAppGroupId:(NSString *)appgroupid;

- (void)sendPushDelivery:(NSDictionary *)userInfo;

/// This is the only carousel event sent out of process — the engaged event is fired by the app when
/// the tap launches it, and an extension copy would double-count every tap.
- (void)sendCarouselPageView:(NSDictionary *)userInfo
                   requestId:(NSString *)requestId
                   itemIndex:(NSInteger)itemIndex;

#endif //TARGET_OS_IOS

@end

NS_ASSUME_NONNULL_END
