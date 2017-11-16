#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "SwrveProfileManager.h"
#import "Swrve.h"
#import "SwrveTestHelper.h"

@interface Swrve (InternalAccess)

@property (atomic) BOOL initialised;
@property (atomic) SwrveProfileManager *profileManager;
-(void) registerLifecycleCallbacks;
- (void)initWithUserId:(NSString *)swrveUserId;

@end

@interface SwrveTestProfileManager : XCTestCase

@end

@implementation SwrveTestProfileManager

- (void)setUp {
    [super setUp];
    [SwrveTestHelper tearDown];
}

- (void)tearDown {
    [super tearDown];
    [SwrveTestHelper tearDown];
}

- (void)testInit {

    Swrve *swrve = [Swrve alloc];
    id swrveMock = OCMPartialMock(swrve);
    [swrve initWithAppID:123 apiKey:@"SomeAPIKey"];
    NSString *userId = [swrve userID];
    XCTAssertNotNil(userId, "UserId should be automatically be created by default");

    OCMVerify([swrveMock registerLifecycleCallbacks]);
    OCMVerify([swrveMock initWithUserId:[OCMArg any]]);

    [swrveMock stopMocking];
}

- (void)testInitWithUserIdConfig {

    SwrveConfig* config = [[SwrveConfig alloc] init];
    config.userId = @"joe";
    Swrve *swrve = [Swrve alloc];
    id swrveMock = OCMPartialMock(swrve);
    [swrve initWithAppID:123 apiKey:@"SomeAPIKey" config:config];
    NSString *userId = [swrve userID];
    XCTAssertEqual([swrve userID], @"joe", @"The current user should be joe.");

    OCMVerify([swrveMock registerLifecycleCallbacks]);
    OCMVerify([swrveMock initWithUserId:[OCMArg any]]);

    [swrveMock stopMocking];
}

- (void)testIsNewUser {

    Swrve *swrve = [[Swrve alloc] initWithAppID:123 apiKey:@"SomeAPIKey"];
    NSString *userId = [swrve userID];
    SwrveProfileManager *profileManager = [swrve profileManager];
    XCTAssertTrue([profileManager isNewUser], @"Brand new fresh install, so the isNewUser flag should be true");

    [SwrveTestHelper destroySharedInstance];
    swrve = [[Swrve alloc] initWithAppID:123 apiKey:@"SomeAPIKey"];
    profileManager = [swrve profileManager];
    XCTAssertTrue([[swrve userID] isEqualToString:userId], @"Previous user:%@ should still be logged in. Current user:%@", userId, [swrve userID]);
    XCTAssertTrue([profileManager isNewUser] == NO, @"Same user as previously auto logged in, so the isNewUser flag should be false now:%@", [profileManager isNewUser] ? @"true" : @"false");
}

@end
