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

// Pending carousel item tap, written by the content extension and consumed by the app.
static NSString *const SwrveSEConfigCarouselItemTapKey = @"swrve.carousel_item_tap";
static NSString *const SwrveCarouselItemTapRequestIdKey = @"request_id";
static NSString *const SwrveCarouselItemTapIndexKey = @"item_index";
static NSString *const SwrveCarouselItemTapActionKey = @"action";

// Per-notification record of which carousel items have already reported a page view.
static NSString *const SwrveSEConfigCarouselPageViewsKey = @"swrve.carousel_page_views";
// Most recent notifications retained in that record, so it cannot grow without bound.
static const NSInteger SwrveSEConfigCarouselPageViewsLimit = 20;

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

+ (void)saveCarouselItemTap:(NSString *)appGroupId
                  requestId:(NSString *)requestId
                  itemIndex:(NSInteger)itemIndex
                     action:(nullable NSString *)action;

+ (nullable NSDictionary *)consumeCarouselItemTap:(NSString *)appGroupId
                                        requestId:(NSString *)requestId;

/// Whether a carousel item has already been reported as viewed for this notification.
///
/// The content extension is re-instantiated when a notification is collapsed and re-expanded, so an
/// in-memory set alone would let item 0 re-report every time. Keyed on the per-delivery request id,
/// not the campaign-level push id, so two notifications from one campaign dedupe independently.
+ (BOOL)hasCarouselPageBeenViewed:(NSString *)appGroupId
                        requestId:(NSString *)requestId
                        itemIndex:(NSInteger)itemIndex;

/// Records a carousel item as reported. **Call this only once the event has actually been sent** —
/// the record is permanent and nothing retries, so marking a failed send loses that view for good.
+ (void)markCarouselPageViewed:(NSString *)appGroupId
                     requestId:(NSString *)requestId
                     itemIndex:(NSInteger)itemIndex;

@end

NS_ASSUME_NONNULL_END
