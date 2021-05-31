#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SwrveSDK.h"
#import "SwrveMessageController.h"

@interface Swrve(privateAccess)
@property(atomic) SwrveMessageController *messaging;
@end

@interface SwrveMessageController()
- (BOOL)eventRaised:(NSDictionary *)event;
@end

@interface SwrveTestEventQueueCallback : XCTestCase
@end

@implementation SwrveTestEventQueueCallback

- (void)testSetEventQueuedCallback {
    //check when setEventQueuedCallback is set by the customer that eventRaised is called in SwrveMessageContrller when using event: OR eventWithNoCallback:

    Swrve *swrve = [Swrve alloc];
    id swrveMock = OCMPartialMock(swrve);
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrveMock initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop
    
    id messagingMock = OCMPartialMock([swrveMock messaging]);
    
    __block NSDictionary *callbackPayload = nil;
    
    [swrveMock setEventQueuedCallback:^(NSDictionary *eventPayload, NSString *eventsPayloadAsJSON) {
        callbackPayload = eventPayload;
        XCTAssertNotEqual([eventPayload valueForKey:@"name"], @"EventWithNOCallback");
    }];
    
    OCMExpect([messagingMock eventRaised:[OCMArg checkWithBlock:^BOOL(NSDictionary *dic) {
        XCTAssertEqual([dic valueForKey:@"name"], @"EventWithCallback");
        return [dic isKindOfClass:[NSDictionary class]];
    }]]);
    
    [swrveMock event:@"EventWithCallback"];
    
    XCTAssertNotNil(callbackPayload);
    
    OCMVerifyAll(messagingMock);
    
    OCMExpect([messagingMock eventRaised:[OCMArg checkWithBlock:^BOOL(NSDictionary *dic) {
        XCTAssertEqual([dic valueForKey:@"name"], @"EventWithNOCallback");
        return [dic isKindOfClass:[NSDictionary class]];
    }]]);
    
    [swrveMock eventWithNoCallback:@"EventWithNOCallback" payload:nil];
    
    OCMVerifyAll(messagingMock);
    
    [swrveMock stopMocking];
    [swrveMock stopMocking];
}
@end
