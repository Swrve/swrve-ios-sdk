#import "SwrveLocalStorage.h"
#import "SwrveCommon.h"

static NSString *SWRVE_APP_SUPPORT_DIR = @"swrve";
static NSString *SWRVE_CACHE_VERSION = @"swrve_cache_version.txt";
static NSString *SWRVE_INSTALL = @"swrve_install.txt";
static NSString *SWRVE_EVENTS = @"swrve_events.txt";
static NSString *SWRVE_CAMPAIGNS_STATE_PLIST = @"com.swrve.messages.settings.plist";
static NSString *SWRVE_USER_RESOURCES = @"srcngt2.txt";
static NSString *SWRVE_USER_RESOURCES_SGT = @"srcngtsgt2.txt";
static NSString *SWRVE_USER_RESOURCES_DIFF = @"rsdfngt2.txt";
static NSString *SWRVE_USER_RESOURCES_DIFF_SGT = @"rsdfngtsgt2.txt";
static NSString *SWRVE_CAMPAIGNS = @"cmcc2.json";
static NSString *SWRVE_CAMPAIGNS_SGT = @"cmccsgt2.txt";
static NSString *SWRVE_AD_CAMPAIGNS = @"cmcc3.json";
static NSString *SWRVE_AD_CAMPAIGNS_SGT = @"cmccsgt3.txt";
static NSString *SWRVE_PUSH_CAMPAIGNS = @"cmcc4.json";
static NSString *SWRVE_PUSH_CAMPAIGNS_SGT = @"cmccsgt4.txt";
static NSString *SWRVE_OFFLINE_CAMPAIGNS = @"cmcc5.json";
static NSString *SWRVE_OFFLINE_CAMPAIGNS_SGT = @"cmccsgt5.txt";
static NSString *SWRVE_REAL_TIME_USER_PROPERTIES = @"cmrp2s.txt";
static NSString *SWRVE_REAL_TIME_USER_PROPERTIES_SGT = @"cmrp2ssgt2.txt";
static NSString *SWRVE_ANONYMOUS_EVENTS_PLIST = @"com.swrve.events.anonymous.plist";

//NSUserDefaults Keys
static NSString *SWRVE_CR_FLUSH_FREQUENCY = @"swrve_cr_flush_frequency";
static NSString *SWRVE_CR_FLUSH_DELAY = @"swrve_cr_flush_delay";
static NSString *SWRVE_CAMPAIGN_RESOURCE_ETAG = @"campaigns_and_resources_etag";
static NSString *SWRVE_DEVICE_TOKEN = @"swrve_device_token";
static NSString *SWRVE_EVENT_SEQNUM = @"swrve_event_seqnum";
static NSString *SWRVE_USER_ID_KEY = @"swrve_user_id";
static NSString *SWRVE_TRACKING_STATE_KEY = @"swrve_tracking_state";
static NSString *SWRVE_PERMISSION_STATUS = @"swrve_permission_status";
static NSString *SWRVE_ASKED_FOR_PUSH_PERMISSIONS = @"swrve.asked_for_push_permission";
static NSString *SWRVE_INFLUENCE_DATA = @"swrve.influence_data";
static NSString *SWRVE_QA_USER = @"swrve.q1";
//this has replaced swrve_device_id and short_device_id
static NSString *SWRVE_DEVICE_UUID = @"swrve_device_uuid";
static NSString *SWRVE_BACKUP_DEFAULTS = @"swrve_backup_defaults";
static NSString *SWRVE_USERS = @"swrve_users";
static NSString *SWRVE_IDFA = @"swrve_ifda";

static dispatch_once_t applicationSupportPathOnceToken = 0;
static dispatch_once_t swrveAppSupportDirOnceToken = 0;

@implementation SwrveLocalStorage

#pragma mark - User defaults management

+ (void)resetDirectoryCreation {
    applicationSupportPathOnceToken = 0;
    swrveAppSupportDirOnceToken = 0;
}

+ (NSUserDefaults*)defaults {
    return [NSUserDefaults standardUserDefaults];
}

//// SWRVE IDFA ////

+ (void)saveIDFA:(NSString *)idfa {
    [[self defaults] setValue:idfa forKey:SWRVE_IDFA];
    [SwrveLocalStorage writeValueToDictionaryFile:SWRVE_BACKUP_DEFAULTS value:idfa key:SWRVE_IDFA];
}

+ (NSString *)idfa {
    NSString *idfa = [[self defaults] stringForKey:SWRVE_IDFA];
    if (idfa == nil) {
        idfa = [SwrveLocalStorage readValueFromDictionaryFile:SWRVE_BACKUP_DEFAULTS forKey:SWRVE_IDFA];
    }
    return idfa;
}

//// SWRVE FLUSH FREQEUNCY ////

+ (void)saveFlushFrequency:(double) flushFrequency {
    [[self defaults] setDouble:flushFrequency forKey:SWRVE_CR_FLUSH_FREQUENCY];
    [SwrveLocalStorage writeValueToDictionaryFile:SWRVE_BACKUP_DEFAULTS value:@(flushFrequency) key:SWRVE_CR_FLUSH_FREQUENCY];
}

+ (double)flushFrequency {
    double flushFrequency = [[self defaults] doubleForKey:SWRVE_CR_FLUSH_FREQUENCY];
    if (flushFrequency == 0) {
        flushFrequency = [[SwrveLocalStorage readValueFromDictionaryFile:SWRVE_BACKUP_DEFAULTS forKey:SWRVE_CR_FLUSH_FREQUENCY] doubleValue];
    }
    return flushFrequency;
}

///// SWRVE FLUSH DELAY /////

+ (void)saveflushDelay:(double) flushDelay {
    [[self defaults] setDouble:flushDelay forKey:SWRVE_CR_FLUSH_DELAY];
    [SwrveLocalStorage writeValueToDictionaryFile:SWRVE_BACKUP_DEFAULTS value:@(flushDelay) key:SWRVE_CR_FLUSH_DELAY];
}

+ (double)flushDelay {
    double flushDelay = [[self defaults] doubleForKey:SWRVE_CR_FLUSH_DELAY];
    if (flushDelay == 0) {
        flushDelay = [[SwrveLocalStorage readValueFromDictionaryFile:SWRVE_BACKUP_DEFAULTS forKey:SWRVE_CR_FLUSH_DELAY] doubleValue];
    }
    return flushDelay;
}

//// SWRVE ETAG ////

+ (void)saveETag:(NSString *)eTag forUserId:(NSString*)userId {
    if (userId == nil) { return; }
    NSString *key = [userId stringByAppendingString:SWRVE_CAMPAIGN_RESOURCE_ETAG];
    [[self defaults] setObject:eTag forKey:key];
    [SwrveLocalStorage writeValueToDictionaryFile:SWRVE_BACKUP_DEFAULTS value:eTag key:key];
}

+ (NSString *)eTagForUserId:(NSString *)userId {
    if (userId == nil) { return nil; }
    NSString *key = [userId stringByAppendingString:SWRVE_CAMPAIGN_RESOURCE_ETAG];
    NSString *eTag = [[self defaults] stringForKey:key];
    if (eTag == nil) {
        eTag = [SwrveLocalStorage readValueFromDictionaryFile:SWRVE_BACKUP_DEFAULTS forKey:key];
    }
    return eTag;
}

+ (void)removeETagForUserId:(NSString *)userId {
    if (userId == nil) { return; }
    NSString *key = [userId stringByAppendingString:SWRVE_CAMPAIGN_RESOURCE_ETAG];
    [[self defaults] removeObjectForKey:key];
    [SwrveLocalStorage removeValueFromDictionaryFile:SWRVE_BACKUP_DEFAULTS forKey:key];
}

//// SWRVE DEVICE TOKEN ////

+ (void)saveDeviceToken:(NSString*)deviceToken {
    [[self defaults] setValue:deviceToken forKey:SWRVE_DEVICE_TOKEN];
    [SwrveLocalStorage writeValueToDictionaryFile:SWRVE_BACKUP_DEFAULTS value:deviceToken key:SWRVE_DEVICE_TOKEN];
}

+ (id)deviceToken {
    id deviceToken = [[self defaults] objectForKey:SWRVE_DEVICE_TOKEN];
    if (deviceToken == nil) {
        deviceToken = [SwrveLocalStorage readValueFromDictionaryFile:SWRVE_BACKUP_DEFAULTS forKey:SWRVE_DEVICE_TOKEN];
    }
    return deviceToken;
}

+ (void)removeDeviceToken {
    [[self defaults] removeObjectForKey:SWRVE_DEVICE_TOKEN];
    [SwrveLocalStorage removeValueFromDictionaryFile:SWRVE_BACKUP_DEFAULTS forKey:SWRVE_DEVICE_TOKEN];
}

// SWRVE SEQUENCE NUMBER KEY

+ (void)saveSeqNum:(NSInteger)seqNum withCustomKey:(NSString*)key {
    [[self defaults] setInteger:seqNum forKey:key];
    [SwrveLocalStorage writeValueToDictionaryFile:SWRVE_BACKUP_DEFAULTS value:@(seqNum) key:key];
}

+ (NSInteger)seqNumWithCustomKey:(NSString*)key {
    NSInteger seqNum = [[self defaults] integerForKey:key];
    if (seqNum == 0) {
        seqNum = [[SwrveLocalStorage readValueFromDictionaryFile:SWRVE_BACKUP_DEFAULTS forKey:key] integerValue];
    }
    return seqNum;
}

+ (void)removeSeqNumWithCustomKey:(NSString*)key {
    [[self defaults] removeObjectForKey:key];
    [SwrveLocalStorage removeValueFromDictionaryFile:SWRVE_BACKUP_DEFAULTS forKey:key];
}

//// SWRVE USER ID ////

+ (void)saveSwrveUserId:(NSString *) swrveUserId {
    [[self defaults] setValue:swrveUserId forKey:SWRVE_USER_ID_KEY];
    [SwrveLocalStorage writeValueToDictionaryFile:SWRVE_BACKUP_DEFAULTS value:swrveUserId key:SWRVE_USER_ID_KEY];
}

+ (NSString *)swrveUserId {
    NSString *swrveUserId = [[self defaults] stringForKey:SWRVE_USER_ID_KEY];
    if (swrveUserId == nil) {
        swrveUserId = [SwrveLocalStorage readValueFromDictionaryFile:SWRVE_BACKUP_DEFAULTS forKey:SWRVE_USER_ID_KEY];
    }
    return swrveUserId;
}

+ (void)removeSwrveUserId {
    [[self defaults] removeObjectForKey:SWRVE_USER_ID_KEY];
    [SwrveLocalStorage removeValueFromDictionaryFile:SWRVE_BACKUP_DEFAULTS forKey:SWRVE_USER_ID_KEY];
}

//// SWRVE TRACKINGSTATE ////

+ (enum SwrveTrackingState)trackingState {
    int trackingStateInt = (int)[[self defaults] integerForKey:SWRVE_TRACKING_STATE_KEY];
    enum SwrveTrackingState trackingState = (enum SwrveTrackingState)trackingStateInt;
    if (trackingState == UNKNOWN) {
        NSNumber *trackingStateNumber = [SwrveLocalStorage readValueFromDictionaryFile:SWRVE_BACKUP_DEFAULTS forKey:SWRVE_TRACKING_STATE_KEY];
        trackingState = (enum SwrveTrackingState)trackingStateNumber.intValue;
    }
    return trackingState;
}

+ (void)saveTrackingState:(enum SwrveTrackingState)trackingState {
    NSNumber *trackingStateNumber = [NSNumber numberWithUnsignedInt:trackingState];
    [[self defaults] setValue:trackingStateNumber forKey:SWRVE_TRACKING_STATE_KEY];
    [SwrveLocalStorage writeValueToDictionaryFile:SWRVE_BACKUP_DEFAULTS value:trackingStateNumber key:SWRVE_TRACKING_STATE_KEY];
}

//// SWRVE PERMISSIONS ////

+ (void)savePermissions:(NSDictionary *) permissions {
    [[self defaults] setObject:permissions forKey:SWRVE_PERMISSION_STATUS];
    [SwrveLocalStorage writeValueToDictionaryFile:SWRVE_BACKUP_DEFAULTS value:permissions key:SWRVE_PERMISSION_STATUS];
}

+ (NSDictionary *)getPermissions {
    NSDictionary *permissions = [[self defaults] dictionaryForKey:SWRVE_PERMISSION_STATUS];
    if (permissions == nil) {
        permissions = [SwrveLocalStorage readValueFromDictionaryFile:SWRVE_BACKUP_DEFAULTS forKey:SWRVE_PERMISSION_STATUS];
    }
    return permissions;
}

//// SWRVE PERMISSIONS BOOL ////

+ (void)saveAskedForPushPermission:(bool) status {
    [[self defaults] setBool:status forKey:SWRVE_ASKED_FOR_PUSH_PERMISSIONS];
    [SwrveLocalStorage writeValueToDictionaryFile:SWRVE_BACKUP_DEFAULTS value:@(status) key:SWRVE_ASKED_FOR_PUSH_PERMISSIONS];
}

+ (bool)askedForPushPermission {
    bool askedForPushPermission = [[self defaults] boolForKey:SWRVE_ASKED_FOR_PUSH_PERMISSIONS];
    if (askedForPushPermission == false) {
        askedForPushPermission = [[SwrveLocalStorage readValueFromDictionaryFile:SWRVE_BACKUP_DEFAULTS forKey:SWRVE_ASKED_FOR_PUSH_PERMISSIONS] boolValue];
    }
    return askedForPushPermission;
}

//// SWRVE QA USER ////

+ (NSDictionary *)qaUser {
    NSString *userId = [[SwrveCommon sharedInstance] userID];
    NSString *key = [NSString stringWithFormat:@"%@%@",SWRVE_QA_USER, userId];
    NSDictionary *qaUser = [[self defaults] dictionaryForKey:key];
     if (qaUser == nil) {
         qaUser = [SwrveLocalStorage readValueFromDictionaryFile:SWRVE_BACKUP_DEFAULTS forKey:key];
     }
     return qaUser;
}

+ (void)saveQaUser:(NSDictionary *)qaUser {
    NSString *userId = [[SwrveCommon sharedInstance] userID];
    NSString *key = [NSString stringWithFormat:@"%@%@",SWRVE_QA_USER, userId];
   [[self defaults] setObject:qaUser forKey:SWRVE_QA_USER];
   [SwrveLocalStorage writeValueToDictionaryFile:SWRVE_BACKUP_DEFAULTS value:qaUser key:key];
}

//// SWRVE DEVICE UUID ////

+ (void)saveDeviceUUID:(NSString *)deviceUUID {
    [[self defaults] setValue:deviceUUID forKey:SWRVE_DEVICE_UUID];
    [SwrveLocalStorage writeValueToDictionaryFile:SWRVE_BACKUP_DEFAULTS value:deviceUUID key:SWRVE_DEVICE_UUID];
}

+ (NSString *)deviceUUID {
    NSString *deviceUUID = [[self defaults] stringForKey:SWRVE_DEVICE_UUID];
    if (deviceUUID == nil) {
        deviceUUID = [SwrveLocalStorage readValueFromDictionaryFile:SWRVE_BACKUP_DEFAULTS forKey:SWRVE_DEVICE_UUID];
    }
    return deviceUUID;
}

//// SWRVE USERS ////

+ (void)saveSwrveUsers:(NSData *)data {
    [[self defaults] setObject:data forKey:SWRVE_USERS];
    
    if (data != nil) {
        NSString *string = [data base64EncodedStringWithOptions:0];
        [SwrveLocalStorage writeValueToDictionaryFile:SWRVE_BACKUP_DEFAULTS value:string key:SWRVE_USERS];
    }
}

+ (NSData *)swrveUsers {
    NSData *data = [[self defaults] dataForKey:SWRVE_USERS];
    if (data == nil) {
        NSString *string = [SwrveLocalStorage readValueFromDictionaryFile:SWRVE_BACKUP_DEFAULTS forKey:SWRVE_USERS];
        if (string != nil) {
            data = [[NSData alloc] initWithBase64EncodedString:string options:0];
        }
    }
    return data;
}

#pragma mark - Application data management

+ (NSString *) applicationSupportPath {
// tvOS does not support writing to the application support directory, so use cache directory
#if TARGET_OS_TV
    return [SwrveLocalStorage cachePath];
#else
    static NSString *_path;
    dispatch_once(&applicationSupportPathOnceToken, ^{
        NSString *appSupportDir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
        if (![[NSFileManager defaultManager] fileExistsAtPath:appSupportDir isDirectory:NULL]) {
            NSError *error = nil;
            if (![[NSFileManager defaultManager] createDirectoryAtPath:appSupportDir withIntermediateDirectories:YES attributes:
                  [NSDictionary dictionaryWithObject:NSFileProtectionNone forKey:NSFileProtectionKey] error:&error]) {
                [SwrveLogger error:@"Error Creating an Application Support Directory %@", error.localizedDescription];
            } else {
                [SwrveLogger debug:@"Successfully Created Directory: %@", appSupportDir];
            }
        }
        _path = appSupportDir;
    });
    
    return _path;
#endif
}

+ (NSString *)cachePath {
    static NSString *_path;
    static dispatch_once_t doOnceToken;
    dispatch_once(&doOnceToken, ^{
        _path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    });
    
    return _path;
}

+ (NSString *)documentPath {
    static NSString *_path;
    static dispatch_once_t doOnceToken;
    dispatch_once(&doOnceToken, ^{
        _path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    });
    
    return _path;
}

+ (NSString *)swrveAppSupportDir {
    static NSString *_path;
    dispatch_once(&swrveAppSupportDirOnceToken, ^{
        NSString *appSupportDir = [SwrveLocalStorage applicationSupportPath];
        NSString *swrveAppSupportDir = [appSupportDir stringByAppendingPathComponent:SWRVE_APP_SUPPORT_DIR];
        if (![[NSFileManager defaultManager] fileExistsAtPath:swrveAppSupportDir isDirectory:NULL]) {
            NSError *error = nil;
            [[NSFileManager defaultManager] createDirectoryAtPath:swrveAppSupportDir withIntermediateDirectories:YES attributes:@{NSFileProtectionKey:NSFileProtectionNone} error:&error];
            if (error == nil) {
                [SwrveLogger debug:@"First time migration or installation. Created Swrve app support directory", nil];
            }
        }
        _path = swrveAppSupportDir;
    });
    
    return _path;
}

+ (NSString *)swrveCacheVersionFilePath {
    NSString *swrveAppSupportDir = [SwrveLocalStorage swrveAppSupportDir];
    return [swrveAppSupportDir stringByAppendingPathComponent:SWRVE_CACHE_VERSION];
}

+ (UInt64)appInstallTimeSeconds {
    return [SwrveLocalStorage userJoinedTimeSeconds:@""]; // pass empty string as app Install time is saved with no id
}

// Get the time that the user first joined the app. This value is stored in a file and might be different to app install
// time if multiple users are identified. If this file is not available then 0 is returned.
+ (UInt64)userJoinedTimeSeconds:(NSString *)userId {
    
    NSString *logMessage = ([userId isEqualToString:@""]) ? @"App install time:" : @"User Joined time:";
#pragma unused(logMessage) // for when debuglog is off

    unsigned long long seconds = 0;
#if TARGET_OS_TV
    NSString *installDateKey = [userId stringByAppendingString:SWRVE_INSTALL];
    if (!installDateKey) {
        installDateKey = SWRVE_INSTALL;
    }
    seconds = [[self defaults] integerForKey:installDateKey];
    unsigned long long secondsSinceEpoch = (unsigned long long)([[NSDate date] timeIntervalSince1970]);
    if(seconds > secondsSinceEpoch){
        [SwrveLogger warning:@"%@ from current file_contents was in milliseconds. restoring as seconds", logMessage];
        seconds = seconds / 1000;
        if (seconds > secondsSinceEpoch) {
            [SwrveLogger warning:@"%@ from current file_contents was corrupted. setting as today", logMessage];
            //install time stored was corrupted and must be added as today.
            seconds = secondsSinceEpoch;
        }
        [[self defaults] setInteger:seconds forKey:installDateKey];
    }
#else
    NSError *error = nil;
    NSString *fileName = [SwrveLocalStorage userInitDateFilePath:userId];
    NSString *file_contents = [[NSString alloc] initWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:&error];
    if (!error && file_contents) {
        seconds = (unsigned long long)[file_contents longLongValue];
        unsigned long long secondsSinceEpoch = (unsigned long long)([[NSDate date] timeIntervalSince1970]);
        // ensure the install time is stored in seconds, legacy from < iOS SDK 4.7
        if (seconds > secondsSinceEpoch) {
            [SwrveLogger warning:@"%@ from current file_contents was in milliseconds. restoring as seconds", logMessage];
            seconds = seconds / 1000;
            if (seconds > secondsSinceEpoch) {
                [SwrveLogger warning:@"%@ from current file_contents was corrupted. setting as today", logMessage];
                //install time stored was corrupted and must be added as today.
                seconds = secondsSinceEpoch;
            }

            file_contents = [NSString stringWithFormat:@"%llu", seconds];
            
            error = nil;
            BOOL success = [file_contents writeToFile:fileName atomically:YES encoding:NSUTF8StringEncoding error:&error];
            if (!success) {
                [SwrveLogger error:@"%@ could not be saved to fileName: %@ %@", logMessage, [fileName lastPathComponent], error];
            } else {
                [SwrveLocalStorage setFileProtectionNone:fileName];
            }
        }

    } else {
        [SwrveLogger error:@"%@ could not read file: %@", logMessage, [fileName lastPathComponent]];
    }
#endif
   return (UInt64)seconds;
}

+ (void)saveAppInstallTime:(UInt64)appInstallTime {
    [SwrveLocalStorage saveUserJoinedTime:appInstallTime forUserId:@""]; // pass empty string to save app install time for all users
}

+ (void)saveUserJoinedTime:(UInt64)userInitTime forUserId:(NSString *) userId {
#if TARGET_OS_TV
    NSString *installDateKey = [userId stringByAppendingString:SWRVE_INSTALL];
    [[self defaults] setInteger:userInitTime forKey:installDateKey];
#else
    NSString *fileName = [SwrveLocalStorage userInitDateFilePath:userId];
    NSString *currentTime = [NSString stringWithFormat:@"%llu", userInitTime];
    NSError *error = nil;
    BOOL success = [currentTime writeToFile:fileName atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    NSString *logMessage = ([userId isEqualToString:@""]) ? @"App install time:" : @"User Joined time:";
#pragma unused(logMessage) // for when debuglog is off
    if (success) {
        [SwrveLogger debug:@"%@ successfully saved to fileName: %@", logMessage, [fileName lastPathComponent]];
        [SwrveLocalStorage setFileProtectionNone:fileName];
    } else {
        [SwrveLogger error:@"%@ could not be saved to fileName: %@ %@", logMessage, [fileName lastPathComponent], error];
    }
#endif
}

+ (NSString *)userInitDateFilePath:(NSString*)userId {
    NSString *documentPath = [SwrveLocalStorage documentPath];
    NSString *installDateFileName = [userId stringByAppendingString:SWRVE_INSTALL];
    return [documentPath stringByAppendingPathComponent: installDateFileName];
}

+ (NSString *)eventsFilePathForUserId:(NSString *)userId {
    return [self applicationSupportFileForUserId:userId andName:SWRVE_EVENTS];
}

+ (NSString *)campaignsFilePathForUserId:(NSString*) userId {
    return [self applicationSupportFileForUserId:userId andName:SWRVE_CAMPAIGNS];
}

+ (NSString *)campaignsSignatureFilePathForUserId:(NSString *)userId {
    return [self applicationSupportFileForUserId:userId andName:SWRVE_CAMPAIGNS_SGT];
}

+ (NSString *)campaignsAdFilePathForUserId:(NSString *) userId {
    return [self applicationSupportFileForUserId:userId andName:SWRVE_AD_CAMPAIGNS];
}

+ (NSString *)campaignsAdSignatureFilePathForUserId:(NSString*) userId {
    return [self applicationSupportFileForUserId:userId andName:SWRVE_AD_CAMPAIGNS_SGT];
}

+ (NSString *)debugCampaignsNoticationFilePathForUserId:(NSString *) userId {
    return [self applicationSupportFileForUserId:userId andName:SWRVE_PUSH_CAMPAIGNS];
}

+ (NSString *)debugCampaignsNotificationSignatureFilePathForUserId:(NSString *) userId {
    return [self applicationSupportFileForUserId:userId andName:SWRVE_PUSH_CAMPAIGNS_SGT];
}

+ (NSString *)campaignsStateFilePathForUserId:(NSString *)userId {
    return [self applicationSupportFileForUserId:userId andName:SWRVE_CAMPAIGNS_STATE_PLIST];
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
    return [swrveAppSupportDir stringByAppendingPathComponent: userIdFileName];
}

+ (NSString *)anonymousEventsFilePath {
    NSString *swrveAppSupportDir = [SwrveLocalStorage swrveAppSupportDir];
    return [swrveAppSupportDir stringByAppendingPathComponent:SWRVE_ANONYMOUS_EVENTS_PLIST];
}

+ (NSString *)swrveCacheFolder {
    static NSString *_path;
    static dispatch_once_t doOnceToken;
    dispatch_once(&doOnceToken, ^{
        NSString *cacheRoot = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        _path = [cacheRoot stringByAppendingPathComponent:@"com.ngt.msgs"];
    });
    
    return _path;
}

+ (NSString *)offlineCampaignsFilePathForUserId:(NSString *)userId {
    return [self applicationSupportFileForUserId:userId andName:SWRVE_OFFLINE_CAMPAIGNS];
}

+ (NSString *)offlineCampaignsSignatureFilePathForUserId:(NSString *)userId {
    return [self applicationSupportFileForUserId:userId andName:SWRVE_OFFLINE_CAMPAIGNS_SGT];
}

+ (NSString *)realTimeUserPropertiesFilePathForUserId:(NSString *)userId {
    return [self applicationSupportFileForUserId:userId andName:SWRVE_REAL_TIME_USER_PROPERTIES];
}

+ (NSString *)offlineRealTimeUserPropertiesSignatureFilePathForUserId:(NSString *)userId {
    return [self applicationSupportFileForUserId:userId andName:SWRVE_REAL_TIME_USER_PROPERTIES_SGT];
}

+ (id)readValueFromDictionaryFile:(NSString *)fileName forKey:(NSString *)key {
    if (fileName == nil || key == nil) return nil;
    NSString *rootPath = [SwrveLocalStorage applicationSupportPath];
    NSString *filePath = [rootPath stringByAppendingPathComponent:fileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSMutableDictionary *dictionary = [NSMutableDictionary new];
        @synchronized (self) {
            NSData *dataFile = [NSData dataWithContentsOfFile:filePath];
            if (dataFile != nil) {
                NSError *error;
                dictionary = [NSJSONSerialization JSONObjectWithData:dataFile
                                                             options:NSJSONReadingMutableContainers
                                                               error:&error];
                if (error) {
                    [SwrveLogger error:@"Swrve: Unable to read from file name: %@, error: %@",fileName, [error localizedDescription]];
                    return nil;
                }
            }
        }
        return [dictionary objectForKey:key];
    }
    return nil;
}

+ (void)writeValueToDictionaryFile:(NSString*)fileName value:(id)value key:(NSString*)key {
    [SwrveLocalStorage valueToDictionaryFileModfy:fileName value:value key:key remove:NO];
}

+ (void)removeValueFromDictionaryFile:(NSString *)fileName forKey:(NSString *)key {
    [SwrveLocalStorage valueToDictionaryFileModfy:fileName value:nil key:key remove:YES];
}

+ (void)valueToDictionaryFileModfy:(NSString*)fileName value:(id)value key:(NSString*)key remove:(bool)remove {
    if (fileName == nil || (!remove && value == nil) || key == nil) return;
    NSString *rootPath = [SwrveLocalStorage applicationSupportPath];
    NSString *filePath = [rootPath stringByAppendingPathComponent:fileName];
    
    NSError *error;
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    
    @synchronized (self) {
        NSData *dataFile = [NSData dataWithContentsOfFile:filePath];
        if (dataFile != nil) {
            dictionary = [NSJSONSerialization JSONObjectWithData:dataFile
                                                         options:NSJSONReadingMutableContainers
                                                           error:&error];
            if (error) {
                [SwrveLogger error:@"Swrve: Unable to write to file name: %@, error: %@",fileName, [error localizedDescription]];
                return;
            }
        }
        
        if (remove) {
            [dictionary removeObjectForKey:key];
        } else {
            [dictionary setObject:value forKey:key];
        }
        
        NSData *dataFromDict = [NSJSONSerialization dataWithJSONObject:dictionary
                                                               options:NSJSONWritingPrettyPrinted
                                                                 error:&error];
        if (error) {
            [SwrveLogger error:@"Swrve: Unable to write to file name: %@, error: %@",fileName, [error localizedDescription]];
             return;
         }
        
        [dataFromDict writeToFile:filePath options:NSDataWritingFileProtectionNone error:&error];
        if (error) {
            [SwrveLogger error:@"Swrve: Unable to write to file name: %@, error: %@",fileName, [error localizedDescription]];
        }
    }
}

+ (void)setFileProtectionNone:(NSString *)filePath {
    NSError *error = nil;
    BOOL success = [[NSFileManager defaultManager] setAttributes:@{NSFileProtectionKey: NSFileProtectionNone} ofItemAtPath:filePath error:&error];
    if (success == YES) {
        [SwrveLogger debug:@"Successfully set NSFileProtectionNone on file: %@", [filePath lastPathComponent]];
    } else {
        [SwrveLogger error:@"Error setting NSFileProtectionNone on file: %@ error: %@", [filePath lastPathComponent], [error localizedDescription]];
    }
}

@end
