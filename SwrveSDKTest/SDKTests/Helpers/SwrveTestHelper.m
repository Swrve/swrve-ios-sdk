#import "SwrveTestHelper.h"
#import "SwrveRESTClient.h"
#import "SwrveMigrationsManager.h"
#import "SwrveSDK.h"
#import "OCMock.h"

#if TARGET_OS_IOS /** exclude tvOS **/
#import "SwrvePush.h"
@interface SwrvePush (InternalAccess)
+ (void)resetSharedInstance;
@end
#endif

@interface SwrveMigrationsManager (SwrveInternalAccess)
+ (void)markAsMigrated;
@end

@interface Swrve (Internal)
@property(atomic) SwrveRESTClient *restClient;
- (void)initSwrveRestClient:(NSTimeInterval)timeOut;
- (void)appDidBecomeActive:(NSNotification *)notification;
- (NSDate *)getNow;
@end

@interface SwrveSDK (InternalAccess)
+ (void)resetSwrveSharedInstance;
+ (void)addSharedInstance:(Swrve*)instance;
@end

@implementation SwrveTestHelper

+ (void)setUp {
    [SwrveTestHelper tearDown];
}

+ (void)tearDown {
    [SwrveTestHelper deleteUserDefaults];
    [SwrveTestHelper deleteFilesInDirectory:[SwrveTestHelper rootCacheDirectory]];
    [SwrveTestHelper deleteFilesInDirectory:[SwrveTestHelper rootApplicationSupportDirectory]];
    [SwrveTestHelper deleteFilesInDirectory:[SwrveLocalStorage documentPath]];
    [SwrveTestHelper deleteFilesInDirectory:[SwrveLocalStorage swrveCacheVersionFilePath]];
    [SwrveTestHelper destroySharedInstance];
}

+ (void)destroySharedInstance {
    [SwrveSDK resetSwrveSharedInstance];

#if TARGET_OS_IOS /** exclude tvOS **/
    [SwrvePush resetSharedInstance];
#endif
}

+ (NSString *)rootCacheDirectory {
    static NSString *_dir = nil;
    if (!_dir) {
        _dir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    }
    return _dir;
}

+ (NSString *)rootApplicationSupportDirectory {
    static NSString *_dir = nil;
    if (!_dir) {
        _dir = [SwrveLocalStorage applicationSupportPath];
    }
    return _dir;
}

+ (void)deleteFilesInDirectory:(NSString *)directory {
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSArray *fileArray = [fileMgr contentsOfDirectoryAtPath:directory error:nil];
    for (NSString *filename in fileArray) {
        [fileMgr removeItemAtPath:[directory stringByAppendingPathComponent:filename] error:NULL];
    }
}

+ (void)deleteUserDefaults {
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSMutableArray *)stringArrayFromCachedContent:(NSString *)content {
    NSMutableArray *cacheLines = [[NSMutableArray alloc] initWithArray:[content componentsSeparatedByString:@"\n"]];
    [cacheLines removeLastObject];

    return cacheLines;
}

+ (NSMutableArray *)dicArrayFromCachedFile:(NSURL *)file {

    NSString *content = [SwrveTestHelper fileContentsFromURL:file];
    NSMutableArray *cacheLines = [[NSMutableArray alloc] initWithArray:[content componentsSeparatedByString:@"\n"]];
    [cacheLines removeLastObject];

    NSMutableArray *formattedArray = [NSMutableArray new];
    for (NSString *s in cacheLines) {

        NSString *newString = [s substringToIndex:s.length-1];
        NSDictionary * dic = [NSJSONSerialization JSONObjectWithData:[newString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];

        [formattedArray addObject:dic];
    }
    return formattedArray;
}

+ (NSString *) fileContentsFromURL:(NSURL *)url {
    return [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
}

+ (id) swrveMockWithMockedRestClient {

    // mock all rest calls with success and empty data
    SwrveRESTClient *restClient = [[SwrveRESTClient alloc] initWithTimeoutInterval:60];
    id mockRestClient = OCMPartialMock(restClient);
    id mockResponse = OCMClassMock([NSHTTPURLResponse class]);
    OCMStub([mockResponse statusCode]).andReturn(500);
    NSData *mockData = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];
    OCMStub([mockRestClient sendHttpRequest:OCMOCK_ANY
                          completionHandler:([OCMArg invokeBlockWithArgs:mockResponse, mockData, [NSNull null], nil])]);

    Swrve *swrveMock = (Swrve *) OCMPartialMock([Swrve alloc]);
    OCMStub([swrveMock initSwrveRestClient:60]).andDo(^(NSInvocation *invocation) {
        swrveMock.restClient = mockRestClient;
    });

    return swrveMock;
}

+ (Swrve *)initializeSwrveWithCampaignsFile:(NSString *)filename andConfig:(SwrveConfig *)config {
    NSArray *assets = [self testJSONAssets];
    [self createDummyAssets:assets];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:1362873600];
    NSString *apiKey = @"someAPIKey";
    NSString *userId = @"someUserID";
    UInt64 secondsSinceEpoch = (unsigned long long) ([[NSDate date] timeIntervalSince1970]);
    NSString *signatureKey = [NSString stringWithFormat:@"%@%llu", apiKey, secondsSinceEpoch];

    // Start saving campaign cache (need specific user and install time to be set)
    [SwrveLocalStorage saveSwrveUserId:userId];
    [SwrveLocalStorage saveAppInstallTime:secondsSinceEpoch];
    [SwrveLocalStorage saveUserJoinedTime:secondsSinceEpoch forUserId:userId];
    // Set as migrated to avoid running migrations in this tests
    [SwrveMigrationsManager markAsMigrated];
    SwrveSignatureProtectedFile *campaignFile = [[SwrveSignatureProtectedFile alloc] protectedFileType:SWRVE_CAMPAIGN_FILE
                                                                                                userID:userId
                                                                                          signatureKey:signatureKey
                                                                                         errorDelegate:nil];
    [self overwriteCampaignFile:campaignFile withFile:filename];

    [config setAutoDownloadCampaignsAndResources:NO];

    DebugLog(@"Finished setting up campaign data for unit tests...");
    Swrve *swrveMock = [SwrveTestHelper swrveMockWithMockedRestClient];
    OCMStub([swrveMock getNow]).andReturn(date);
    swrveMock = [swrveMock initWithAppID:123 apiKey:apiKey config:config];
    [swrveMock appDidBecomeActive:nil];
    [SwrveSDK addSharedInstance:swrveMock];

    return swrveMock;
}

+ (void)overwriteCampaignFile:(SwrveSignatureProtectedFile *)signatureFile withFile:(NSString *)filename {
    NSURL *path = [[NSBundle bundleForClass:[Swrve class]] URLForResource:filename withExtension:@"json"];
    NSString *campaignData = [NSString stringWithContentsOfURL:path encoding:NSUTF8StringEncoding error:nil];
    if (campaignData == nil) {
        [NSException raise:@"No content in JSON test file" format:@"File %@ has no content", filename];
    }
    [SwrveTestHelper writeData:campaignData toProtectedFile:signatureFile];
}

+ (NSArray *)testJSONAssets {
    static NSArray *assets = nil;
    if (!assets) {
        assets = @[
                @"281af8272a42b2da21886fd36eef3829e6aadb80"
        ];
    }
    return assets;
}

+ (void)createDummyAssets:(NSArray *)assets {
    [self removeAssets:assets];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager createDirectoryAtPath:[SwrveTestHelper campaignCacheDirectory] withIntermediateDirectories:YES attributes:nil error:nil];

    NSData *dummyData = [@"TestData" dataUsingEncoding:NSASCIIStringEncoding];

    for (NSString *asset in assets) {
        NSString *path = [[SwrveTestHelper campaignCacheDirectory] stringByAppendingPathComponent:asset];
        [fileManager createFileAtPath:path contents:dummyData attributes:nil];
    }
}

+ (void)removeAssets:(NSArray *)assets {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (NSString *asset in assets) {
        NSString *path = [[SwrveTestHelper campaignCacheDirectory] stringByAppendingPathComponent:asset];
        [fileManager removeItemAtPath:path error:nil];
    }
}

+ (void)writeData:(NSString *)content toURL:(NSURL *)url {
    [content writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

+ (void)writeData:(NSString *)content toPath:(NSString *)path {
    [content writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

+ (void)writeData:(NSString *)content toProtectedFile:(SwrveSignatureProtectedFile *)file {
    NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding];
    [file writeWithRespectToPlatform:data];
}

+ (NSString *)campaignCacheDirectory {
    return [[SwrveTestHelper rootCacheDirectory] stringByAppendingPathComponent:@"com.ngt.msgs"];
}

#if TARGET_OS_IOS
+ (void)changeToOrientation:(UIInterfaceOrientation)orientation {
    // Give it time
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]];
    UIApplication *app = [UIApplication sharedApplication];
    if (app == nil || ![app respondsToSelector:@selector(statusBarOrientation)]) {
        NSException *ex = [NSException exceptionWithName:@"ApplicationChangeOrientationError"
                                    reason:@"Appliction could not change orientation, something is up..."
                                    userInfo:nil];
        @throw ex;
    }

    if ([app statusBarOrientation] != orientation) {
        [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:orientation] forKey:@"orientation"];
    }
}
#endif

// Wait for the condition to be true, once that happens the expectation is fulfilled. If it is not true on each delta time, it is checked again.
+ (void)waitForBlock:(float)deltaSecs conditionBlock:(BOOL (^)(void))conditionBlock expectation:(XCTestExpectation *)expectation {
    [self waitForBlock:deltaSecs conditionBlock:conditionBlock expectation:expectation checkNow:TRUE];
}

+ (void)waitForBlock:(float)deltaSecs conditionBlock:(BOOL (^)(void))conditionBlock expectation:(XCTestExpectation *)expectation checkNow:(BOOL)checkNow {
    // Check right away on first invocation
    if (checkNow) {
        if (conditionBlock()) {
            [expectation fulfill];
            return;
        }
    }
    
    // Schedule a check of the condition
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(deltaSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (conditionBlock()) {
            [expectation fulfill];
        } else {
            [self waitForBlock:deltaSecs conditionBlock:conditionBlock expectation:expectation checkNow:NO];
        }
    });
}

@end
