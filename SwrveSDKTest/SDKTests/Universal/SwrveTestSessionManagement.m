#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "Swrve.h"
#import "SwrveTestHelper.h"

@interface Swrve () {
    NSDate *lastSessionDate;
}
- (void)queueSessionStart;
- (void)appDidBecomeActive:(NSNotification *)notification;
- (void)logDeviceInfo:(NSDictionary *)deviceProperties;
- (void)sendQueuedEventsWithCallback:(void (^)(NSURLResponse *response, NSData *data, NSError *error))eventBufferCallback
                   eventFileCallback:(void (^)(NSURLResponse *response, NSData *data, NSError *error))eventFileCallback;

@end

@interface SwrveTestSessionManagement : XCTestCase

@end

@implementation SwrveTestSessionManagement

- (void)setUp {
    [super setUp];
    [SwrveTestHelper setUp];
}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [super tearDown];
}

- (void)testSessionManagement {
    id config = OCMClassMock([SwrveConfig class]);
    OCMStub([config newSessionInterval]).andReturn(30);
    
    Swrve *swrve = [Swrve alloc];
    id mockSwrve = OCMPartialMock(swrve);
    mockSwrve = [mockSwrve initWithAppID:123 apiKey:@"SomeAPIKey"];
    OCMStub([mockSwrve config]).andReturn(config);
    
    __block int callCount = 0;
     OCMStub([mockSwrve queueSessionStart]).andDo(^(NSInvocation *invocation) {
         ++callCount;
     });
     
    OCMStub([mockSwrve deviceInfo]).andReturn(@{});
    OCMStub([mockSwrve mergeWithCurrentDeviceInfo:OCMOCK_ANY]).andDo(nil);
    OCMStub([mockSwrve logDeviceInfo:OCMOCK_ANY]).andDo(nil);
    OCMStub([mockSwrve sendQueuedEventsWithCallback:OCMOCK_ANY eventFileCallback:OCMOCK_ANY]).andDo(nil);
    
    [mockSwrve appDidBecomeActive:nil]; // initial session start
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wundeclared-selector"
    [mockSwrve performSelector:@selector(appWillResignActive:) withObject:nil];
    [mockSwrve appDidBecomeActive:nil]; // too soon no session start
 
    [mockSwrve performSelector:@selector(appWillResignActive:) withObject:nil];
    [mockSwrve setValue:[NSDate dateWithTimeIntervalSinceNow:-31] forKey:@"lastSessionDate"];
    [swrve appDidBecomeActive:nil]; // should be another session start 30 seconds has passed.

     int expectedNumberOfCalls = 2;
     XCTAssertEqual(callCount, expectedNumberOfCalls);
}

@end
