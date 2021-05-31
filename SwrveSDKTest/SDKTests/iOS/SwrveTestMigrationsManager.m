#import <XCTest/XCTest.h>
#import "SwrveMigrationsManager.h"
#import "SwrveTestHelper.h"
#import "SwrveProfileManager.h"
#import "SwrveRESTClient.h"
#import "SwrveUser.h"
#import "SwrveMessageController.h"

@interface SwrveProfileManager ()
- (instancetype)initWithIdentityUrl:(NSString *)identityBaseUrl deviceUUID:(NSString *)deviceUUID restClient:(SwrveRESTClient *)restClient appId:(long)appId apiKey:(NSString*)apiKey;
@end

@interface SwrveMigrationsManager (SwrveInternalAccess)
- (int)currentCacheVersion;
+ (void)setCurrentCacheVersion:(int)cacheVersion;
- (void)migrateOldCacheFile:(NSString *)oldPath withNewPath:(NSString *)newPath;

@property(nonatomic) NSString *cacheVersionFilePath;
@end

@interface Swrve (Internal)
@property(atomic) SwrveSignatureProtectedFile *resourcesFile;
@property(atomic) SwrveSignatureProtectedFile *resourcesDiffFile;
@property(atomic) SwrveSignatureProtectedFile *realTimeUserPropertiesFile;
- (UInt64)joinedDateMilliSeconds;
- (UInt64)appInstallTimeSeconds;
- (UInt64)userJoinedTimeSeconds;
- (NSString *)signatureKey;
@end

@interface SwrveMessageController (SwrveMessageControllerInternal)
@property (nonatomic, retain) SwrveSignatureProtectedFile* campaignFile;
@end


@interface SwrveSignatureProtectedFile (SwrveSignatureProtectedFileInternal)
- (NSData*) createHMACWithMD5:(NSData*)source;
@end


@interface SwrveTestMigrationsManager : XCTestCase

@end

@implementation SwrveTestMigrationsManager

- (void)setUp {
    [super setUp];
    [SwrveTestHelper setUp];
    [SwrveLocalStorage resetDirectoryCreation];
}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [super tearDown];
}

- (void)testMigrate0_old_device_ids_deleted {
    
    [SwrveLocalStorage saveSwrveUserId:@"fake_user"]; // Fake user, migrations only run for existing installations
    [[NSUserDefaults standardUserDefaults] setObject:@1234 forKey:@"swrve_device_id"];
    [[NSUserDefaults standardUserDefaults] setObject:@4567 forKey:@"short_device_id"];
    
    SwrveConfig *swrveConfig = [[SwrveConfig alloc] init];
    ImmutableSwrveConfig *immutableSwrveConfig = [[ImmutableSwrveConfig alloc] initWithMutableConfig:swrveConfig];
    SwrveMigrationsManager *swrveMigrationsManager = [[SwrveMigrationsManager alloc] initWithConfig:immutableSwrveConfig];
    [swrveMigrationsManager checkMigrations];
    
    NSString *oldShortDeviceIdKey1 = @"swrve_device_id";
    NSString *oldShortDeviceId1 =  [[NSUserDefaults standardUserDefaults] stringForKey:oldShortDeviceIdKey1];
    XCTAssertNil(oldShortDeviceId1);
    
    NSString *oldShortDeviceIdKey2 = @"short_device_id";
    NSString *oldShortDeviceId2 =  [[NSUserDefaults standardUserDefaults] stringForKey:oldShortDeviceIdKey2];
    XCTAssertNil(oldShortDeviceId2);
}

- (void)testGetSetCurrentCacheVersion {

    SwrveConfig *swrveConfig = [[SwrveConfig alloc] init];
    ImmutableSwrveConfig *immutableSwrveConfig = [[ImmutableSwrveConfig alloc] initWithMutableConfig:swrveConfig];
    SwrveMigrationsManager *migrationsManager = [[SwrveMigrationsManager alloc] initWithConfig:immutableSwrveConfig];

    XCTAssertEqual([migrationsManager currentCacheVersion], 0, @"From a cold install the current cache version number should not exist.");

    [SwrveMigrationsManager setCurrentCacheVersion:5];
    XCTAssertEqual([migrationsManager currentCacheVersion], 5, @"The current cache version was updated to 5.");

    [SwrveMigrationsManager setCurrentCacheVersion:10];
    XCTAssertEqual([migrationsManager currentCacheVersion], 10, @"The current cache version was updated to 10.");
}

// The below test requires Data Encryption capability to be enabled, and a passcode set.
// Therefore this test is manually executed on a REAL device with a passcode. Simulators do not support passcode so it will fail in CI.
// prefix the test with "skipped" so CI does not execute it in simulator
- (void)skipped_testFileProtectionOnCurrentCacheVersion_withCompleteParentProtection {

    NSFileManager *fileManager = [NSFileManager defaultManager];

    // remove the app support dir and then recreate it with NSFileProtectionComplete
    NSString *appSupportDir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    [fileManager removeItemAtPath:appSupportDir error:nil];
    [fileManager createDirectoryAtPath:appSupportDir
           withIntermediateDirectories:YES
                            attributes:@{NSFileProtectionKey: NSFileProtectionComplete}
                                 error:nil];

    // create "swrve" parent folder using nil attributes. Version 6.5.2 and lower had this
    NSString *swrveAppSupportDir = [appSupportDir stringByAppendingPathComponent:@"swrve"];
    BOOL successCreateDir = [[NSFileManager defaultManager] createDirectoryAtPath:swrveAppSupportDir
                                                      withIntermediateDirectories:YES
                                                                       attributes:nil // nil file protection
                                                                            error:nil];
    XCTAssertTrue(successCreateDir);

    // create existing cache version file and verify it is protected
    NSString *cacheVersionFilePath = [swrveAppSupportDir stringByAppendingPathComponent:@"swrve_cache_version.txt"];
    BOOL successWriteCacheVersion = [@"2" writeToFile:cacheVersionFilePath
                                           atomically:YES
                                             encoding:NSUTF8StringEncoding
                                                error:nil];
    XCTAssertTrue(successWriteCacheVersion);
    BOOL successSetAttributes = [fileManager setAttributes:@{NSFileProtectionKey: NSFileProtectionComplete}
                                              ofItemAtPath:cacheVersionFilePath
                                                     error:nil];
    XCTAssertTrue(successSetAttributes);
    XCTAssertTrue([self isProtectedItemAtFilePath:cacheVersionFilePath]);

    // call setCurrentCacheVersion verify it is now not protected
    [SwrveMigrationsManager setCurrentCacheVersion:10];
    XCTAssertFalse([self isProtectedItemAtFilePath:cacheVersionFilePath]);
}

- (void)testInstallDateMigration {

    [SwrveLocalStorage saveSwrveUserId:@"fake_user"]; // Fake user, migrations only run for existing installations
    
    // Create install date file in old format
    [self createInstallDateV0FormatWithDate:@"00000000"];

    SwrveConfig *swrveConfig = [[SwrveConfig alloc] init];
    ImmutableSwrveConfig *immutableSwrveConfig = [[ImmutableSwrveConfig alloc] initWithMutableConfig:swrveConfig];
    SwrveMigrationsManager *migrationsManager = [[SwrveMigrationsManager alloc] initWithConfig:immutableSwrveConfig];
    [migrationsManager checkMigrations];

    NSString *installDateFilePath = [self installDateFilePathForConfig];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:installDateFilePath] == YES);
}

- (void)createInstallDateV0FormatWithDate:(NSString *)installDate {
    // create an install date file in the old v0 format.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentPath = [SwrveLocalStorage documentPath];
    BOOL dirCreated = [[NSFileManager defaultManager] createDirectoryAtPath:documentPath withIntermediateDirectories:YES attributes:nil error:nil];
    XCTAssertTrue(dirCreated == YES);
    NSString *installDateFilePath = [documentPath stringByAppendingPathComponent:@"swrve_install.txt"];
    NSData *data = [installDate dataUsingEncoding:NSUTF8StringEncoding];
    BOOL success = [fileManager createFileAtPath:installDateFilePath contents:data attributes:nil];
    XCTAssertTrue(success == YES);
    XCTAssertTrue([fileManager fileExistsAtPath:installDateFilePath]);
}

- (void)testSeqNumMigration {

    [[NSUserDefaults standardUserDefaults] setValue:@"100" forKey:@"swrve_event_seqnum"];
    [SwrveLocalStorage saveSwrveUserId:@"joe"];
    SwrveConfig *swrveConfig = [[SwrveConfig alloc] init];
    ImmutableSwrveConfig *immutableSwrveConfig = [[ImmutableSwrveConfig alloc] initWithMutableConfig:swrveConfig];
    SwrveMigrationsManager *migrationsManager = [[SwrveMigrationsManager alloc] initWithConfig:immutableSwrveConfig];
    [migrationsManager checkMigrations];

    NSString *seqNumKey = [@"joe" stringByAppendingString:@"swrve_event_seqnum"];
    NSInteger seqNum = [[NSUserDefaults standardUserDefaults] integerForKey:seqNumKey];
    XCTAssertEqual(seqNum, 100);

    NSInteger oldSeqNum = [[NSUserDefaults standardUserDefaults] integerForKey:@"swrve_event_seqnum"];
    XCTAssertEqual(oldSeqNum, 0);
}

- (void)testCampaignsStateMigration {

    [SwrveLocalStorage saveSwrveUserId:@"fake_user"]; // Fake user, migrations only run for existing installations
    // Create an campaign state file in the old v0 format.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *applicationSupportPath = [SwrveLocalStorage applicationSupportPath];
    BOOL dirCreated = [[NSFileManager defaultManager] createDirectoryAtPath:applicationSupportPath withIntermediateDirectories:YES attributes:nil error:nil];
    XCTAssertTrue(dirCreated == YES);
    NSString *settingsFilePath = [applicationSupportPath stringByAppendingPathComponent: @"com.swrve.messages.settings.plist"];
    NSData *data = [@"123456" dataUsingEncoding:NSUTF8StringEncoding];
    BOOL success1 = [fileManager createFileAtPath:settingsFilePath contents:data attributes:nil];
    XCTAssertTrue(success1 == YES);
    XCTAssertTrue([fileManager fileExistsAtPath:settingsFilePath] == YES);

    SwrveConfig *swrveConfig = [[SwrveConfig alloc] init];
    ImmutableSwrveConfig *immutableSwrveConfig = [[ImmutableSwrveConfig alloc] initWithMutableConfig:swrveConfig];
    SwrveMigrationsManager *migrationsManager = [[SwrveMigrationsManager alloc] initWithConfig:immutableSwrveConfig];
    [migrationsManager checkMigrations];
    
    SwrveProfileManager *profileManager = [[SwrveProfileManager alloc] initWithIdentityUrl:nil deviceUUID:nil restClient:nil  appId:1 apiKey:@"api_key"];
    NSString *userId = [profileManager userId];
    NSString *campaignsStateFilePath = [SwrveLocalStorage campaignsStateFilePathForUserId:userId];
    XCTAssertTrue([fileManager fileExistsAtPath:campaignsStateFilePath] == YES);
    NSString *campaignsState = [[NSString alloc] initWithContentsOfFile:campaignsStateFilePath encoding:NSUTF8StringEncoding error:nil];
    XCTAssertTrue([campaignsState isEqualToString:@"123456"], @"The contents of the campaign state plist are not the same after migration.");
}

- (void)testMigrateCampaignState {
    [self checkMigratedApplicationSupportFile:@"com.swrve.messages.settings.plist"];
}

- (void)testMigrateCampaigns {
    [self checkMigratedApplicationSupportFile:@"cmcc2.json"];
}

- (void)testMigrateCampaignsSgt {
    [self checkMigratedApplicationSupportFile:@"cmccsgt2.txt"];
}

- (void)testMigrateLocations {
    [self checkMigratedApplicationSupportFile:@"lc.txt"];
}

- (void)testMigrateLocationsSgt {
    [self checkMigratedApplicationSupportFile:@"lcsgt.txt"];
}

- (void)testMigrateResources {
    [self checkMigratedApplicationSupportFile:@"srcngt2.txt"];
}

- (void)testMigrateResourcesSgt {
    [self checkMigratedApplicationSupportFile:@"srcngtsgt2.txt"];
}

- (void)testMigrateResourcesDiff {
    [self checkMigratedApplicationSupportFile:@"rsdfngt2.txt"];
}

- (void)testMigrateResourcesDiffSgt {
    [self checkMigratedApplicationSupportFile:@"rsdfngtsgt2.txt"];
}

- (void)testMigrateEvents {
    [self checkMigratedApplicationSupportFile:@"swrve_events.txt"];
}

- (void)checkMigratedApplicationSupportFile:(NSString *)fileName {

    [SwrveLocalStorage saveSwrveUserId:@"fake_user"]; // Fake user, migrations only run for existing installations
    
    // Create the file
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *applicationSupportPath = [SwrveLocalStorage applicationSupportPath];
    BOOL dirCreated = [[NSFileManager defaultManager] createDirectoryAtPath:applicationSupportPath withIntermediateDirectories:YES attributes:nil error:nil];
    XCTAssertTrue(dirCreated == YES);
    NSString *filePath = [applicationSupportPath stringByAppendingPathComponent:fileName];
    NSData *data = [@"123456" dataUsingEncoding:NSUTF8StringEncoding];
    BOOL success1 = [fileManager createFileAtPath:filePath contents:data attributes:nil];
    XCTAssertTrue(success1 == YES);
    XCTAssertTrue([fileManager fileExistsAtPath:filePath] == YES);

    SwrveConfig *swrveConfig = [[SwrveConfig alloc] init];
    ImmutableSwrveConfig *immutableSwrveConfig = [[ImmutableSwrveConfig alloc] initWithMutableConfig:swrveConfig];
    SwrveMigrationsManager *migrationsManager = [[SwrveMigrationsManager alloc] initWithConfig:immutableSwrveConfig];
    [migrationsManager checkMigrations];
    
    SwrveProfileManager *profileManager = [[SwrveProfileManager alloc] initWithIdentityUrl:nil deviceUUID:nil restClient:nil  appId:1 apiKey:@"api_key"];
    NSString *userId = [profileManager userId];
    NSString *swrveAppSupportDir = [SwrveLocalStorage swrveAppSupportDir];
    NSString *migratedFileName = [userId stringByAppendingString:fileName];
    NSString *migratedFilePath = [swrveAppSupportDir stringByAppendingPathComponent:migratedFileName];
    XCTAssertTrue([fileManager fileExistsAtPath:migratedFilePath] == YES);
    NSString *contents = [[NSString alloc] initWithContentsOfFile:migratedFilePath encoding:NSUTF8StringEncoding error:nil];
    XCTAssertTrue([contents isEqualToString:@"123456"], @"The contents of the migrated file are not the same after migration.");
}

-(void)testMigrate2Etag {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"TestEtag" forKey:@"campaigns_and_resources_etag"];
    [SwrveLocalStorage saveSwrveUserId:@"UserId"];

    XCTAssertTrue([@"TestEtag" isEqualToString:[SwrveLocalStorage eTagForUserId:@""]]);
    XCTAssertNil([SwrveLocalStorage eTagForUserId:@"UserId"]);

    SwrveMigrationsManager *swrveMigrationsManager = [[SwrveMigrationsManager alloc] init];
    [SwrveMigrationsManager setCurrentCacheVersion:0];
    [swrveMigrationsManager checkMigrations];

    XCTAssertNil([defaults objectForKey:@"campaigns_and_resources_etag"]);
    XCTAssertTrue([@"TestEtag" isEqualToString:[SwrveLocalStorage eTagForUserId:@"UserId"]]);
}

-(void)testMigrate2InstallDate_From_v0 {
    [SwrveLocalStorage saveSwrveUserId:@"UserId"]; // Fake user, migrations only run for existing installations
    
    // Create install date file in old format
    [self createInstallDateV0FormatWithDate:@"00000"];

    SwrveConfig *swrveConfig = [[SwrveConfig alloc] init];
    ImmutableSwrveConfig *immutableSwrveConfig = [[ImmutableSwrveConfig alloc] initWithMutableConfig:swrveConfig];
    SwrveMigrationsManager *migrationsManager = [[SwrveMigrationsManager alloc] initWithConfig:immutableSwrveConfig];
    [SwrveMigrationsManager setCurrentCacheVersion:0]; // migrate from 0
    [migrationsManager checkMigrations];
    
    NSString *documentPath = [SwrveLocalStorage documentPath];
    NSString *appInstallDateFilePath = [documentPath stringByAppendingPathComponent:@"swrve_install.txt"];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:appInstallDateFilePath] == YES);
    
    NSString *appInstallDateContents = [[NSString alloc] initWithContentsOfFile:appInstallDateFilePath encoding:NSUTF8StringEncoding error:nil];
    XCTAssertTrue([appInstallDateContents isEqualToString:@"00000"], @"The contents of the app install date is not correct after copying current user joined time.");
}

-(void)testMigrate2InstallDate_From_v1 {
    [SwrveLocalStorage saveSwrveUserId:@"UserId"]; // Fake user, migrations only run for existing installations
    
    // Create install date file in format v1
    [SwrveLocalStorage saveUserJoinedTime:987654321 forUserId:@"UserId"];
    
    SwrveConfig *swrveConfig = [[SwrveConfig alloc] init];
    ImmutableSwrveConfig *immutableSwrveConfig = [[ImmutableSwrveConfig alloc] initWithMutableConfig:swrveConfig];
    SwrveMigrationsManager *migrationsManager = [[SwrveMigrationsManager alloc] initWithConfig:immutableSwrveConfig];
    [SwrveMigrationsManager setCurrentCacheVersion:1]; //migrate from 1
    [migrationsManager checkMigrations];
    
    NSString *documentPath = [SwrveLocalStorage documentPath];
    NSString *appInstallDateFilePath = [documentPath stringByAppendingPathComponent:@"swrve_install.txt"];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:appInstallDateFilePath] == YES);
    
    NSString *appInstallDateContents = [[NSString alloc] initWithContentsOfFile:appInstallDateFilePath encoding:NSUTF8StringEncoding error:nil];
    XCTAssertTrue([appInstallDateContents isEqualToString:@"987654321"], @"The contents of the app install date is not correct after copying current user joined time.");
}

-(void)testMigrate3WithSingleUser {
    
    [SwrveLocalStorage saveSwrveUserId:@"userId1"]; // Fake user, migrations only run for existing installations

    NSFileManager *fileManager = [NSFileManager defaultManager];

    // remove the app support dir and then recreate it with NSFileProtectionComplete
    NSString *appSupportDir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    [fileManager removeItemAtPath:appSupportDir error:nil];
    [fileManager createDirectoryAtPath:appSupportDir
           withIntermediateDirectories:YES
                            attributes:@{NSFileProtectionKey: NSFileProtectionComplete}
                                 error:nil];

    // create "swrve" parent folder using nil attributes. Version 6.5.2 and lower had this
    NSString *swrveAppSupportDir = [appSupportDir stringByAppendingPathComponent:@"swrve"];
    [fileManager createDirectoryAtPath:swrveAppSupportDir
                                                      withIntermediateDirectories:YES
                                                                       attributes:nil // nil file protection
                                                                            error:nil];

    SwrveConfig *swrveConfig = [[SwrveConfig alloc] init];
    ImmutableSwrveConfig *immutableSwrveConfig = [[ImmutableSwrveConfig alloc] initWithMutableConfig:swrveConfig];
    SwrveMigrationsManager *migrationsManager = [[SwrveMigrationsManager alloc] initWithConfig:immutableSwrveConfig];
    [SwrveMigrationsManager setCurrentCacheVersion:2]; // migrate from 2

    // install dates
    [SwrveLocalStorage saveUserJoinedTime:987654321 forUserId:@""]; // blank userId for app install date

    // set up files
    [self migrate3SetupTestForUserId:@"userId1"];

    // do the migrations
    [migrationsManager checkMigrations];

    // verify files are not protected
    XCTAssertFalse([self isProtectedItemAtFilePath:migrationsManager.cacheVersionFilePath]);
    XCTAssertFalse([self isProtectedItemAtFilePath:[SwrveLocalStorage swrveAppSupportDir]]);
    XCTAssertFalse([self isProtectedItemAtFilePath:[SwrveLocalStorage userInitDateFilePath:@""]]); // pass empty string as app Install time is saved with no id

    [self migrate3VerifyTestForUserId:@"userId1"];
}

-(void)testMigrate3WithMultipleUsers {
    
    [SwrveLocalStorage saveSwrveUserId:@"userId1"]; // Fake user, migrations only run for existing installations

    NSFileManager *fileManager = [NSFileManager defaultManager];

    // remove the app support dir and then recreate it with NSFileProtectionComplete
    NSString *appSupportDir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    [fileManager removeItemAtPath:appSupportDir error:nil];
    [fileManager createDirectoryAtPath:appSupportDir
           withIntermediateDirectories:YES
                            attributes:@{NSFileProtectionKey: NSFileProtectionComplete}
                                 error:nil];

    // create "swrve" parent folder using nil attributes. Version 6.5.2 and lower had this
    NSString *swrveAppSupportDir = [appSupportDir stringByAppendingPathComponent:@"swrve"];
    [fileManager createDirectoryAtPath:swrveAppSupportDir
                                                      withIntermediateDirectories:YES
                                                                       attributes:nil // nil file protection
                                                                            error:nil];

    SwrveConfig *swrveConfig = [[SwrveConfig alloc] init];
    ImmutableSwrveConfig *immutableSwrveConfig = [[ImmutableSwrveConfig alloc] initWithMutableConfig:swrveConfig];
    SwrveMigrationsManager *migrationsManager = [[SwrveMigrationsManager alloc] initWithConfig:immutableSwrveConfig];
    [SwrveMigrationsManager setCurrentCacheVersion:2]; // migrate from 2

    // install dates
    [SwrveLocalStorage saveUserJoinedTime:987654321 forUserId:@""]; // blank userId for app install date

    SwrveUser *user1 = [[SwrveUser alloc]initWithExternalId:@"externalUserId1" swrveId:@"userId1" verified:YES];
    SwrveUser *user2 = [[SwrveUser alloc]initWithExternalId:@"externalUserId2" swrveId:@"userId2" verified:YES];
    SwrveUser *user3 = [[SwrveUser alloc]initWithExternalId:@"externalUserId3" swrveId:@"userId3" verified:YES];
    NSArray *userArray = @[user1, user2, user3];
    NSData *swrveUsersData = [NSKeyedArchiver archivedDataWithRootObject:userArray];
    [SwrveLocalStorage saveSwrveUsers:swrveUsersData];

    // set up files for 3 users
    [self migrate3SetupTestForUserId:@"userId1"];
    [self migrate3SetupTestForUserId:@"userId2"];
    [self migrate3SetupTestForUserId:@"userId3"];

    // do the migrations
    [migrationsManager checkMigrations];

    // verify files are not protected
    XCTAssertFalse([self isProtectedItemAtFilePath:migrationsManager.cacheVersionFilePath]);
    XCTAssertFalse([self isProtectedItemAtFilePath:[SwrveLocalStorage swrveAppSupportDir]]);
    XCTAssertFalse([self isProtectedItemAtFilePath:[SwrveLocalStorage userInitDateFilePath:@""]]); // pass empty string as app Install time is saved with no id

    [self migrate3VerifyTestForUserId:@"userId1"];
    [self migrate3VerifyTestForUserId:@"userId2"];
    [self migrate3VerifyTestForUserId:@"userId3"];
}

/* HELPER METHODS */

- (NSString*)installDateFilePathForConfig {
    SwrveProfileManager *profileManager = [[SwrveProfileManager alloc] initWithIdentityUrl:nil deviceUUID:nil restClient:nil appId:1 apiKey:@"SomeKey"];
    NSString *documentPath = [SwrveLocalStorage documentPath];
    NSString *installDateWithUserId = [[profileManager userId] stringByAppendingString:@"swrve_install.txt"];
    NSString *installDateFilePath = [documentPath stringByAppendingPathComponent:installDateWithUserId];
    return installDateFilePath;
}

- (void)migrate3SetupTestForUserId:(NSString *)userId {

    UInt64 secondsSinceEpoch = (unsigned long long) ([[NSDate date] timeIntervalSince1970]);
    NSString *signatureKey = [NSString stringWithFormat:@"%@%llu", @"someAPIKey", secondsSinceEpoch];
    
    // install dates
    [SwrveLocalStorage saveUserJoinedTime:987654321 forUserId:userId];

    // resources
    NSArray *resources = [NSArray arrayWithObjects:@{@"uid": @"resources.example"}, nil];
    NSData *resourceData = [NSJSONSerialization dataWithJSONObject:resources options:0 error:nil];
    SwrveSignatureProtectedFile *resourcesFile = [[SwrveSignatureProtectedFile alloc] protectedFileType:SWRVE_RESOURCE_FILE
                                                                                                 userID:userId
                                                                                           signatureKey:signatureKey
                                                                                          errorDelegate:nil];

    [resourcesFile writeWithRespectToPlatform:resourceData];
    // resources diff
    NSArray *resourcesDiff = [NSArray arrayWithObjects:@{@"uid": @"resourcesdiff.example"}, nil];
    NSData *resourceDiffData = [NSJSONSerialization dataWithJSONObject:resourcesDiff options:0 error:nil];
    SwrveSignatureProtectedFile *resourcesDiffFile = [[SwrveSignatureProtectedFile alloc] protectedFileType:SWRVE_RESOURCE_DIFF_FILE
                                                                                                     userID:userId
                                                                                               signatureKey:signatureKey
                                                                                              errorDelegate:nil];
    [resourcesDiffFile writeWithRespectToPlatform:resourceDiffData];
    // campaigns
    NSDictionary *campaigns = @{ @"campaigns": @{}, @"fake1": @"value1"};
    NSData *campaignsData = [NSJSONSerialization dataWithJSONObject:campaigns options:0 error:nil];
    SwrveSignatureProtectedFile *campaignsFile = [[SwrveSignatureProtectedFile alloc] protectedFileType:SWRVE_CAMPAIGN_FILE
                                                                                                 userID:userId
                                                                                           signatureKey:signatureKey
                                                                                          errorDelegate:nil];
    [campaignsFile writeWithRespectToPlatform:campaignsData];
    // offline notification campaigns
    NSDictionary *campaignsOffline = @{@"campaigns": @{}, @"fake2": @"value2"};
    NSData *campaignsOfflineData = [NSJSONSerialization dataWithJSONObject:campaignsOffline options:0 error:nil];
    SwrveSignatureProtectedFile *campaignsOfflineFile = [[SwrveSignatureProtectedFile alloc] protectedFileType:SWRVE_NOTIFICATION_CAMPAIGNS_FILE
                                                                                                        userID:userId
                                                                                                  signatureKey:signatureKey
                                                                                                 errorDelegate:nil];
    [campaignsOfflineFile writeWithRespectToPlatform:campaignsOfflineData];
    // realtime user properties
    NSDictionary *realTimeUserProperties = @{ @"fake3": @"value3"};
    NSData *realTimeUserPropertiesData = [NSJSONSerialization dataWithJSONObject:realTimeUserProperties options:0 error:nil];
    SwrveSignatureProtectedFile *realTimeUserPropertiesFile = [[SwrveSignatureProtectedFile alloc] protectedFileType:SWRVE_REAL_TIME_USER_PROPERTIES_FILE
                                                                                                              userID:userId
                                                                                                        signatureKey:signatureKey
                                                                                                       errorDelegate:nil];
    [realTimeUserPropertiesFile writeWithRespectToPlatform:realTimeUserPropertiesData];
    // event file
    // TODO
}

- (void)migrate3VerifyTestForUserId:(NSString *)userId {
    XCTAssertFalse([self isProtectedItemAtFilePath:[SwrveLocalStorage userInitDateFilePath:userId]]);
    XCTAssertFalse([self isProtectedItemAtFilePath:[SwrveLocalStorage userResourcesFilePathForUserId:userId]]);
    XCTAssertFalse([self isProtectedItemAtFilePath:[SwrveLocalStorage userResourcesSignatureFilePathForUserId:userId]]);
    XCTAssertFalse([self isProtectedItemAtFilePath:[SwrveLocalStorage userResourcesDiffFilePathForUserId:userId]]);
    XCTAssertFalse([self isProtectedItemAtFilePath:[SwrveLocalStorage userResourcesDiffSignatureFilePathForUserId:userId]]);
    XCTAssertFalse([self isProtectedItemAtFilePath:[SwrveLocalStorage campaignsFilePathForUserId:userId]]);
    XCTAssertFalse([self isProtectedItemAtFilePath:[SwrveLocalStorage campaignsSignatureFilePathForUserId:userId]]);
    XCTAssertFalse([self isProtectedItemAtFilePath:[SwrveLocalStorage offlineCampaignsFilePathForUserId:userId]]);
    XCTAssertFalse([self isProtectedItemAtFilePath:[SwrveLocalStorage offlineCampaignsSignatureFilePathForUserId:userId]]);
    XCTAssertFalse([self isProtectedItemAtFilePath:[SwrveLocalStorage realTimeUserPropertiesFilePathForUserId:userId]]);
    XCTAssertFalse([self isProtectedItemAtFilePath:[SwrveLocalStorage offlineRealTimeUserPropertiesSignatureFilePathForUserId:userId]]);
}

- (BOOL)isProtectedItemAtFilePath:(NSString *)filePath {
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSError *error = nil;
    NSDictionary *attributes = [fileManager attributesOfItemAtPath:filePath error:&error];
    if (attributes != nil) {
        NSString *protectionAttributeValue = [attributes valueForKey:NSFileProtectionKey];
        if ((protectionAttributeValue == nil) || [protectionAttributeValue isEqualToString:NSFileProtectionNone]) {
            return NO;
        }
    }
    return YES;
}

- (void)testMigrateOneFilesContentsToAnother {
    
    NSError *error;
    NSString *oldFilePath = [self createTestFile:@"old" withContent:@"hello"];
    NSString *newFilePath = [[SwrveTestHelper rootCacheDirectory] stringByAppendingPathComponent:@"new.txt"];

    SwrveMigrationsManager *swrveMigrationsManager = [[SwrveMigrationsManager alloc] init];
    [swrveMigrationsManager migrateOldCacheFile:oldFilePath withNewPath:newFilePath];
    NSString *migratedString = [NSString stringWithContentsOfFile:newFilePath encoding:NSUTF8StringEncoding error:&error];
    XCTAssertEqualObjects(migratedString, @"hello");
}

/**
 *  Test to verify Migrating Converting our own files to NSFileProtectionNone
 *  NB, this needs in order to correctly operate:
 *   - the Project Capability 'File Protection' ON
 *   - running on a real device
 **/
- (void)testMigrateFileProtection {
#if !(TARGET_IPHONE_SIMULATOR)  // File Protection does not appear for simulators, can only test against device
    
    NSError *error;
    NSString *filePath = [self createProtectedTestFile:@"test" withContent:@"super secret"];
    
    // No longer visible when building for device
    // [SwrveMigrationsManager migrateFileProtectionAtPath:filePath];
    
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
    XCTAssertNil(error);
    XCTAssertEqualObjects([attributes objectForKey:NSFileProtectionKey], NSFileProtectionNone);
    
#endif //#if !(TARGET_IPHONE_SIMULATOR)
}

#pragma mark - private methods

- (NSString *)createTestFile:(NSString *) fileName withContent:(NSString *)content {
    
    NSError *error;
    NSString *name = [NSString stringWithFormat:@"%@.txt", fileName];
    NSString *filePath = [[SwrveTestHelper rootCacheDirectory] stringByAppendingPathComponent:name];
    [content writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    XCTAssertNil(error);
    
    return filePath;
}

- (NSString *)createProtectedTestFile:(NSString *) fileName withContent:(NSString *)content {
    
    NSError *error;
    NSString *name = [NSString stringWithFormat:@"%@.txt", fileName];
    NSString *filePath = [[SwrveTestHelper rootCacheDirectory] stringByAppendingPathComponent:name];
    [[content dataUsingEncoding:NSUTF8StringEncoding] writeToURL:[NSURL fileURLWithPath:filePath] options:NSDataWritingFileProtectionComplete error:&error];
    XCTAssertNil(error);
    
    return filePath;
}

@end
