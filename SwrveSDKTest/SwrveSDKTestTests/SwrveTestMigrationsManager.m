#import <XCTest/XCTest.h>
#import "SwrveMigrationsManager.h"
#import "SwrveLocalStorage.h"
#import "SwrveTestHelper.h"

@interface SwrveMigrationsManager (SwrveInternalAccess)

- (int)getCurrentCacheVersion;
- (void)setCurrentCacheVersion:(int)cacheVersion;

@end


@interface SwrveTestMigrationsManager : XCTestCase

@end

@implementation SwrveTestMigrationsManager

- (void)setUp {
    [super setUp];
    [SwrveTestHelper tearDown];
}

- (void)tearDown {
    [super tearDown];
    [SwrveTestHelper tearDown];
}

- (void)testGetSetCurrentCacheVersion {

    SwrveConfig *swrveConfig = [[SwrveConfig alloc] init];
    ImmutableSwrveConfig *immutableSwrveConfig = [[ImmutableSwrveConfig alloc] initWithMutableConfig:swrveConfig];
    SwrveMigrationsManager *migrationsManager = [[SwrveMigrationsManager alloc] initWithConfig:immutableSwrveConfig];

    XCTAssertEqual([migrationsManager getCurrentCacheVersion], 0, @"From a cold install the current cache version number should not exist.");

    [migrationsManager setCurrentCacheVersion:5];
    XCTAssertEqual([migrationsManager getCurrentCacheVersion], 5, @"The current cache version was updated to 5.");

    [migrationsManager setCurrentCacheVersion:10];
    XCTAssertEqual([migrationsManager getCurrentCacheVersion], 10, @"The current cache version was updated to 10.");
}

- (void)testInstallDateMigrationInAutoTracking {

    // create install date file in old format
    [self createInstallDateV0Format];

    SwrveConfig *swrveConfig = [[SwrveConfig alloc] init];
    ImmutableSwrveConfig *immutableSwrveConfig = [[ImmutableSwrveConfig alloc] initWithMutableConfig:swrveConfig];
    SwrveMigrationsManager *migrationsManager = [[SwrveMigrationsManager alloc] initWithConfig:immutableSwrveConfig];
    [migrationsManager checkMigrations];

    NSString *installDateFilePath = [self installDateFilePathForConfig:immutableSwrveConfig];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:installDateFilePath] == YES);
}

- (void)createInstallDateV0Format {
    // create an install date file in the old v0 format.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentPath = [SwrveLocalStorage documentPath];
    BOOL dirCreated = [[NSFileManager defaultManager] createDirectoryAtPath:documentPath withIntermediateDirectories:YES attributes:nil error:nil];
    XCTAssertTrue(dirCreated == YES);
    NSString *installDateFilePath = [documentPath stringByAppendingPathComponent: @"swrve_install.txt"];
    NSData *data = [@"1111111" dataUsingEncoding:NSUTF8StringEncoding];
    BOOL success = [fileManager createFileAtPath:installDateFilePath contents:data attributes:nil];
    XCTAssertTrue(success == YES);
    XCTAssertTrue([fileManager fileExistsAtPath:installDateFilePath]);
}

- (NSString*)installDateFilePathForConfig:(ImmutableSwrveConfig *)immutableSwrveConfig {
    SwrveProfileManager *profileManager = [[SwrveProfileManager alloc] initWithConfig:immutableSwrveConfig];
    NSString *documentPath = [SwrveLocalStorage documentPath];
    NSString *installDateWithUserId = [[profileManager userId] stringByAppendingString:@"swrve_install.txt"];
    NSString *installDateFilePath = [documentPath stringByAppendingPathComponent:installDateWithUserId];
    return installDateFilePath;
}

- (void)testSeqNumMigration {

    [[NSUserDefaults standardUserDefaults] setValue:@"100" forKey:@"swrve_event_seqnum"];
    SwrveConfig *swrveConfig = [[SwrveConfig alloc] init];
    swrveConfig.userId = @"joe";
    ImmutableSwrveConfig *immutableSwrveConfig = [[ImmutableSwrveConfig alloc] initWithMutableConfig:swrveConfig];
    SwrveMigrationsManager *migrationsManager = [[SwrveMigrationsManager alloc] initWithConfig:immutableSwrveConfig];
    [migrationsManager checkMigrations];

    NSString *seqNumKey = [@"joe" stringByAppendingString:@"swrve_event_seqnum"];
    NSInteger seqNum = [[NSUserDefaults standardUserDefaults] integerForKey:seqNumKey];
    XCTAssertEqual(seqNum, 100);

    NSInteger oldSeqNum = [[NSUserDefaults standardUserDefaults] integerForKey:@"swrve_event_seqnum"];
    XCTAssertEqual(oldSeqNum, 0);
}

- (void)testCampaignsStateMigrationInAutoTracking {

    // create an campaign state file in the old v0 format.
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

    SwrveProfileManager *profileManager = [[SwrveProfileManager alloc] initWithConfig:immutableSwrveConfig];
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

    // create the file
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *applicationSupportPath = [SwrveLocalStorage applicationSupportPath];
    BOOL dirCreated = [[NSFileManager defaultManager] createDirectoryAtPath:applicationSupportPath withIntermediateDirectories:YES attributes:nil error:nil];
    XCTAssertTrue(dirCreated == YES);
    NSString *filePath = [applicationSupportPath stringByAppendingPathComponent: fileName];
    NSData *data = [@"123456" dataUsingEncoding:NSUTF8StringEncoding];
    BOOL success1 = [fileManager createFileAtPath:filePath contents:data attributes:nil];
    XCTAssertTrue(success1 == YES);
    XCTAssertTrue([fileManager fileExistsAtPath:filePath] == YES);

    SwrveConfig *swrveConfig = [[SwrveConfig alloc] init];
    ImmutableSwrveConfig *immutableSwrveConfig = [[ImmutableSwrveConfig alloc] initWithMutableConfig:swrveConfig];
    SwrveMigrationsManager *migrationsManager = [[SwrveMigrationsManager alloc] initWithConfig:immutableSwrveConfig];
    [migrationsManager checkMigrations];

    SwrveProfileManager *profileManager = [[SwrveProfileManager alloc] initWithConfig:immutableSwrveConfig];
    NSString *userId = [profileManager userId];
    NSString *swrveAppSupportDir = [SwrveLocalStorage swrveAppSupportDir];
    NSString *migratedFileName = [userId stringByAppendingString:fileName];
    NSString *migratedFilePath = [swrveAppSupportDir stringByAppendingPathComponent:migratedFileName];

    XCTAssertTrue([fileManager fileExistsAtPath:migratedFilePath] == YES);
    NSString *contents = [[NSString alloc] initWithContentsOfFile:migratedFilePath encoding:NSUTF8StringEncoding error:nil];
    XCTAssertTrue([contents isEqualToString:@"123456"], @"The contents of the migrated file are not the same after migration.");
}

@end
