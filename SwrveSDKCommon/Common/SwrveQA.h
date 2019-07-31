#import <Foundation/Foundation.h>
#import "SwrveRESTClient.h"

@interface SwrveQA : NSObject

@property(atomic) SwrveRESTClient *restClient;
@property(nonatomic, readwrite) bool isQALogging;
@property (atomic) BOOL resetDeviceState;

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

+ (void)updateQAUser:(NSDictionary *)jsonQa;

@end
