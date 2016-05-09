#import "SwrveCommon.h"

void UnitySendMessage(const char *, const char *, const char *);

#ifdef SWRVE_LOCATION_SDK
#import "SwrvePlot.h"
@interface UnitySwrveCommonDelegate : NSObject<SwrveCommonDelegate, PlotDelegate>
#else
@interface UnitySwrveCommonDelegate : NSObject<SwrveCommonDelegate>
#endif

+(UnitySwrveCommonDelegate*) sharedInstance;
+(void) init:(char*)jsonConfig;

-(void) initLocation;

-(long) appId;
-(NSString*) apiKey;

-(NSString*) applicationPath;
-(NSString*) locTag;
-(NSString*) sigSuffix;
-(NSString*) userId;
-(NSString*) appVersion;
-(NSString*) uniqueKey;
-(NSString*) getLocationPath;

-(NSString*) batchUrl;
-(NSString*) eventsServer;

-(NSURL*) getBatchUrl;
-(int) httpTimeout;

-(NSData*) getCampaignData:(int)category;

-(void) setLocationVersion:(NSString *)version;
-(int) userUpdate:(NSDictionary *)attributes;
-(void) shutdown;

@end
