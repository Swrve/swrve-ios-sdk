#import "SwrveTestHelper.h"
#import "SwrvePrivateAccess.h"
#import "SwrvePush.h"
#import "SwrveLocalStorage.h"
#import "SwrveSDK.h"
#import "SwrveMigrationsManager.h"
#import "SwrveMockNSURLProtocol.h"
#import "SwrvePermissions.h"

#if __has_include(<OCMock/OCMock.h>)
#import <OCMock/OCMock.h>
#endif

@interface SwrveMigrationsManager (SwrveInternalAccess)
+ (void)markAsMigrated;
@end

#if TARGET_OS_IOS
@interface SwrvePush (SwrvePushInternalAccess)
+ (void)resetSharedInstance;
@end
#endif //TARGET_OS_IOS

@implementation SwrveTestHelper

+ (void)setAlreadyInstalledUserId:(NSString *)userId {
    // Set user id
    [SwrveLocalStorage saveSwrveUserId:userId];
    // Mark user as fully migrated
    [SwrveMigrationsManager markAsMigrated];
    // Save fake install time
    [SwrveLocalStorage saveUserJoinedTime:1234567889 forUserId:userId];
    [SwrveLocalStorage saveAppInstallTime:1234567889];
}

+ (NSString*)fileContentsFromURL:(NSURL*)url
{
    return [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
}

+ (NSString*)fileContentsFromPath:(NSString*)path
{
    return [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
}

+ (NSString*)fileContentsFromProtectedFile:(SwrveSignatureProtectedFile*)file
{
    NSData *data = [file readWithRespectToPlatform];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+ (void)writeData:(NSString*)content toURL:(NSURL*)url
{
    [content writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

+ (void)writeData:(NSString*)content toPath:(NSString*)path
{
    [content writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

+ (void)writeData:(NSString*)content toProtectedFile:(SwrveSignatureProtectedFile*)file
{
    NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding];
    [file writeWithRespectToPlatform:data];
}

+ (NSString*)rootCacheDirectory
{
    static NSString *_dir = nil;
    if (!_dir) {
        _dir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    }
    return _dir;
}

+ (NSString*)campaignCacheDirectory
{
    return [[SwrveTestHelper rootCacheDirectory] stringByAppendingPathComponent:@"com.ngt.msgs"];
}

+ (void)removeSDKData {
    [SwrveTestHelper deleteUserDefaults];
    [SwrveTestHelper deleteFilesInDirectory:[SwrveTestHelper rootCacheDirectory]];
    [SwrveTestHelper deleteFilesInDirectory:[SwrveLocalStorage applicationSupportPath]];
    [SwrveTestHelper deleteFilesInDirectory:[SwrveLocalStorage documentPath]];
    [SwrveLocalStorage resetDirectoryCreation];
}

+ (void)deleteFilesInDirectory:(NSString*)directory {
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSArray *fileArray = [fileMgr contentsOfDirectoryAtPath:directory error:nil];
    for (NSString *filename in fileArray)  {
        [fileMgr removeItemAtPath:[directory stringByAppendingPathComponent:filename] error:NULL];
    }
}

+ (void)createDirectory:(NSString*)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
}

+ (NSArray*)getFilesInDirectory:(NSString*)directory {
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    return [fileMgr contentsOfDirectoryAtPath:directory error:nil];
}

+ (void)deleteUserDefaults {
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)removeAssets:(NSArray*)assets {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (NSString *asset in assets) {
        NSString *path = [[SwrveTestHelper campaignCacheDirectory] stringByAppendingPathComponent:asset];
        [fileManager removeItemAtPath:path error:nil];
    }
}

+ (void)removeAllAssets {
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSArray *fileArray = [fileMgr contentsOfDirectoryAtPath:[SwrveTestHelper campaignCacheDirectory] error:nil];
    for (NSString *filename in fileArray) {
        [fileMgr removeItemAtPath:[[SwrveTestHelper campaignCacheDirectory] stringByAppendingPathComponent:filename] error:NULL];
    }
}

+ (void)createDummyAssets:(NSArray*)assets {
    [self removeAssets:assets];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager createDirectoryAtPath:[SwrveTestHelper campaignCacheDirectory] withIntermediateDirectories:YES attributes:nil error:nil];

    NSData *dummyData = [@"TestData" dataUsingEncoding:NSASCIIStringEncoding];

    for (NSString *asset in assets) {
        NSString *path = [[SwrveTestHelper campaignCacheDirectory] stringByAppendingPathComponent:asset];
        [fileManager createFileAtPath:path contents:dummyData attributes:nil];
    }
}

// Makes a copy of the logo.gif image for each asset in the array
+ (void)createDummyGifAssets:(NSArray *)assets {
    NSString *dummyGifFilePath = [[NSBundle mainBundle] pathForResource:@"logo" ofType:@"gif"];
    NSURL *fileURL = [NSURL fileURLWithPath:dummyGifFilePath];
    NSData *dummyGifData = [NSData dataWithContentsOfURL:fileURL];
    for (NSString *asset in assets) {
        NSString *assetNameGif = [asset stringByAppendingString:@".gif"];
        NSString *path = [[SwrveTestHelper campaignCacheDirectory] stringByAppendingPathComponent:assetNameGif];
        [dummyGifData writeToFile:path atomically:YES];
    }
}

// Makes a copy of the swrve_logo.png image for each asset in the array
+ (void)createDummyPngAssets:(NSArray*)assets {
    NSString *dummyImageFilePath = [[NSBundle mainBundle] pathForResource:@"swrve_logo" ofType:@"png"];
    NSURL *fileURL = [NSURL fileURLWithPath:dummyImageFilePath];
    NSData *dummyImageData = [NSData dataWithContentsOfURL:fileURL];
    for (NSString *asset in assets) {
        NSString *path = [[SwrveTestHelper campaignCacheDirectory] stringByAppendingPathComponent:asset]; // png assets have no file extension
        [dummyImageData writeToFile:path atomically:YES];
    }
}

+ (NSDictionary*)makeDictionaryFromEventBufferEntry:(NSString*)entry
{
    return [NSJSONSerialization JSONObjectWithData:[entry dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
}


+ (NSArray*)makeArrayFromEventFileContents:(NSMutableData*)storedEvents {

    // remove the ending comma allowing it to be turned into an acceptable UTF8 string
    [storedEvents setLength:[storedEvents length] - 2];
    NSString* file_contents = [[NSString alloc] initWithData:storedEvents encoding:NSUTF8StringEncoding];

    // wrap it around [] brackets so it can be interpreted as an array in UTF8
    NSString *eventArray = [NSString stringWithFormat:@"[%@]", file_contents];
    NSData *bodyData = [eventArray dataUsingEncoding:NSUTF8StringEncoding];
    NSArray* storedEventQueue = [NSJSONSerialization
                     JSONObjectWithData:bodyData
                     options:NSJSONReadingMutableContainers
                     error:nil];

    //will return a list of Dictionaries associated with events
    return storedEventQueue;
}

+ (void)destroySharedInstance {
    [SwrveSDK resetSwrveSharedInstance];
#if TARGET_OS_IOS /** exclude for tvOS **/
    [SwrvePush resetSharedInstance];
#endif //TARGET_OS_IOS
}

+ (NSDictionary*)makeDictionaryFromEventRequest:(NSString*)eventRequest
{
    NSRange range = [eventRequest rangeOfString:@"{"];
    NSString *dictString = [eventRequest substringFromIndex:range.location];
    NSDictionary *dict = [SwrveTestHelper makeDictionaryFromEventBufferEntry:dictString];
    return dict;
}

+ (void)setUp {
    [NSURLProtocol registerClass:[SwrveMockNSURLProtocol class]];
    [SwrveTestHelper removeAllData];
}

#pragma mark - global teardown

+ (void)tearDown {
    [SwrveTestHelper removeAllData];
    [NSURLProtocol unregisterClass:[SwrveMockNSURLProtocol class]];
}

+ (void)removeAllData {
    /** Globally called Clean up method to ensure that each test runs individually without interference from others **/
    [SwrveTestHelper removeSDKData];
    [SwrveTestHelper destroySharedInstance];
}

+ (NSMutableArray*)dicArrayFromCachedFile:(NSURL*)file {

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

+ (id)mockPushRequest {
    id classMock = nil;
#if __has_include(<OCMock/OCMock.h>)
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wgnu"
#if TARGET_OS_IOS
    classMock = OCMClassMock([SwrvePermissions class]);
    OCMStub(ClassMethod([classMock pushAuthorizationWithSDK:OCMOCK_ANY])).andReturn(@"unittest");
#endif
#pragma GCC diagnostic pop
#endif
    return classMock;
}

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

+ (id)swrveMockWithMockedRestClientResponseCode:(int)httpCode mockData:(NSData *)mockData {
    // mock all rest calls with success and empty data
    SwrveRESTClient *restClient = [[SwrveRESTClient alloc] initWithTimeoutInterval:60];
    id mockRestClient = OCMPartialMock(restClient);
    id mockResponse = OCMClassMock([NSHTTPURLResponse class]);
    OCMStub([mockResponse statusCode]).andReturn(httpCode);
    OCMStub([mockRestClient sendHttpRequest:OCMOCK_ANY
                          completionHandler:([OCMArg invokeBlockWithArgs:mockResponse, mockData, [NSNull null], nil])]);

    Swrve *swrveMock = (Swrve *) OCMPartialMock([Swrve alloc]);
    OCMStub([swrveMock initSwrveRestClient:60 urlSssionDelegate:nil]).andDo(^(NSInvocation *invocation) {
        swrveMock.restClient = mockRestClient;
    });

    return swrveMock;
}

+ (id)swrveMockWithMockedRestClient {
    // mock all rest calls with success and empty data
    SwrveRESTClient *restClient = [[SwrveRESTClient alloc] initWithTimeoutInterval:60];
    id mockRestClient = OCMPartialMock(restClient);
    id mockResponse = OCMClassMock([NSHTTPURLResponse class]);
    OCMStub([mockResponse statusCode]).andReturn(500);
    NSData *mockData = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];
    OCMStub([mockRestClient sendHttpRequest:OCMOCK_ANY
                          completionHandler:([OCMArg invokeBlockWithArgs:mockResponse, mockData, [NSNull null], nil])]);

    Swrve *swrveMock = (Swrve *) OCMPartialMock([Swrve alloc]);
    OCMStub([swrveMock initSwrveRestClient:60 urlSssionDelegate:nil]).andDo(^(NSInvocation *invocation) {
        swrveMock.restClient = mockRestClient;
    });

    return swrveMock;
}

+ (Swrve *)initializeSwrveWithCampaignsFile:(NSString *)filename andConfig:(SwrveConfig *)config {
    return [self initialiseSwrveWithFile:filename type:SWRVE_CAMPAIGN_FILE andConfig:config];
}

+ (Swrve *)initializeSwrveWithRealTimeUserPropertiesFile:(NSString *)filename andConfig:(SwrveConfig *)config {
    return [self initialiseSwrveWithFile:filename type:SWRVE_REAL_TIME_USER_PROPERTIES_FILE andConfig:config];
}

+ (Swrve *)initialiseSwrveWithFile:(NSString *)filename type:(int)fileType andConfig:(SwrveConfig *)config {
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
    SwrveSignatureProtectedFile *campaignFile = [[SwrveSignatureProtectedFile alloc] protectedFileType:fileType
                                                                                                userID:userId
                                                                                          signatureKey:signatureKey
                                                                                         errorDelegate:nil];
    [self overwriteCampaignFile:campaignFile withFile:filename];

    [config setAutoDownloadCampaignsAndResources:NO];

    [SwrveLogger debug:@"Finished setting up campaign data for unit tests...", nil];
    Swrve *swrveMock = [SwrveTestHelper swrveMockWithMockedRestClient];
    OCMStub([swrveMock getNow]).andReturn(date);
    swrveMock = [swrveMock initWithAppID:123 apiKey:apiKey config:config];
    [swrveMock appDidBecomeActive:nil];
    [SwrveSDK addSharedInstance:swrveMock];

    return swrveMock;
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

+ (void)overwriteCampaignFile:(SwrveSignatureProtectedFile *)signatureFile withFile:(NSString *)filename {
    NSURL *path = [[NSBundle bundleForClass:[Swrve class]] URLForResource:filename withExtension:@"json"];
    NSString *campaignData = [NSString stringWithContentsOfURL:path encoding:NSUTF8StringEncoding error:nil];
    if (campaignData == nil) {
        [NSException raise:@"No content in JSON test file" format:@"File %@ has no content", filename];
    }
    [SwrveTestHelper writeData:campaignData toProtectedFile:signatureFile];
}

#if TARGET_OS_IOS
+ (void)setScreenOrientation:(enum UIInterfaceOrientation)orientation {
    [[UIDevice currentDevice] setValue: [NSNumber numberWithInteger: orientation]
                                forKey:@"orientation"];
}
#endif //TARGET_OS_IOS

@end
