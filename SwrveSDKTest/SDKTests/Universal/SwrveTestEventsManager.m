#import <XCTest/XCTest.h>
#import "SwrveEventsManager.h"
@interface SwrveTestEventsManager : XCTestCase

@end

@implementation SwrveTestEventsManager

- (void)testIsValidEvent_Nil {
    SwrveEventsManager *swrveEventsManager = [SwrveEventsManager new];
    bool result = [swrveEventsManager isValidEventName:nil];
    XCTAssertFalse(result);
}

- (void)testIsValidEvent_EmptyString {
    SwrveEventsManager *swrveEventsManager = [SwrveEventsManager new];
    bool result = [swrveEventsManager isValidEventName:@""];
    XCTAssertTrue(result);
}

- (void)testIsValidEvent_restrictedStringLowerCase {
    SwrveEventsManager *swrveEventsManager = [SwrveEventsManager new];
    bool result = [swrveEventsManager isValidEventName:@"Swrve.test"];
    XCTAssertFalse(result);
}

- (void)testIsValidEvent_restrictedStringUpperCase {
    SwrveEventsManager *swrveEventsManager = [SwrveEventsManager new];
    bool result = [swrveEventsManager isValidEventName:@"swrve.test"];
    XCTAssertFalse(result);
}

- (void)testIsValidEvent_allowedString {
    SwrveEventsManager *swrveEventsManager = [SwrveEventsManager new];
    bool result = [swrveEventsManager isValidEventName:@"test"];
    XCTAssertTrue(result);
}

@end
