#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "SwrveProfileManager.h"
#import "Swrve.h"
#import "SwrveTestHelper.h"
#import "SwrveLocalStorage.h"
#import "SwrveMockNSURLProtocol.h"
#import "SwrveSDK.h"
#import "SwrvePermissions.h"

@interface Swrve (InternalAccess)

@property (atomic) BOOL initialised;
@property (atomic) SwrveProfileManager *profileManager;
-(void)registerLifecycleCallbacks;
-(void)initWithUserId:(NSString *)swrveUserId;

@end

@interface SwrveTestProfileManager : XCTestCase

@end

@implementation SwrveTestProfileManager

- (void)setUp {
    [super setUp];
    [SwrveTestHelper setUp];

    [NSURLProtocol registerClass:[SwrveMockNSURLProtocol class]];
    
#if TARGET_OS_IOS /** exclude tvOS **/
    id classMock = OCMClassMock([SwrvePermissions class]);
    OCMStub(ClassMethod([classMock pushAuthorizationWithSDK:OCMOCK_ANY])).andReturn(@"unittest");
#endif

}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [super tearDown];
}

- (void)testInit {

    Swrve *swrve = [Swrve alloc];
    id swrveMock = OCMPartialMock(swrve);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrve initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop
    XCTAssertNotNil([swrve userID], "UserId should automatically be created by default");

    OCMVerify([swrveMock registerLifecycleCallbacks]);
    OCMVerify([swrveMock initWithUserId:OCMOCK_ANY]);

    [swrveMock stopMocking];
}

- (void)testUserIdInitFromLocalStorage {

    SwrveConfig *config = [[SwrveConfig alloc] init];
    [SwrveLocalStorage saveSwrveUserId:@"SomeUserId"];
    Swrve *swrve = [Swrve alloc];
    id swrveMock = OCMPartialMock(swrve);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrve initWithAppID:123 apiKey:@"SomeAPIKey" config:config];
#pragma clang diagnostic pop
    NSString* currentUserId = [swrve userID];
    XCTAssertEqualObjects(currentUserId, @"SomeUserId", @"The current user should be SomeUserId but was: %@", currentUserId);

    OCMVerify([swrveMock registerLifecycleCallbacks]);
    OCMVerify([swrveMock initWithUserId:OCMOCK_ANY]);

    [swrveMock stopMocking];
}

- (void)testNoUserIdInitFromConfig {
    
    SwrveConfig *config = [[SwrveConfig alloc] init];
    Swrve *swrve = [Swrve alloc];
    id swrveMock = OCMPartialMock(swrve);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrve initWithAppID:123 apiKey:@"SomeAPIKey" config:config];
#pragma clang diagnostic pop
    NSString *currentUserId = [swrve userID];
    XCTAssertTrue((bool)[[NSUUID alloc] initWithUUIDString:currentUserId]);

    OCMVerify([swrveMock registerLifecycleCallbacks]);
    OCMVerify([swrveMock initWithUserId:OCMOCK_ANY]);
    
    [swrveMock stopMocking];
}

- (void)testUserIdNoConfig {
    
    Swrve *swrve = [Swrve alloc];
    id swrveMock = OCMPartialMock(swrve);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrve initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop
    NSString *currentUserId = [swrve userID];
    XCTAssertTrue((bool)[[NSUUID alloc] initWithUUIDString:currentUserId]);
    
    OCMVerify([swrveMock registerLifecycleCallbacks]);
    OCMVerify([swrveMock initWithUserId:OCMOCK_ANY]);
    
    [swrveMock stopMocking];
}

- (void)testIsNewUser {
    Swrve *swrve = [Swrve alloc];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrve initWithAppID:1 apiKey:@"SomeApiKey"];
#pragma clang diagnostic pop

    XCTAssertTrue(swrve.profileManager.isNewUser, @"Init with an initial User, so the isNewUser flag should be true");

    //simulate app restart
    [swrve initWithUserId:[swrve userID]];
    XCTAssertFalse(swrve.profileManager.isNewUser, @"Init with the same User, so the isNewUser flag should be false");

    //simulate a new user init
    [swrve initWithUserId:@"A different SwrveUserId"];
    XCTAssertTrue(swrve.profileManager.isNewUser, @"Init with a new user, so the isNewUser flag should be true");
}

@end
