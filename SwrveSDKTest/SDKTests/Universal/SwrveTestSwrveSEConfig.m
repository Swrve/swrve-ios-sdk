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

#pragma mark - Carousel item tap

- (void)testCarouselItemTapIsConsumedOnlyByItsOwnNotification {
    NSString *appGroupId = [self freshAppGroupId];
    [[[NSUserDefaults alloc] initWithSuiteName:appGroupId] removeObjectForKey:SwrveSEConfigCarouselItemTapKey];

    [SwrveSEConfig saveCarouselItemTap:appGroupId requestId:@"request-a" itemIndex:2 action:@"https://example.com/"];

    // A direct press on an unrelated notification must not destroy the pending tap — this runs for
    // every Swrve notification, not just carousel ones.
    XCTAssertNil([SwrveSEConfig consumeCarouselItemTap:appGroupId requestId:@"request-b"]);

    NSDictionary *record = [SwrveSEConfig consumeCarouselItemTap:appGroupId requestId:@"request-a"];
    XCTAssertNotNil(record, @"the tap should survive an unrelated notification being opened first");
    XCTAssertEqualObjects([record objectForKey:SwrveCarouselItemTapIndexKey], @2);
    XCTAssertEqualObjects([record objectForKey:SwrveCarouselItemTapActionKey], @"https://example.com/");

    // Consumed on the match, so it cannot be replayed.
    XCTAssertNil([SwrveSEConfig consumeCarouselItemTap:appGroupId requestId:@"request-a"]);
}

#pragma mark - Carousel page view de-duplication

- (NSString *)freshAppGroupId {
    NSString *appGroupId = [NSString stringWithFormat:@"app.groupid.%@", [[NSUUID UUID] UUIDString]];
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:appGroupId];
    [userDefaults removeObjectForKey:SwrveSEConfigCarouselPageViewsKey];
    return appGroupId;
}

- (void)testCarouselPageViewIsRecordedOncePerItem {
    NSString *appGroupId = [self freshAppGroupId];

    XCTAssertFalse([SwrveSEConfig hasCarouselPageBeenViewed:appGroupId requestId:@"request-a" itemIndex:0]);
    [SwrveSEConfig markCarouselPageViewed:appGroupId requestId:@"request-a" itemIndex:0];
    XCTAssertTrue([SwrveSEConfig hasCarouselPageBeenViewed:appGroupId requestId:@"request-a" itemIndex:0],
                  @"re-expanding a notification must not re-report item 0");

    // Marking twice is harmless and must not corrupt the record.
    [SwrveSEConfig markCarouselPageViewed:appGroupId requestId:@"request-a" itemIndex:0];
    XCTAssertTrue([SwrveSEConfig hasCarouselPageBeenViewed:appGroupId requestId:@"request-a" itemIndex:0]);
}

- (void)testCarouselPageViewTracksEachItemSeparately {
    NSString *appGroupId = [self freshAppGroupId];

    [SwrveSEConfig markCarouselPageViewed:appGroupId requestId:@"request-a" itemIndex:0];

    XCTAssertTrue([SwrveSEConfig hasCarouselPageBeenViewed:appGroupId requestId:@"request-a" itemIndex:0]);
    XCTAssertFalse([SwrveSEConfig hasCarouselPageBeenViewed:appGroupId requestId:@"request-a" itemIndex:1]);

    [SwrveSEConfig markCarouselPageViewed:appGroupId requestId:@"request-a" itemIndex:1];
    XCTAssertTrue([SwrveSEConfig hasCarouselPageBeenViewed:appGroupId requestId:@"request-a" itemIndex:1]);
}

- (void)testCarouselPageViewDedupesPerNotificationNotPerCampaign {
    NSString *appGroupId = [self freshAppGroupId];

    [SwrveSEConfig markCarouselPageViewed:appGroupId requestId:@"request-a" itemIndex:0];

    // A second notification from the same campaign shares its push id but not its request id, so it
    // must report its own view.
    XCTAssertFalse([SwrveSEConfig hasCarouselPageBeenViewed:appGroupId requestId:@"request-b" itemIndex:0]);
}

- (void)testCarouselPageViewRecordIsBounded {
    NSString *appGroupId = [self freshAppGroupId];

    for (NSInteger i = 0; i < SwrveSEConfigCarouselPageViewsLimit; i++) {
        NSString *requestId = [NSString stringWithFormat:@"request-%ld", (long) i];
        [SwrveSEConfig markCarouselPageViewed:appGroupId requestId:requestId itemIndex:0];
    }
    // Still within the limit, so the oldest is remembered.
    XCTAssertTrue([SwrveSEConfig hasCarouselPageBeenViewed:appGroupId requestId:@"request-0" itemIndex:0]);

    // One more notification takes it over the limit, evicting the oldest.
    [SwrveSEConfig markCarouselPageViewed:appGroupId requestId:@"overflow" itemIndex:0];
    XCTAssertFalse([SwrveSEConfig hasCarouselPageBeenViewed:appGroupId requestId:@"request-0" itemIndex:0],
                   @"the oldest notification should have been evicted");
    XCTAssertTrue([SwrveSEConfig hasCarouselPageBeenViewed:appGroupId requestId:@"request-1" itemIndex:0],
                  @"newer notifications should still be remembered");
}

- (void)testCarouselPageViewRequiresRequestId {
    NSString *appGroupId = [self freshAppGroupId];

    [SwrveSEConfig markCarouselPageViewed:appGroupId requestId:nil itemIndex:0];
    [SwrveSEConfig markCarouselPageViewed:appGroupId requestId:@"" itemIndex:0];

    XCTAssertFalse([SwrveSEConfig hasCarouselPageBeenViewed:appGroupId requestId:nil itemIndex:0]);
    XCTAssertFalse([SwrveSEConfig hasCarouselPageBeenViewed:appGroupId requestId:@"" itemIndex:0]);
}

@end
