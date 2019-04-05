#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "SwrveSDK.h"
#import "SwrveTestHelper.h"

@interface Swrve (Internal)
- (void)appDidBecomeActive:(NSNotification *)notification;
- (NSDate *)getNow;
@end

@interface SwrveTestInit : XCTestCase

@end

@implementation SwrveTestInit


- (void)setUp {
    [super setUp];
    [SwrveTestHelper setUp];
}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [super tearDown];
}

- (void)testSessionDelegate {

    [SwrveSDK sharedInstanceWithAppID:572 apiKey:@"SomeAPIKey"];
    id mockSwrve = OCMPartialMock([SwrveSDK sharedInstance]);

    id mockSwrveSessionDelegate1 = OCMProtocolMock(@protocol(SwrveSessionDelegate)); // mock SessionDelegate for each verify
    [mockSwrve setSwrveSessionDelegate:mockSwrveSessionDelegate1];
    OCMExpect([mockSwrveSessionDelegate1 sessionStarted]);

    [mockSwrve appDidBecomeActive:nil];

    OCMVerifyAll(mockSwrve);
    OCMVerifyAll(mockSwrveSessionDelegate1);

    // Calling a second time within the same session should not call the mockSwrveSessionDelegate
    id mockSwrveSessionDelegate2 = OCMProtocolMock(@protocol(SwrveSessionDelegate)); // mock SessionDelegate for each verify
    [mockSwrve setSwrveSessionDelegate:mockSwrveSessionDelegate2];
    OCMReject([mockSwrveSessionDelegate2 sessionStarted]);
    [mockSwrve appDidBecomeActive:nil];
    OCMVerifyAll(mockSwrveSessionDelegate2);

    // Calling a third time, but fast forward time by 30 seconds. mockSwrveSessionDelegate should be called as its a new session
    id mockSwrveSessionDelegate3 = OCMProtocolMock(@protocol(SwrveSessionDelegate)); // mock SessionDelegate for each verify
    [mockSwrve setSwrveSessionDelegate:mockSwrveSessionDelegate3];
    OCMExpect([mockSwrveSessionDelegate3 sessionStarted]);
    NSDate *date30SecondsLater = [[NSDate date] dateByAddingTimeInterval:30];
    OCMStub([mockSwrve getNow]).andReturn(date30SecondsLater);
    [mockSwrve appDidBecomeActive:nil];
    OCMVerifyAll(mockSwrveSessionDelegate3);
}


@end
