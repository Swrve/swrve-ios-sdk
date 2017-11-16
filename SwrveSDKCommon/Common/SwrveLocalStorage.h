#import <Foundation/Foundation.h>

@interface SwrveLocalStorage : NSObject

+ (NSString *)applicationSupportPath;
+ (NSString *)cachePath;
+ (NSString *)documentPath;
+ (NSString *)swrveAppSupportDir;
+ (NSString *)swrveCacheVersionFilePath;
+ (UInt64)installTimeForUserId:(NSString*) userId;
+ (void)saveInstallTime:(UInt64)installTime forUserId:(NSString*) userId;
+ (NSString *)installDateFilePathForUserId:(NSString*) userId;
+ (NSString *)eventsFilePathForUserId:(NSString*) userId;
+ (NSString *)campaignsFilePathForUserId:(NSString*) userId;
+ (NSString *)campaignsSignatureFilePathForUserId:(NSString*) userId ;
+ (NSString *)campaignsStateFilePathForUserId:(NSString*) userId;
+ (NSString *)locationCampaignFilePathForUserId:(NSString*) userId ;
+ (NSString *)locationCampaignSignatureFilePathForUserId:(NSString*) userId ;
+ (NSString *)userResourcesFilePathForUserId:(NSString*) userId ;
+ (NSString *)userResourcesSignatureFilePathForUserId:(NSString*) userId ;
+ (NSString *)userResourcesDiffFilePathForUserId:(NSString*) userId ;
+ (NSString *)userResourcesDiffSignatureFilePathForUserId:(NSString*) userId ;
+ (NSString *)anonymousEventsFilePath;
+ (NSString *)swrveCacheFolder;


//NSUserdefaults
+ (double)flushFrequency;
+ (void)saveFlushFrequency:(double)flushFrequency;
+ (double)flushDelay;
+ (void)saveflushDelay:(double)flushDelay;
+ (NSString *)eTag;
+ (void)saveETag:(NSString*)eTag;
+ (void)removeETag;
+ (id)deviceToken;
+ (void)saveDeviceToken:(NSString*)deviceToken;
+ (void)removeDeviceToken;
+ (void)saveSeqNum:(NSInteger)seqNum withCustomKey:(NSString*)key;
+ (NSInteger)seqNumWithCustomKey:(NSString*)key;
+ (void)removeSeqNumWithCustomKey:(NSString*)key;
+ (void)saveShortDeviceID:(NSNumber*)deviceID;
+ (NSNumber*)shortDeviceID;
+ (void)removeShortDeviceID;
+ (void)saveSwrveUserId:(NSString *) swrveUserId;
+ (NSString *)swrveUserId;
+ (void)removeSwrveUserId;
+ (void)savePermissions:(NSDictionary *) permissions;
+ (NSDictionary *)getPermissions;
+ (void)saveAskedForPushPermission:(bool) status;
+ (bool)askedForPushPermission;

@end
