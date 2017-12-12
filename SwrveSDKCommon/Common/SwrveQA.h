#import <Foundation/Foundation.h>
#import "SwrveRESTClient.h"

@interface SwrveQA : NSObject

@property (atomic) SwrveRESTClient * restClient;
@property (nonatomic, readwrite) bool isQALogging;

+(id)sharedInstance;
+(void)makeRequest:(NSMutableDictionary*)jsonBody;
+(NSMutableDictionary*)locationCampaignTriggered:(NSArray*)campaigns;
+(NSMutableDictionary*)locationCampaignDownloaded;
+(NSMutableDictionary*)locationCampaignEngagedID:(NSString*)campaignID variantID:(NSNumber*)variantID plotID:(NSString*)plotID payload:(NSDictionary*)payload;
+(void)updateQAUser:(NSDictionary*) jsonQa;

@end
