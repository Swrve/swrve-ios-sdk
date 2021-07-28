#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SwrveSEConfig.h"
@interface SwrveTestSwrveCampaignDelivery : XCTestCase

@property id classNSFileManagerMock;

@end

@implementation SwrveTestSwrveCampaignDelivery

- (void)setUp {
    [super setUp];
    // Partial mock of NSFileManager to Force a valid return when check for the valid GroupId.
    self.classNSFileManagerMock = OCMPartialMock([NSFileManager defaultManager]);
    NSURL *someURL = [NSURL fileURLWithPath:@"somePath"];
    OCMStub([self.classNSFileManagerMock containerURLForSecurityApplicationGroupIdentifier:OCMOCK_ANY]).andReturn(someURL);
}

- (void)tearDown {
    [self.classNSFileManagerMock stopMocking];
    [super tearDown];
}

- (void)testIsValidAppGroupId {
    XCTAssertTrue([SwrveSEConfig isValidAppGroupId:@"whatEverAppId"]);
    XCTAssertFalse([SwrveSEConfig isValidAppGroupId:@""]);
    XCTAssertFalse([SwrveSEConfig isValidAppGroupId:nil]);
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

    [SwrveSEConfig saveAppGroupId:appGroupId
                           userId:userId
                   eventServerUrl:serverUrl
                         deviceId:deviceId
                     sessionToken:sessionToken
                       appVersion:appVersion
                         isQAUser:NO];

    // Update deliveryConfig after save the values for final test.
    deliveryConfig = [userDefaults dictionaryForKey:SwrveDeliveryConfigKey];
    XCTAssertEqualObjects(deliveryConfig[SwrveDeliveryRequiredConfigUserIdKey], userId);
    XCTAssertEqualObjects(deliveryConfig[SwrveDeliveryRequiredConfigEventsUrlKey], serverUrl);
    XCTAssertEqualObjects(deliveryConfig[SwrveDeliveryRequiredConfigDeviceIdKey], deviceId);
    XCTAssertEqualObjects(deliveryConfig[SwrveDeliveryRequiredConfigSessionTokenKey], sessionToken);
    XCTAssertEqualObjects(deliveryConfig[SwrveDeliveryRequiredConfigAppVersionKey], appVersion);
    XCTAssertEqualObjects(deliveryConfig[SwrveDeliveryRequiredConfigIsQAUser], [NSNumber numberWithBool:NO]);

    // Save again now as QAUser.
    [SwrveSEConfig saveAppGroupId:appGroupId
                           userId:userId
                   eventServerUrl:serverUrl
                         deviceId:deviceId
                     sessionToken:sessionToken
                       appVersion:appVersion
                         isQAUser:YES];

    deliveryConfig = [userDefaults dictionaryForKey:SwrveDeliveryConfigKey];
    XCTAssertEqualObjects(deliveryConfig[SwrveDeliveryRequiredConfigIsQAUser], [NSNumber numberWithBool:YES]);
}

- (void)testNextEventSequence {

    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"whatever.group"];
    [userDefaults setObject:nil forKey:@"MyFirstUserIdswrve_event_seqnum"];
    [userDefaults setObject:nil forKey:@"MyOtherUserIdswrve_event_seqnum"];
    XCTAssertEqual(1, [SwrveSEConfig nextSeqnumForAppGroupId:@"whatever.group" userId:@"MyFirstUserId"]);
    XCTAssertEqual(2, [SwrveSEConfig nextSeqnumForAppGroupId:@"whatever.group" userId:@"MyFirstUserId"]);

    XCTAssertEqual(1, [SwrveSEConfig nextSeqnumForAppGroupId:@"whatever.group" userId:@"MyOtherUserId"]);
    XCTAssertEqual(2, [SwrveSEConfig nextSeqnumForAppGroupId:@"whatever.group" userId:@"MyOtherUserId"]);

    XCTAssertEqual(3, [SwrveSEConfig nextSeqnumForAppGroupId:@"whatever.group" userId:@"MyFirstUserId"]);
}

- (void)testTrackingStateStopped {

    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"whatever.group"];
    [userDefaults setObject:nil forKey:@"swrve.is_tracking_state_stopped"];
    XCTAssertFalse([SwrveSEConfig isTrackingStateStopped:@"whatever.group"]);
    [SwrveSEConfig saveTrackingStateStopped:@"whatever.group" isTrackingStateStopped:YES];
    XCTAssertTrue([SwrveSEConfig isTrackingStateStopped:@"whatever.group"]);
    [SwrveSEConfig saveTrackingStateStopped:@"whatever.group" isTrackingStateStopped:NO];
    XCTAssertFalse([SwrveSEConfig isTrackingStateStopped:@"whatever.group"]);
}

@end
