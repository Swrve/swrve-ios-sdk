#import <XCTest/XCTest.h>
#import "SwrveMigrationsManager.h"
#import "SwrveTestHelper.h"
#import "SwrveProfileManager.h"
#import "SwrveRESTClient.h"

@interface SwrveProfileManager ()
- (instancetype)initWithIdentityUrl:(NSString *)identityBaseUrl deviceUUID:(NSString *)deviceUUID restClient:(SwrveRESTClient *)restClient appId:(long)appId apiKey:(NSString*)apiKey;
@end

@interface SwrveMigrationsManager (SwrveInternalAccess)

- (int)currentCacheVersion;
+ (void)setCurrentCacheVersion:(int)cacheVersion;

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

/* HELPER METHODS */

- (NSString*)installDateFilePathForConfig {
    SwrveProfileManager *profileManager = [[SwrveProfileManager alloc] initWithIdentityUrl:nil deviceUUID:nil restClient:nil appId:1 apiKey:@"SomeKey"];
    NSString *documentPath = [SwrveLocalStorage documentPath];
    NSString *installDateWithUserId = [[profileManager userId] stringByAppendingString:@"swrve_install.txt"];
    NSString *installDateFilePath = [documentPath stringByAppendingPathComponent:installDateWithUserId];
    return installDateFilePath;
}

@end
