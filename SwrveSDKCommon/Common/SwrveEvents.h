#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SwrveEvents : NSObject

#pragma mark QA SDK Events

+ (NSMutableDictionary *)qalogWrappedEvent:(NSDictionary *) dic;
+ (NSMutableDictionary *)qalogCampaignsDownloaded:(NSArray *) array;
+ (NSMutableDictionary *)qalogCampaignButtonClicked:(NSDictionary *) campaign;
+ (NSMutableDictionary *)qaLogEvent:(NSDictionary *) logDetails logType:(NSString *) logType;

#pragma mark QA GEO-SDK Events
+ (NSMutableDictionary *)qalogGeoCampaignTriggered:(NSArray *)campaigns
              fromGeoPlaceId:(NSString *)geoplaceId
               andGeofenceId:(NSString *)geofenceId
               andActionType:(NSString *)actionType;
+ (NSMutableDictionary *)qalogGeoCampaignsDownloaded:(NSArray *)campaigns
                fromGeoPlaceId:(NSString *)geoplaceId
                 andGeofenceId:(NSString *)geofenceId
                 andActionType:(NSString *)actionType;

@end

NS_ASSUME_NONNULL_END


