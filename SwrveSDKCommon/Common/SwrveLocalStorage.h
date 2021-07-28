#import <Foundation/Foundation.h>

enum SwrveTrackingState {
    UNKNOWN = 0,
    STARTED = 1,
    EVENT_SENDING_PAUSED = 2,
    STOPPED = 3
};

@interface SwrveLocalStorage : NSObject

+ (void)resetDirectoryCreation;
+ (NSString *)applicationSupportPath;
+ (NSString *)cachePath;
+ (NSString *)documentPath;
+ (NSString *)swrveAppSupportDir;
+ (NSString *)swrveCacheVersionFilePath;
+ (UInt64)userJoinedTimeSeconds:(NSString *)userId;
+ (void)saveUserJoinedTime:(UInt64)userInitTime forUserId:(NSString *)userId;
+ (UInt64)appInstallTimeSeconds;
+ (void)saveAppInstallTime:(UInt64)appInstallTime;
+ (NSString *)userInitDateFilePath:(NSString*)userId;
+ (NSString *)eventsFilePathForUserId:(NSString *)userId;
+ (NSString *)campaignsFilePathForUserId:(NSString *)userId;
+ (NSString *)campaignsSignatureFilePathForUserId:(NSString *)userId;
+ (NSString *)campaignsStateFilePathForUserId:(NSString *)userId;
+ (NSString *)campaignsAdFilePathForUserId:(NSString *)userId;
+ (NSString *)campaignsAdSignatureFilePathForUserId:(NSString *)userId;
+ (NSString *)debugCampaignsNoticationFilePathForUserId:(NSString *)userId;
+ (NSString *)debugCampaignsNotificationSignatureFilePathForUserId:(NSString *)userId;
+ (NSString *)userResourcesFilePathForUserId:(NSString *) userId ;
+ (NSString *)userResourcesSignatureFilePathForUserId:(NSString *) userId;
+ (NSString *)userResourcesDiffFilePathForUserId:(NSString *) userId;
+ (NSString *)userResourcesDiffSignatureFilePathForUserId:(NSString *) userId;
+ (NSString *)anonymousEventsFilePath;
+ (NSString *)swrveCacheFolder;
+ (NSString *)offlineCampaignsFilePathForUserId:(NSString *)userId;
+ (NSString *)offlineCampaignsSignatureFilePathForUserId:(NSString *)userId;
+ (NSString *)realTimeUserPropertiesFilePathForUserId:(NSString *)userId;
+ (NSString *)offlineRealTimeUserPropertiesSignatureFilePathForUserId:(NSString *)userId;
+ (void)setFileProtectionNone:(NSString *)filePath;

//NSUserdefaults
+ (double)flushFrequency;
+ (void)saveFlushFrequency:(double)flushFrequency;
+ (double)flushDelay;
+ (void)saveflushDelay:(double)flushDelay;
+ (void)saveETag:(NSString *)eTag forUserId:(NSString *)userId;
+ (NSString *)eTagForUserId:(NSString *)userId;
+ (void)removeETagForUserId:(NSString *)userId;
+ (id)deviceToken;
+ (void)saveDeviceToken:(NSString *)deviceToken;
+ (void)removeDeviceToken;
+ (void)saveSeqNum:(NSInteger)seqNum withCustomKey:(NSString *)key;
+ (NSInteger)seqNumWithCustomKey:(NSString *)key;
+ (void)removeSeqNumWithCustomKey:(NSString *)key;
+ (void)saveSwrveUserId:(NSString *)swrveUserId;
+ (NSString *)swrveUserId;
+ (void)removeSwrveUserId;
+ (enum SwrveTrackingState)trackingState;
+ (void)saveTrackingState:(enum SwrveTrackingState)trackingState;
+ (void)savePermissions:(NSDictionary *)permissions;
+ (NSDictionary *)getPermissions;
+ (void)saveAskedForPushPermission:(bool)status;
+ (bool)askedForPushPermission;
+ (NSDictionary *)qaUser;
+ (void)saveQaUser:(NSDictionary *)qaUser;
+ (void)saveDeviceUUID:(NSString *)deviceUUID;
+ (NSString *)deviceUUID;
+ (void)saveSwrveUsers:(NSData *)data;
+ (NSData *)swrveUsers;
+ (void)saveIDFA:(NSString *)idfa;
+ (NSString *)idfa;

@end
