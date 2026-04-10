#import <XCTest/XCTest.h>
#import "SwrveTestHelper.h"
#if __has_include(<OCMock/OCMock.h>)
#import <OCMock/OCMock.h>
#endif

#if __has_include(<SwrveSDK/SwrveSDK-Swift.h>)
#import <SwrveSDK/SwrveSDK-Swift.h>
#elif __has_include("SwrveSDK-Swift.h")
#import "SwrveSDK-Swift.h"
#endif

#if TARGET_OS_TV
#import "SwrveSDK_tvOSTests-Swift.h"
#else
#import "SwrveSDK_iOSTests-Swift.h"
#endif

@interface SwrveSDK (InternalAccess)
+ (void)resetSwrveSharedInstance;
+ (void)addSharedInstance:(Swrve *)instance;
@end

@interface Swrve (Internal)
@property(atomic) NSDate *campaignsAndResourcesLastRefreshed;
@property(atomic) id profileManager;
@end

@interface NSObject (SwrveProfileManagerInternal)
- (void)switchUser:(NSString *)userId;
- (void)persistUser;
- (void)generateNewUser:(NSString *)disabledSwrveUserId;
@end

@interface SwrveUserDisabledDelegateSpy : NSObject <SwrveUserDisabledDelegate>
@property(nonatomic) NSInteger callCount;
@property(nonatomic, copy) NSString *disabledUserId;
@property(nonatomic, copy) NSString *externalUserId;
@end

@implementation SwrveUserDisabledDelegateSpy

- (void)userDisabled:(NSString *)userId externalId:(NSString *)externalId {
    self.callCount += 1;
    self.disabledUserId = userId;
    self.externalUserId = externalId;
}

@end

@interface SwrveTestRefreshContent : XCTestCase

@end

@implementation SwrveTestRefreshContent

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
    [SwrveTestHelper tearDown];
}

- (void) testRefreshContent_sdkNotReady {
    Swrve *swrveMock = [self swrveMockWithResponseCode:200 responseBody:@""];

    [swrveMock stopTracking]; // stop tracking so that the sdk is not ready erromessage is received
    
    id mockRefreshContentDelegate = OCMProtocolMock(@protocol(SwrveRefreshContentDelegate));
    [swrveMock refreshContent:mockRefreshContentDelegate];
    
    OCMVerify([mockRefreshContentDelegate onComplete:[OCMArg checkWithBlock:^BOOL(SwrveRefreshContentResult* result) {
        return result.resultCode == SwrveRefreshContentResultCodeERROR
        && [result.errorMessage isEqualToString:@"SDK is not ready"];
    }]]);
}

- (void) testRefreshContent_rateLimited {
    Swrve *swrveMock = [SwrveTestHelper swrveBasicMockResponse];
    SwrveConfig *config = [SwrveConfig new];
    [config setAutoDownloadCampaignsAndResources:false]; // set the autoDownloadCampaignsAndResources conbfig to false
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrveMock initWithAppID:572 apiKey:@"SomeAPIKey" config:config];
#pragma clang diagnostic pop
    
    NSTimeInterval oneDayInSeconds = 24 * 60 * 60;
    swrveMock.campaignsAndResourcesLastRefreshed = [[NSDate new] dateByAddingTimeInterval:oneDayInSeconds]; // Advance the last refresh date to tomorrow.
    
    id mockRefreshContentDelegate = OCMProtocolMock(@protocol(SwrveRefreshContentDelegate));
    [swrveMock refreshContent:mockRefreshContentDelegate];
    
    OCMVerify([mockRefreshContentDelegate onComplete:[OCMArg checkWithBlock:^BOOL(SwrveRefreshContentResult* result) {
        return result.resultCode == SwrveRefreshContentResultCodeERROR
        && [result.errorMessage isEqualToString:@"Request to retrieve campaign and user resource data was rate-limited"];
    }]]);
}

- (void) testRefreshContent_restServerError {
    Swrve *swrveMock = [self swrveMockWithResponseCode:500 responseBody:@"Server error 500"];
    
    id mockRefreshContentDelegate = OCMProtocolMock(@protocol(SwrveRefreshContentDelegate));
    [swrveMock refreshContent:mockRefreshContentDelegate];
    
    OCMVerify([mockRefreshContentDelegate onComplete:[OCMArg checkWithBlock:^BOOL(SwrveRefreshContentResult* result) {
        return result.resultCode == SwrveRefreshContentResultCodeERROR
        && [result.errorMessage isEqualToString:@"Server error 500"]
        && result.httpResponseCode == 500;
    }]]);
}

- (void) testRefreshContent_restFailure {
    Swrve *swrveMock = [self swrveMockWithResponseCode:999 responseBody:@"Failure error 999"];
    
    id mockRefreshContentDelegate = OCMProtocolMock(@protocol(SwrveRefreshContentDelegate));
    [swrveMock refreshContent:mockRefreshContentDelegate];
    
    OCMVerify([mockRefreshContentDelegate onComplete:[OCMArg checkWithBlock:^BOOL(SwrveRefreshContentResult* result) {
        return result.resultCode == SwrveRefreshContentResultCodeERROR_UNKNOWN
        && [result.errorMessage isEqualToString:@"A custom NSError occurred"]
        && result.httpResponseCode == 0;
    }]]);
}

- (void) testRefreshContent_restSuccess {
    Swrve *swrveMock = [self swrveMockWithResponseCode:200 responseBody:@"{}"];
    
    id mockRefreshContentDelegate = OCMProtocolMock(@protocol(SwrveRefreshContentDelegate));
    [swrveMock refreshContent:mockRefreshContentDelegate];
    
    OCMVerify([mockRefreshContentDelegate onComplete:[OCMArg checkWithBlock:^BOOL(SwrveRefreshContentResult* result) {
        return result.resultCode == SwrveRefreshContentResultCodeSUCCESS
        && [result.errorMessage isEqualToString:@""]
        && result.httpResponseCode == 200;
    }]]);
}

- (id)swrveMockWithResponseCode:(int)httpCode responseBody:(NSString *)responseBody {
    return [self swrveMockWithResponseCode:httpCode responseBody:responseBody config:[SwrveConfig new]];
}

- (id)swrveMockWithResponseCode:(int)httpCode responseBody:(NSString *)responseBody config:(SwrveConfig *)config {
    NSData *mockResponseData = [responseBody dataUsingEncoding:NSUTF8StringEncoding];
    Swrve *swrveMock = [SwrveTestHelper swrveMockResponse:httpCode mockData:mockResponseData];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrveMock initWithAppID:572 apiKey:@"SomeAPIKey" config:config];
#pragma clang diagnostic pop
    [SwrveSDK resetSwrveSharedInstance];
    [SwrveSDK addSharedInstance:swrveMock];
    return swrveMock;
}

- (NSArray<NSString *> *)seedPathsForUserId:(NSString *)userId {
    return @[
        [SwrveLocalStorage eventsFilePathForUserId:userId],
        [SwrveLocalStorage campaignsFilePathForUserId:userId],
        [SwrveLocalStorage campaignsSignatureFilePathForUserId:userId],
        [SwrveLocalStorage userResourcesFilePathForUserId:userId],
        [SwrveLocalStorage pushInboxFilePathForUserId:userId],
        [SwrveLocalStorage offlineCampaignsFilePathForUserId:userId]
    ];
}

- (void)seedUserDataForUserId:(NSString *)userId {
    for (NSString *path in [self seedPathsForUserId:userId]) {
        [@"test" writeToFile:path
                  atomically:YES
                    encoding:NSUTF8StringEncoding
                       error:nil];
        XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:path]);
    }

    [SwrveLocalStorage saveETag:@"etag" forUserId:userId];
    [SwrveLocalStorage savePushInboxHash:@"hash" forUserId:userId];
}

- (void)assertUserDataDeletedForUserId:(NSString *)userId {
    for (NSString *path in [self seedPathsForUserId:userId]) {
        XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:path],
                       @"Expected file to be deleted: %@", path);
    }

    XCTAssertNil([SwrveLocalStorage eTagForUserId:userId]);
    XCTAssertNil([SwrveLocalStorage pushInboxHashForUserId:userId]);
}

- (void)testEvent401DisablesCurrentUser {
    SwrveConfig *config = [[SwrveConfig alloc] init];
    SwrveUserDisabledDelegateSpy *userDisabledDelegate = [SwrveUserDisabledDelegateSpy new];
    config.userDisabledDelegate = userDisabledDelegate;

    Swrve *swrve = [self swrveMockWithResponseCode:200 responseBody:@"{}" config:config];
    NSString *userIdBefore = swrve.userID;
    NSData *responseData = [@"{ \"code\" : 401, \"message\" : \"User access has been disabled\"}" dataUsingEncoding:NSUTF8StringEncoding];

    [self seedUserDataForUserId:userIdBefore];

    [swrve.profileManager handleDisableUser:responseData
                                     userId:userIdBefore
                       userDisabledDelegate:userDisabledDelegate];

    XCTAssertEqual(userDisabledDelegate.callCount, 1);
    XCTAssertEqualObjects(userDisabledDelegate.disabledUserId, userIdBefore);
    XCTAssertNotEqualObjects(swrve.userID, userIdBefore);
    XCTAssertFalse([swrve started]);
    [self assertUserDataDeletedForUserId:userIdBefore];
}


- (void)testHandleDisableUserDuplicateDisabledResponseIgnored {
    SwrveConfig *config = [[SwrveConfig alloc] init];
    SwrveUserDisabledDelegateSpy *userDisabledDelegate = [SwrveUserDisabledDelegateSpy new];
    config.userDisabledDelegate = userDisabledDelegate;

    Swrve *swrve = [self swrveMockWithResponseCode:200 responseBody:@"{}" config:config];
    NSString *userIdBefore = swrve.userID;
    NSData *responseData = [@"{ \"code\" : 401, \"message\" : \"User access has been disabled\"}" dataUsingEncoding:NSUTF8StringEncoding];

    [self seedUserDataForUserId:userIdBefore];

    [swrve.profileManager handleDisableUser:responseData
                                     userId:userIdBefore
                       userDisabledDelegate:userDisabledDelegate];
    NSString *userIdAfterFirst401 = swrve.userID;

    [swrve.profileManager handleDisableUser:responseData
                                     userId:userIdBefore
                       userDisabledDelegate:userDisabledDelegate];

    XCTAssertEqual(userDisabledDelegate.callCount, 1);
    XCTAssertEqualObjects(userDisabledDelegate.disabledUserId, userIdBefore);
    XCTAssertEqualObjects(swrve.userID, userIdAfterFirst401);
    XCTAssertFalse([swrve started]);
    [self assertUserDataDeletedForUserId:userIdBefore];
}

- (void)testHandleDisableUserDoesNotStopTrackingWhenCurrentUserChanged {
    SwrveConfig *config = [[SwrveConfig alloc] init];
    SwrveUserDisabledDelegateSpy *userDisabledDelegate = [SwrveUserDisabledDelegateSpy new];
    config.userDisabledDelegate = userDisabledDelegate;

    Swrve *swrve = [self swrveMockWithResponseCode:200 responseBody:@"{}" config:config];
    NSString *disabledUserId = swrve.userID;
    NSString *activeUserId = @"456";
    NSData *responseData = [@"{ \"code\" : 401, \"message\" : \"User access has been disabled\"}" dataUsingEncoding:NSUTF8StringEncoding];

    [self seedUserDataForUserId:disabledUserId];

    [swrve.profileManager switchUser:activeUserId];
    [swrve.profileManager persistUser];
    XCTAssertEqualObjects(swrve.userID, activeUserId);
    XCTAssertTrue([swrve started]);

    [swrve.profileManager handleDisableUser:responseData
                                     userId:disabledUserId
                       userDisabledDelegate:userDisabledDelegate];

    XCTAssertEqual(userDisabledDelegate.callCount, 1);
    XCTAssertEqualObjects(userDisabledDelegate.disabledUserId, disabledUserId);
    XCTAssertEqualObjects(swrve.userID, activeUserId);
    XCTAssertTrue([swrve started]);
    [self assertUserDataDeletedForUserId:disabledUserId];
}

@end
