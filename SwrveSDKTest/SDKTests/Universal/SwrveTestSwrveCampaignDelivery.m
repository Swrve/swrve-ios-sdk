#import <XCTest/XCTest.h>
#import "SwrveCampaignDelivery.h"
#import <OCMock/OCMock.h>
#import "SwrveUtils.h"
@interface SwrveTestSwrveCampaignDelivery : XCTestCase

@property id classNSFileManagerMock;

@end
@interface SwrveCampaignDelivery ()

// Force exterl public keys
extern NSString *const SwrveDeliveryConfigKey;
extern NSString *const SwrveDeliveryRequiredConfigUserIdKey;
extern NSString *const SwrveDeliveryRequiredConfigEventsUrlKey;
extern NSString *const SwrveDeliveryRequiredConfigDeviceIdKey;
extern NSString *const SwrveDeliveryRequiredConfigSessionTokenKey;
extern NSString *const SwrveDeliveryRequiredConfigAppVersionKey;

// Force public interface for private methods.
+ (BOOL) isValidAppGroupId:(NSString *)appId;
+ (NSInteger)nextEventSequenceWithUserId:(NSString *)userId forUserDefaults:(NSUserDefaults *)defaults;
@end

@implementation SwrveTestSwrveCampaignDelivery


- (void)setUp {
    [super setUp];
    // Partial mock of NSFileManager to Force a valid return when check for the valid GroupId.
    self.classNSFileManagerMock = OCMPartialMock([NSFileManager defaultManager]);
    OCMExpect([self.classNSFileManagerMock containerURLForSecurityApplicationGroupIdentifier:OCMOCK_ANY]).andReturn([NSURL new]);
}

- (void)tearDown {
    [self.classNSFileManagerMock stopMocking];
    [super tearDown];
}


- (void)testIsValidAppGroupId {
    
    XCTAssertTrue([SwrveCampaignDelivery isValidAppGroupId:@"whatEverAppId"]);
    XCTAssertFalse([SwrveCampaignDelivery isValidAppGroupId:@""]);
    XCTAssertFalse([SwrveCampaignDelivery isValidAppGroupId:nil]);
}

- (void)testSaveAndReadConfigForPushDelivery {
    NSString *userId = @"userId";
    NSString *serverUrl = @"server.url";
    NSString *deviceId = @"deviceId";
    NSString *sessionToken = @"sessionToken";
    NSString *appVersion = @"appVersion";
    NSString *appGroupId = @"app.groupid";

    // Force an empty info into our storage.
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:appGroupId];
    [userDefaults removeObjectForKey:SwrveDeliveryConfigKey];
    NSDictionary *deliveryConfig = [userDefaults dictionaryForKey:SwrveDeliveryConfigKey];
    XCTAssertNil(deliveryConfig);

    [SwrveCampaignDelivery saveConfigForPushDeliveryWithUserId:userId
                                            WithEventServerUrl:serverUrl
                                                  WithDeviceId:deviceId
                                              WithSessionToken:sessionToken
                                                WithAppVersion:appVersion
                                                 ForAppGroupID:appGroupId];

    // Update storadConfigs after save the values for final test.
    deliveryConfig = [userDefaults dictionaryForKey:SwrveDeliveryConfigKey];
    XCTAssertEqualObjects(deliveryConfig[SwrveDeliveryRequiredConfigUserIdKey], userId);
    XCTAssertEqualObjects(deliveryConfig[SwrveDeliveryRequiredConfigEventsUrlKey], serverUrl);
    XCTAssertEqualObjects(deliveryConfig[SwrveDeliveryRequiredConfigDeviceIdKey], deviceId);
    XCTAssertEqualObjects(deliveryConfig[SwrveDeliveryRequiredConfigSessionTokenKey], sessionToken);
    XCTAssertEqualObjects(deliveryConfig[SwrveDeliveryRequiredConfigAppVersionKey], appVersion);
}

- (void)testNextEventSequence {

    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"whatever.group"];
    [userDefaults setObject:nil forKey:@"MyFirstUserIdswrve_event_seqnum"];
    [userDefaults setObject:nil forKey:@"MyOtherUserIdswrve_event_seqnum"];
    XCTAssertEqual(1, [SwrveCampaignDelivery nextEventSequenceWithUserId:@"MyFirstUserId" forUserDefaults:userDefaults]);
    XCTAssertEqual(2, [SwrveCampaignDelivery nextEventSequenceWithUserId:@"MyFirstUserId" forUserDefaults:userDefaults]);

    XCTAssertEqual(1, [SwrveCampaignDelivery nextEventSequenceWithUserId:@"MyOtherUserId" forUserDefaults:userDefaults]);
    XCTAssertEqual(2, [SwrveCampaignDelivery nextEventSequenceWithUserId:@"MyOtherUserId" forUserDefaults:userDefaults]);

    XCTAssertEqual(3, [SwrveCampaignDelivery nextEventSequenceWithUserId:@"MyFirstUserId" forUserDefaults:userDefaults]);
}
@end
