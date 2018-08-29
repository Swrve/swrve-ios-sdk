#import <Foundation/Foundation.h>
#import "SwrveRESTClient.h"

@interface SwrveQA : NSObject

@property(atomic) SwrveRESTClient *restClient;
@property(nonatomic, readwrite) bool isQALogging;

+ (id)sharedInstance;
+ (void)makeRequest:(NSMutableDictionary *)jsonBody;

+ (void)geoCampaignTriggered:(NSArray *)campaigns
              fromGeoPlaceId:(NSString *)geoplaceId
               andGeofenceId:(NSString *)geofenceId
               andActionType:(NSString *)actionType;

+ (void)geoCampaignsDownloaded:(NSArray *)campaigns
                fromGeoPlaceId:(NSString *)geoplaceId
                 andGeofenceId:(NSString *)geofenceId
                 andActionType:(NSString *)actionType;

+ (NSMutableDictionary *)locationCampaignTriggered:(NSArray *)campaigns;
+ (NSMutableDictionary *)locationCampaignDownloaded;
+ (NSMutableDictionary *)locationCampaignEngagedID:(NSString *)campaignID variantID:(NSNumber *)variantID plotID:(NSString *)plotID payload:(NSDictionary *)payload;
+ (void)updateQAUser:(NSDictionary *)jsonQa;

@end
