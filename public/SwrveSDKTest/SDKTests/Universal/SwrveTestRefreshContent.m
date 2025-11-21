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

@interface Swrve (Internal)
@property(atomic) NSDate *campaignsAndResourcesLastRefreshed;
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
    NSData *mockResponseData = [responseBody dataUsingEncoding:NSUTF8StringEncoding];
    Swrve *swrveMock = [SwrveTestHelper swrveMockResponse:httpCode mockData:mockResponseData];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrveMock initWithAppID:572 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop
    return swrveMock;
}

@end
