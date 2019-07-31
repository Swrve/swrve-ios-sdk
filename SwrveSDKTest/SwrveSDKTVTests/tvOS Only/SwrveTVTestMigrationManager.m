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

@interface SwrveTVTestMigrationManager : XCTestCase

@end

@implementation SwrveTVTestMigrationManager

- (void)setUp {
    [super setUp];
    [SwrveTestHelper setUp];
    [SwrveLocalStorage resetDirectoryCreation];
}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [super tearDown];
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
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    UInt64 expectedInstallSeconds = [defaults integerForKey:@"swrve_install.txt"];

    XCTAssertEqual(expectedInstallSeconds, 987654321);
}

@end
