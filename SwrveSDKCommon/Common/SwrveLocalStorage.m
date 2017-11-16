#import "SwrveLocalStorage.h"
#import "SwrveCommon.h"

static NSString* SWRVE_APP_SUPPORT_DIR = @"swrve";
static NSString* SWRVE_CACHE_VERSION = @"swrve_cache_version.txt";
static NSString* SWRVE_INSTALL = @"swrve_install.txt";
static NSString* SWRVE_EVENTS = @"swrve_events.txt";
static NSString* SWRVE_CAMPAIGNS_STATE_PLIST = @"com.swrve.messages.settings.plist";
static NSString* SWRVE_LOCATION_CAMPAIGNS = @"lc.txt";
static NSString* SWRVE_LOCATION_CAMPAIGNS_SGT = @"lcsgt.txt";
static NSString* SWRVE_USER_RESOURCES = @"srcngt2.txt";
static NSString* SWRVE_USER_RESOURCES_SGT = @"srcngtsgt2.txt";
static NSString* SWRVE_USER_RESOURCES_DIFF = @"rsdfngt2.txt";
static NSString* SWRVE_USER_RESOURCES_DIFF_SGT = @"rsdfngtsgt2.txt";
static NSString* SWRVE_CAMPAIGNS = @"cmcc2.json";
static NSString* SWRVE_CAMPAIGNS_SGT = @"cmccsgt2.txt";
static NSString* SWRVE_ANONYMOUS_EVENTS_PLIST = @"com.swrve.events.anonymous.plist";

//NSUserDefaults Keys
static NSString* SWRVE_CR_FLUSH_FREQUENCY = @"swrve_cr_flush_frequency";
static NSString* SWRVE_CR_FLUSH_DELAY = @"swrve_cr_flush_delay";
static NSString* SWRVE_CAMPAIGN_RESOURCE_ETAG = @"campaigns_and_resources_etag";
static NSString* SWRVE_DEVICE_TOKEN = @"swrve_device_token";
static NSString* SWRVE_EVENT_SEQNUM = @"swrve_event_seqnum";
// old version was @"swrve_device_id", was changed in migration0 see migration manager
static NSString* SWRVE_SHORT_DEVICE_ID =  @"short_device_id";
static NSString* SWRVE_USER_ID_KEY = @"swrve_user_id";
static NSString* SWRVE_PERMISSION_STATUS = @"swrve_permission_status";
static NSString* SWRVE_ASKED_FOR_PUSH_PERMISSIONS = @"swrve.asked_for_push_permission";
static NSString* SWRVE_INFLUENCE_DATA = @"swrve.influence_data";

@implementation SwrveLocalStorage

#pragma mark - User defaults management

+ (NSUserDefaults*)defaults {
    return [NSUserDefaults standardUserDefaults];
}

//// SWRVE FLUSH FREQEUNCY ////

+ (void)saveFlushFrequency:(double) flushFrequency {
    [[self defaults] setDouble:flushFrequency forKey:SWRVE_CR_FLUSH_FREQUENCY];
}

+ (double)flushFrequency {
    return [[self defaults] doubleForKey:SWRVE_CR_FLUSH_FREQUENCY];
}

///// SWRVE FLUSH DELAY /////

+ (void)saveflushDelay:(double) flushDelay {
    [[self defaults] setDouble:flushDelay forKey:SWRVE_CR_FLUSH_DELAY];
}

+ (double)flushDelay {
    return  [[self defaults] doubleForKey:SWRVE_CR_FLUSH_DELAY];
}

//// SWRVE ETAG ////

+ (void)saveETag:(NSString*)eTag {
    [[self defaults] setValue:eTag forKey:SWRVE_CAMPAIGN_RESOURCE_ETAG];
}

+ (NSString *)eTag {
    return [[self defaults] stringForKey:SWRVE_CAMPAIGN_RESOURCE_ETAG];
}

+ (void)removeETag {
     [[self defaults] removeObjectForKey:SWRVE_CAMPAIGN_RESOURCE_ETAG];
}

//// SWRVE DEVICE TOKEN ////

+ (void)saveDeviceToken:(NSString*)deviceToken {
    [[self defaults] setValue:deviceToken forKey:SWRVE_DEVICE_TOKEN];
}

+ (id)deviceToken {
    return [[self defaults] objectForKey:SWRVE_DEVICE_TOKEN];
}

+ (void)removeDeviceToken {
    [[self defaults] removeObjectForKey:SWRVE_DEVICE_TOKEN];
}

// SWRVE SEQUENCE NUMBER KEY

+ (void)saveSeqNum:(NSInteger)seqNum withCustomKey:(NSString*)key {
    [[self defaults] setInteger:seqNum forKey:key];
}

+ (NSInteger)seqNumWithCustomKey:(NSString*)key {
    return [[self defaults] integerForKey:key];
}

+ (void)removeSeqNumWithCustomKey:(NSString*)key {
    [[self defaults] removeObjectForKey:key];
}

//// SWRVE SHORT DEVICE ID ////

+ (void)saveShortDeviceID:(NSNumber*)deviceID {
    [[self defaults] setObject:deviceID forKey:SWRVE_SHORT_DEVICE_ID];
}

+ (NSNumber*)shortDeviceID {
    return [[self defaults] objectForKey:SWRVE_SHORT_DEVICE_ID];
}

+ (void)removeShortDeviceID {
   [[self defaults]removeObjectForKey:SWRVE_SHORT_DEVICE_ID];
}

//// SWRVE USER ID ////

+ (void)saveSwrveUserId:(NSString *) swrveUserId {
    [[self defaults] setValue:swrveUserId forKey:SWRVE_USER_ID_KEY];
}

+ (NSString *)swrveUserId {
    return [[self defaults] stringForKey:SWRVE_USER_ID_KEY];
}

+ (void)removeSwrveUserId {
    [[self defaults] removeObjectForKey:SWRVE_USER_ID_KEY];
}

//// SWRVE PERMISSIONS ////

+ (void)savePermissions:(NSDictionary *) permissions {
    [[self defaults] setObject:permissions forKey:SWRVE_PERMISSION_STATUS];
}

+ (NSDictionary *)getPermissions {
    return [[self defaults] dictionaryForKey:SWRVE_PERMISSION_STATUS];
}

//// SWRVE PERMISSIONS BOOL ////

+ (void)saveAskedForPushPermission:(bool) status {
    [[self defaults] setBool:status forKey:SWRVE_ASKED_FOR_PUSH_PERMISSIONS];
}

+ (bool)askedForPushPermission {
    return [[self defaults] boolForKey:SWRVE_ASKED_FOR_PUSH_PERMISSIONS];
}

#pragma mark - Application data management

+ (NSString *) applicationSupportPath {

    NSString *appSupportDir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    if (![[NSFileManager defaultManager] fileExistsAtPath:appSupportDir isDirectory:NULL]) {
        NSError *error = nil;
        if (![[NSFileManager defaultManager] createDirectoryAtPath:appSupportDir withIntermediateDirectories:YES attributes:
              [NSDictionary dictionaryWithObject:NSFileProtectionNone forKey:NSFileProtectionKey] error:&error]) {
            DebugLog(@"Error Creating an Application Support Directory %@", error.localizedDescription);
        } else {
            DebugLog(@"Successfully Created Directory: %@", appSupportDir);
        }
    }
    return appSupportDir;
}

+ (NSString *)cachePath {
    return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
}

+ (NSString *)documentPath {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
}

+ (NSString *)swrveAppSupportDir {
    NSString *appSupportDir = [SwrveLocalStorage applicationSupportPath];
    NSString *swrveAppSupportDir = [appSupportDir stringByAppendingPathComponent:SWRVE_APP_SUPPORT_DIR];
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:swrveAppSupportDir withIntermediateDirectories:YES attributes:nil error:&error];
    if (error == nil) {
        DebugLog(@"First time migration or installation. Created Swrve app support directory:%@.", swrveAppSupportDir);
    }
    return swrveAppSupportDir;
}

+ (NSString *)swrveCacheVersionFilePath {
    NSString *swrveAppSupportDir = [SwrveLocalStorage swrveAppSupportDir];
    NSString *swrveCacheVersionFilePath = [swrveAppSupportDir stringByAppendingPathComponent:SWRVE_CACHE_VERSION];
    return swrveCacheVersionFilePath;
}

// Get the time that the application was first installed. This value is stored in a file. If this file is not available
// then 0 is returned.
+ (UInt64)installTimeForUserId:(NSString*) userId {
    unsigned long long seconds = 0;

    NSError* error = nil;
    NSString *fileName = [SwrveLocalStorage installDateFilePathForUserId:userId];
    NSString* file_contents = [[NSString alloc] initWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:&error];
    if (!error && file_contents) {
        seconds = (unsigned long long)[file_contents longLongValue];
        unsigned long long secondsSinceEpoch = (unsigned long long)([[NSDate date] timeIntervalSince1970]);
        // ensure the install time is stored in seconds, legacy from < iOS SDK 4.7
        if(seconds > secondsSinceEpoch){
            DebugLog(@"install_time from current file_contents was in milliseconds. restoring as seconds");
            seconds = seconds / 1000;
            if(seconds > secondsSinceEpoch){
                DebugLog(@"install_time from current file_contents was corrupted. setting as today");
                //install time stored was corrupted and must be added as today.
                seconds = secondsSinceEpoch;
            }

            file_contents = [NSString stringWithFormat:@"%llu", seconds];
            [file_contents writeToFile:fileName atomically:YES encoding:NSUTF8StringEncoding error:nil];
        }

    } else {
        DebugLog(@"Install time: could not read file: %@", fileName);
    }

   return (UInt64)seconds;
}

+ (void)saveInstallTime:(UInt64)installTime forUserId:(NSString*) userId {
    NSString *fileName = [SwrveLocalStorage installDateFilePathForUserId:userId];
    NSString *currentTime = [NSString stringWithFormat:@"%llu", installTime];
    BOOL success = [currentTime writeToFile:fileName atomically:YES encoding:NSUTF8StringEncoding error:nil];
    if (success) {
        DebugLog(@"Install time: successfully saved install time to fileName:%@", fileName);
    } else {
        DebugLog(@"Install time: could not save install time to fileName:%@", fileName);
    }
}

+ (NSString *)installDateFilePathForUserId:(NSString*) userId {
    NSString *documentPath = [SwrveLocalStorage documentPath];
    NSString *installDateFileName = [userId stringByAppendingString:SWRVE_INSTALL];
    NSString *installDateFilePath = [documentPath stringByAppendingPathComponent: installDateFileName];
    return installDateFilePath;
}

+ (NSString *)eventsFilePathForUserId:(NSString *)userId {
    return [self applicationSupportFileForUserId:userId andName:SWRVE_EVENTS];
}

+ (NSString *)campaignsFilePathForUserId:(NSString*) userId {
    return [self applicationSupportFileForUserId:userId andName:SWRVE_CAMPAIGNS];
}

+ (NSString *)campaignsSignatureFilePathForUserId:(NSString*) userId {
    return [self applicationSupportFileForUserId:userId andName:SWRVE_CAMPAIGNS_SGT];
}

+ (NSString *)campaignsStateFilePathForUserId:(NSString*) userId {
    return [self applicationSupportFileForUserId:userId andName:SWRVE_CAMPAIGNS_STATE_PLIST];
}

+ (NSString *)locationCampaignFilePathForUserId:(NSString*) userId {
    return [self applicationSupportFileForUserId:userId andName:SWRVE_LOCATION_CAMPAIGNS];
}

+ (NSString *)locationCampaignSignatureFilePathForUserId:(NSString*) userId {
    return [self applicationSupportFileForUserId:userId andName:SWRVE_LOCATION_CAMPAIGNS_SGT];
}

+ (NSString *)userResourcesFilePathForUserId:(NSString*) userId {
    return [self applicationSupportFileForUserId:userId andName:SWRVE_USER_RESOURCES];
}

+ (NSString *)userResourcesSignatureFilePathForUserId:(NSString*) userId {
    return [self applicationSupportFileForUserId:userId andName:SWRVE_USER_RESOURCES_SGT];
}

+ (NSString *)userResourcesDiffFilePathForUserId:(NSString*) userId {
    return [self applicationSupportFileForUserId:userId andName:SWRVE_USER_RESOURCES_DIFF];
}

+ (NSString *)userResourcesDiffSignatureFilePathForUserId:(NSString*) userId {
    return [self applicationSupportFileForUserId:userId andName:SWRVE_USER_RESOURCES_DIFF_SGT];
}

+ (NSString *)applicationSupportFileForUserId:(NSString *)userId andName:(NSString *)fileName {
    NSString *swrveAppSupportDir = [SwrveLocalStorage swrveAppSupportDir];
    NSString *userIdFileName = [userId stringByAppendingString:fileName];
    NSString *pathUserIdFileName = [swrveAppSupportDir stringByAppendingPathComponent: userIdFileName];
    return pathUserIdFileName;
}

+ (NSString *)anonymousEventsFilePath {
    NSString *swrveAppSupportDir = [SwrveLocalStorage swrveAppSupportDir];
    return [swrveAppSupportDir stringByAppendingPathComponent:SWRVE_ANONYMOUS_EVENTS_PLIST];
}

+ (NSString *)swrveCacheFolder {
    NSString *cacheRoot = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *swrve_folder = @"com.ngt.msgs";
    NSString *cacheFolder = [cacheRoot stringByAppendingPathComponent:swrve_folder];
    return cacheFolder;
}

@end
