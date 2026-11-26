#import <XCTest/XCTest.h>
#import "SwrveCampaignDelivery.h"
#import <OCMock/OCMock.h>
#import <SwrveSEConfig.h>
#import "SwrveUtils.h"
#import "SwrveRESTClient.h"

@interface SwrveTestSwrveCampaignDeliveryIOS : XCTestCase

@property id classNSFileManagerMock;
@property (nonatomic) NSString *trackingData;
@end

@interface SwrveCampaignDelivery (Private)

- (NSDictionary *)pushDeliveryEvent:(NSDictionary *)userInfo userId:(NSString *)userId;

- (NSDictionary *)carouselPageViewEvent:(NSDictionary *)userInfo userId:(NSString *)userId itemIndex:(NSInteger)itemIndex;

@end

/// Normalises a parsed JSON tree so payloads compare on content, not on key order, which
/// NSJSONSerialization leaves unspecified.
///
/// Only `log_details.payload` is unwrapped, and only when it really is a string: that one value
/// carries JSON nested inside a string, so comparing it verbatim would reimpose key ordering.
/// Unwrapping strings generally would be too lax — a payload emitted as an object would then match
/// one emitted as a string, and the string form is exactly what this test exists to pin down.
static id SwrveJSONContent(id node) {
    if ([node isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *out = [NSMutableDictionary dictionaryWithCapacity:[node count]];
        [(NSDictionary *)node enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
#pragma unused(stop)
            out[key] = SwrveJSONContent(value);
        }];
        // Keep the string form asserted, and compare what it holds irrespective of key order.
        id payload = out[@"payload"];
        if (out[@"client_time"] != nil && [payload isKindOfClass:[NSString class]]) {
            NSData *embedded = [(NSString *)payload dataUsingEncoding:NSUTF8StringEncoding];
            id parsed = embedded ? [NSJSONSerialization JSONObjectWithData:embedded options:0 error:nil] : nil;
            if ([parsed isKindOfClass:[NSDictionary class]]) {
                out[@"payload"] = @{@"__jsonString": SwrveJSONContent(parsed)};
            }
        }
        return out;
    }
    if ([node isKindOfClass:[NSArray class]]) {
        NSMutableArray *out = [NSMutableArray arrayWithCapacity:[node count]];
        for (id value in (NSArray *)node) {
            [out addObject:SwrveJSONContent(value)];
        }
        return out;
    }
    return node;
}

/// `isEqual:` on NSNumber ignores how the value was written, so @YES == @1 and @1 == @1.0. Those
/// are different on the wire, so compare booleans and numbers by their Objective-C type as well.
static BOOL SwrveJSONEqual(id lhs, id rhs) {
    if ([lhs isKindOfClass:[NSDictionary class]] && [rhs isKindOfClass:[NSDictionary class]]) {
        if ([lhs count] != [rhs count]) {
            return NO;
        }
        for (id key in (NSDictionary *)lhs) {
            if (!SwrveJSONEqual(lhs[key], ((NSDictionary *)rhs)[key])) {
                return NO;
            }
        }
        return YES;
    }
    if ([lhs isKindOfClass:[NSArray class]] && [rhs isKindOfClass:[NSArray class]]) {
        if ([lhs count] != [rhs count]) {
            return NO;
        }
        for (NSUInteger i = 0; i < [lhs count]; i++) {
            if (!SwrveJSONEqual(lhs[i], ((NSArray *)rhs)[i])) {
                return NO;
            }
        }
        return YES;
    }
    if ([lhs isKindOfClass:[NSNumber class]] && [rhs isKindOfClass:[NSNumber class]]) {
        if (strcmp([lhs objCType], [rhs objCType]) != 0) {
            return NO;
        }
    }
    return [lhs isEqual:rhs];
}

/// Matches a JSON request body against `expected` by content, ignoring key order.
static id SwrveJSONBodyMatching(NSData *expected) {
    return [OCMArg checkWithBlock:^BOOL(NSData *actual) {
        if (![actual isKindOfClass:[NSData class]]) {
            return NO;
        }
        id actualJSON = [NSJSONSerialization JSONObjectWithData:actual options:0 error:nil];
        id expectedJSON = [NSJSONSerialization JSONObjectWithData:expected options:0 error:nil];
        if (actualJSON == nil || expectedJSON == nil) {
            return NO;
        }
        return SwrveJSONEqual(SwrveJSONContent(actualJSON), SwrveJSONContent(expectedJSON));
    }];
}

@implementation SwrveTestSwrveCampaignDeliveryIOS

NSString *userId = @"userId";
NSString *serverUrl = @"server.url";
NSString *deviceId = @"deviceId";
NSString *sessionToken = @"sessionToken";
NSString *appVersion = @"appVersion";
NSString *appGroupId = @"app.groupid";

- (void)setUp {
    [super setUp];
    self.trackingData = @"5ea0fb1b8a24b8f9f76f675b7350200f314312fa";
    // Partial mock of NSFileManager to Force a valid return when check for the valid GroupId.
    self.classNSFileManagerMock = OCMPartialMock([NSFileManager defaultManager]);
    OCMStub([self.classNSFileManagerMock containerURLForSecurityApplicationGroupIdentifier:OCMOCK_ANY]).andReturn([NSURL new]);
}

- (void)tearDown {
    [self.classNSFileManagerMock stopMocking];
    [super tearDown];
}

- (void)testPushDeliveryEvent {
    NSDictionary *userInfo = @{
            @"_p": @123456,
            @"_td": self.trackingData,
            @"_smp": @"iOS",
            @"sw": @{@"media":
                    @{      @"title": @"title",
                            @"body": @"body",
                            @"url": @"https://whatever.jpg"
                    },
                    @"version": @1
            }
    };
    [self assertPushDeliveryEventWithUserInfo:userInfo isSilent:NO isDisplayed:YES reason:@""];
}

- (void)testPushDeliveryEventAuthSameUser {
    NSDictionary *userInfo = @{
            @"_td": self.trackingData,
            @"_smp": @"iOS",
            @"_aui" : @"some_user",
            @"_p": @123456,
            @"sw": @{@"media":
                    @{      @"title": @"title",
                            @"body": @"body",
                            @"url": @"https://whatever.jpg"
                    },
                    @"version": @1
            }
    };
    [self assertPushDeliveryEventWithUserInfo:userInfo isSilent:NO isDisplayed:YES reason:@""];
}

- (void)testPushDeliveryEventSDKStopped {
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:appGroupId];
    [userDefaults setObject:@YES forKey:SwrveSEConfigIsTrackingStateStopped];
    NSDictionary *userInfo = @{
            @"_td": self.trackingData,
            @"_smp": @"iOS",
            @"_aui" : @"some_user",
            @"_p": @123456,
            @"sw": @{@"media":
                    @{      @"title": @"title",
                            @"body": @"body",
                            @"url": @"https://whatever.jpg"
                    },
                    @"version": @1
            }
    };
    [self assertPushDeliveryEventWithUserInfo:userInfo isSilent:NO isDisplayed:NO reason:@"stopped"];
    
    [userDefaults setObject:nil forKey:SwrveSEConfigIsTrackingStateStopped];
}

- (void)testPushDeliveryEventAuthDifferentUser {
    NSDictionary *userInfo = @{
            @"_td": self.trackingData,
            @"_smp": @"iOS",
            @"_aui" : @"some_other_user",
            @"_p": @123456,
            @"sw": @{@"media":
                    @{      @"title": @"title",
                            @"body": @"body",
                            @"url": @"https://whatever.jpg"
                    },
                    @"version": @1
            }
    };
    [self assertPushDeliveryEventWithUserInfo:userInfo isSilent:NO isDisplayed:NO reason:@"different_user"];
}

- (void)testPushDeliveryEventSilent {
    NSDictionary *userInfo = @{
            @"_td": self.trackingData,
            @"_smp": @"iOS",
            @"_sp": @123456,
            @"_s.SilentPayload": @{
                    @"k1": @"v1"}
    };
    [self assertPushDeliveryEventWithUserInfo:userInfo isSilent:YES isDisplayed:NO reason:@""];
}

- (void)assertPushDeliveryEventWithUserInfo:(NSDictionary *)userInfo isSilent:(BOOL)isSilent isDisplayed:(BOOL)isDisplayed reason:(NSString *)reason {
    id classSwrveUtilsMock = OCMClassMock([SwrveUtils class]);
    OCMStub([classSwrveUtilsMock getTimeEpoch]).andReturn(1580397679375);

    id classSwrveSEConfigMock = OCMClassMock([SwrveSEConfig class]);
    OCMStub([classSwrveSEConfigMock nextSeqnumForAppGroupId:OCMOCK_ANY userId:OCMOCK_ANY]).andReturn(100);

    SwrveCampaignDelivery *campaignDelivery = [[SwrveCampaignDelivery alloc] initAppGroupId:@"app.groupid"];
    NSDictionary *event = [campaignDelivery pushDeliveryEvent:userInfo userId:@"some_user"];

    XCTAssertEqualObjects([event objectForKey:@"type"], @"generic_campaign_event");
    XCTAssertEqualObjects([event objectForKey:@"time"], @1580397679375);
    XCTAssertEqualObjects([event objectForKey:@"seqnum"], @"100");
    XCTAssertEqualObjects([event objectForKey:@"actionType"], @"delivered");
    XCTAssertEqualObjects([event objectForKey:@"campaignType"], @"push");
    NSDictionary *expectedPayload =
                    @{
                        @"platform": @"iOS",
                        @"trackingData": self.trackingData,
                        @"displayed": [NSNumber numberWithInt:isDisplayed],
                        @"reason": reason,
                        @"silent": [NSNumber numberWithBool:isSilent]
                    };
    XCTAssertEqualObjects([event objectForKey:@"payload"], expectedPayload);
    XCTAssertEqualObjects([event objectForKey:@"id"], @123456);

    [classSwrveUtilsMock stopMocking];
}

- (void)testPushDeliveryInvalidAppGroupId {
    NSString *appGroupIdInvalid = @"";
    NSDictionary *userInfo = @{
            @"_sp": @123456,
            @"_s.SilentPayload": @{
                    @"k1": @"v1"}
    };
    id mockCampaignDelivery = OCMPartialMock([[SwrveCampaignDelivery alloc] initAppGroupId:appGroupIdInvalid]);
    OCMReject([mockCampaignDelivery pushDeliveryEvent:OCMOCK_ANY userId:OCMOCK_ANY]);
    [mockCampaignDelivery sendPushDelivery:userInfo];
    OCMVerifyAll(mockCampaignDelivery);
}

- (void)testPushDeliveryInvalidPush {
    NSDictionary *invalidUserInfo = @{@"some_invalid_push": @123};
    id mockCampaignDelivery = OCMPartialMock([[SwrveCampaignDelivery alloc] initAppGroupId:appGroupId]);
    OCMReject([mockCampaignDelivery pushDeliveryEvent:OCMOCK_ANY userId:OCMOCK_ANY]);
    [mockCampaignDelivery sendPushDelivery:invalidUserInfo];
    OCMVerifyAll(mockCampaignDelivery);
}

- (void)testSendPushDelivery {
    [self saveDummyUserDefaultsWithQaUser:NO];
    NSDictionary *userInfo = @{
            @"_td": self.trackingData,
            @"_smp": @"iOS",
            @"_p": @123456,
            @"sw": @{@"media":
                    @{@"title": @"tile",
                            @"body": @"body",
                            @"url": @"https://whatever.jpg"
                    },
                    @"version": @1
            }
    };
    [self assertSendPushDeliveryWithUserInfo:userInfo isSilent:NO isDisplayed:YES];
}

- (void)testSendPushDeliverySilent {
    [self saveDummyUserDefaultsWithQaUser:NO];
    NSDictionary *userInfo = @{
            @"_td": self.trackingData,
            @"_smp": @"iOS",
            @"_sp": @123456,
            @"_s.SilentPayload": @{
                    @"k1": @"v1"}
    };
    [self assertSendPushDeliveryWithUserInfo:userInfo isSilent:YES isDisplayed:NO];
}

- (void)testSendPushDeliveryEventAsQAUser {

    [self saveDummyUserDefaultsWithQaUser:YES];

    id restClientClassMock = OCMClassMock([SwrveRESTClient class]);
    OCMStub([restClientClassMock alloc]).andReturn(restClientClassMock);
    OCMStub([restClientClassMock initWithTimeoutInterval:10]).andReturn(restClientClassMock);

    id swrveUtilsClassMock = OCMClassMock([SwrveUtils class]);
    OCMStub([swrveUtilsClassMock getTimeEpoch]).andReturn(1580732959342);

    NSURL *expectedURL = [NSURL URLWithString:@"1/batch" relativeToURL:[NSURL URLWithString:@"server.url"]];
    NSError *jsonError;
    NSDictionary *expectedPushDeliveryEvent = @{
            @"seqnum": @"1",
            @"actionType": @"delivered",
            @"time": @1580732959342,
            @"campaignType": @"push",
            @"id": @123456,
            @"payload": @{
                    @"displayed": [NSNumber numberWithBool:YES],
                    @"reason": @"",
                    @"silent": [NSNumber numberWithBool:NO],
                    @"trackingData": self.trackingData,
                    @"platform": @"iOS",
            },
            @"type": @"generic_campaign_event"
    };
    
    // note that the payload in qalog events gets turned into a string
    NSDictionary *expectedPushDeliveryWrappedEvent = @{
            @"log_details": @{
                    @"client_time": @1580732959342,
                    @"parameters": @{
                            @"actionType": @"delivered",
                            @"campaignType": @"push",
                            @"id": @123456,
                    },
                    @"seqnum": @"1",
                    @"payload":[NSString stringWithFormat:@"{\"trackingData\":\"%@\",\"platform\":\"iOS\",\"reason\":\"\",\"silent\":false,\"displayed\":true}",self.trackingData],
                    @"type": @"generic_campaign_event"
            },
            @"log_source": @"sdk",
            @"log_type": @"event",
            @"time": @1580732959342,
            @"type": @"qa_log_event"
    };

    NSArray *eventData = @[expectedPushDeliveryEvent, expectedPushDeliveryWrappedEvent];
    NSData *jsonEventBatchNSData = [NSJSONSerialization dataWithJSONObject:@{
            @"app_version": appVersion,
            @"unique_device_id": deviceId,
            @"data": eventData,
            @"session_token": sessionToken,
            @"user": userId,
    }                                                              options:0 error:&jsonError];
    
    NSString *batchImpressionEvent = [[NSString alloc] initWithData:jsonEventBatchNSData encoding:NSUTF8StringEncoding];
    NSData *expectedEventBatchNSData = [batchImpressionEvent dataUsingEncoding:NSUTF8StringEncoding];

    XCTAssertNil(jsonError);
    // Expected call with expectedURL and jsonData.
    OCMExpect([restClientClassMock sendHttpPOSTRequest:expectedURL jsonData:SwrveJSONBodyMatching(expectedEventBatchNSData) completionHandler:OCMOCK_ANY]);

    NSDictionary *userInfo = @{
            @"_td": self.trackingData,
            @"_smp": @"iOS",
            @"_p": @123456,
            @"sw": @{@"media":
                    @{@"title": @"tile",
                            @"body": @"body",
                            @"url": @"https://whatever.jpg"
                    },
                    @"version": @1
            }
    };

    SwrveCampaignDelivery *campaignDelivery = [[SwrveCampaignDelivery alloc] initAppGroupId:appGroupId];
    [campaignDelivery sendPushDelivery:userInfo];

    [self resetUserDefaults];

    OCMVerifyAll(restClientClassMock);
    [restClientClassMock stopMocking];
    [swrveUtilsClassMock stopMocking];
}

#pragma mark - Carousel page view

- (NSDictionary *)carouselUserInfo {
    return @{
            @"_p": @123456,
            @"_td": self.trackingData,
            @"_smp": @"iOS",
            @"_sw": @{
                    @"carousel": @[@{@"image_url": @"https://example.com/item0.png"}],
                    @"version": @1
            }
    };
}

- (void)testCarouselPageViewEventFields {
    [self resetUserDefaults];
    id swrveUtilsClassMock = OCMClassMock([SwrveUtils class]);
    OCMStub([swrveUtilsClassMock getTimeEpoch]).andReturn(1580732959342);

    SwrveCampaignDelivery *campaignDelivery = [[SwrveCampaignDelivery alloc] initAppGroupId:appGroupId];
    NSDictionary *event = [campaignDelivery carouselPageViewEvent:[self carouselUserInfo] userId:userId itemIndex:0];

    // The first carousel item reports as slide 0 and contextId "0" — the wire matches the index
    // used everywhere inside the SDK.
    NSDictionary *expected = @{
            @"type": @"generic_campaign_event",
            @"time": @1580732959342,
            @"seqnum": @"1",
            @"actionType": @"slide_view",
            @"campaignType": @"push",
            @"contextId": @"0",
            @"id": @123456,
            @"payload": @{
                    @"carousel": @YES,
                    @"slide": @0,
                    @"trackingData": self.trackingData,
                    @"platform": @"iOS"
            }
    };
    XCTAssertEqualObjects(event, expected);

    [self resetUserDefaults];
    [swrveUtilsClassMock stopMocking];
}

- (void)testCarouselPageViewReportsTheItemsDeeplinkNotThePushs {
    [self resetUserDefaults];
    SwrveCampaignDelivery *campaignDelivery = [[SwrveCampaignDelivery alloc] initAppGroupId:appGroupId];
    NSMutableDictionary *userInfo = [[self carouselUserInfo] mutableCopy];
    [userInfo setObject:@"swrve://push-deeplink" forKey:@"_sd"];
    [userInfo setObject:@{
            @"carousel": @[
                    @{@"image_url": @"https://example.com/item0.png", @"action_type": @"open_url", @"action": @"https://example.com/item0"},
                    @{@"image_url": @"https://example.com/item1.png", @"action_type": @"open_app"}
            ],
            @"version": @1
    } forKey:@"_sw"];

    NSDictionary *urlItem = [campaignDelivery carouselPageViewEvent:userInfo userId:userId itemIndex:0];
    NSDictionary *appItem = [campaignDelivery carouselPageViewEvent:userInfo userId:userId itemIndex:1];

    XCTAssertEqualObjects([[urlItem objectForKey:@"payload"] objectForKey:@"deeplink"], @"https://example.com/item0");
    XCTAssertNil([[appItem objectForKey:@"payload"] objectForKey:@"deeplink"]);
    [self resetUserDefaults];
}

- (void)testCarouselPageViewEventIndexMatchesTheItem {
    [self resetUserDefaults];
    SwrveCampaignDelivery *campaignDelivery = [[SwrveCampaignDelivery alloc] initAppGroupId:appGroupId];

    NSDictionary *event = [campaignDelivery carouselPageViewEvent:[self carouselUserInfo] userId:userId itemIndex:2];

    XCTAssertEqualObjects([[event objectForKey:@"payload"] objectForKey:@"slide"], @2);
    XCTAssertEqualObjects([event objectForKey:@"contextId"], @"2");
    [self resetUserDefaults];
}

- (void)testCarouselPageViewIsNotResentOnceRecorded {
    [self saveDummyUserDefaultsWithQaUser:NO];
    id restClientClassMock = OCMClassMock([SwrveRESTClient class]);
    OCMStub([restClientClassMock alloc]).andReturn(restClientClassMock);
    OCMStub([restClientClassMock initWithTimeoutInterval:10]).andReturn(restClientClassMock);
    OCMReject([restClientClassMock sendHttpPOSTRequest:OCMOCK_ANY jsonData:OCMOCK_ANY completionHandler:OCMOCK_ANY]);

    NSString *requestId = [[NSUUID UUID] UUIDString];
    [SwrveSEConfig markCarouselPageViewed:appGroupId requestId:requestId itemIndex:0];

    SwrveCampaignDelivery *campaignDelivery = [[SwrveCampaignDelivery alloc] initAppGroupId:appGroupId];
    [campaignDelivery sendCarouselPageView:[self carouselUserInfo] requestId:requestId itemIndex:0];

    [self resetUserDefaults];
    OCMVerifyAll(restClientClassMock);
    [restClientClassMock stopMocking];
}

- (void)testCarouselPageViewIsRecordedOnlyAfterTheSendSucceeds {
    [self saveDummyUserDefaultsWithQaUser:NO];
    id restClientClassMock = OCMClassMock([SwrveRESTClient class]);
    OCMStub([restClientClassMock alloc]).andReturn(restClientClassMock);
    OCMStub([restClientClassMock initWithTimeoutInterval:10]).andReturn(restClientClassMock);

    // A request that never completes — the extension was torn down with it in flight.
    NSString *inFlightRequestId = [[NSUUID UUID] UUIDString];
    SwrveCampaignDelivery *campaignDelivery = [[SwrveCampaignDelivery alloc] initAppGroupId:appGroupId];
    [campaignDelivery sendCarouselPageView:[self carouselUserInfo] requestId:inFlightRequestId itemIndex:0];

    XCTAssertFalse([SwrveSEConfig hasCarouselPageBeenViewed:appGroupId requestId:inFlightRequestId itemIndex:0],
                   @"an unsent page view must not be recorded, or it is lost for good");

    // Now let the POST complete with a 200.
    __block void (^capturedHandler)(NSURLResponse *, NSData *, NSError *) = nil;
    OCMStub([restClientClassMock sendHttpPOSTRequest:OCMOCK_ANY jsonData:OCMOCK_ANY completionHandler:OCMOCK_ANY])
        .andDo(^(NSInvocation *invocation) {
            void (^handler)(NSURLResponse *, NSData *, NSError *);
            [invocation getArgument:&handler atIndex:4];
            capturedHandler = [handler copy];
        });

    NSString *sentRequestId = [[NSUUID UUID] UUIDString];
    [campaignDelivery sendCarouselPageView:[self carouselUserInfo] requestId:sentRequestId itemIndex:0];
    XCTAssertNotNil(capturedHandler);

    NSHTTPURLResponse *ok = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"server.url"]
                                                        statusCode:200
                                                       HTTPVersion:nil
                                                      headerFields:nil];
    capturedHandler(ok, nil, nil);

    XCTAssertTrue([SwrveSEConfig hasCarouselPageBeenViewed:appGroupId requestId:sentRequestId itemIndex:0],
                  @"a delivered page view should be recorded so it is not re-sent");

    [self resetUserDefaults];
    [restClientClassMock stopMocking];
}

- (void)testCarouselPageViewNotSentWhenTrackingStopped {
    [self saveDummyUserDefaultsWithQaUser:NO];
    [SwrveSEConfig saveTrackingStateStopped:appGroupId isTrackingStateStopped:YES];

    id restClientClassMock = OCMClassMock([SwrveRESTClient class]);
    OCMStub([restClientClassMock alloc]).andReturn(restClientClassMock);
    OCMStub([restClientClassMock initWithTimeoutInterval:10]).andReturn(restClientClassMock);
    OCMReject([restClientClassMock sendHttpPOSTRequest:OCMOCK_ANY jsonData:OCMOCK_ANY completionHandler:OCMOCK_ANY]);

    SwrveCampaignDelivery *campaignDelivery = [[SwrveCampaignDelivery alloc] initAppGroupId:appGroupId];
    NSString *requestId = [[NSUUID UUID] UUIDString];
    [campaignDelivery sendCarouselPageView:[self carouselUserInfo] requestId:requestId itemIndex:0];

    [SwrveSEConfig saveTrackingStateStopped:appGroupId isTrackingStateStopped:NO];

    // The item must not have been marked as viewed, or resuming tracking would find it burned.
    XCTAssertFalse([SwrveSEConfig hasCarouselPageBeenViewed:appGroupId requestId:requestId itemIndex:0]);

    [self resetUserDefaults];
    OCMVerifyAll(restClientClassMock);
    [restClientClassMock stopMocking];
}

- (void)testCarouselPageViewNotSentWithoutDeliveryConfig {
    [self resetUserDefaults];
    id restClientClassMock = OCMClassMock([SwrveRESTClient class]);
    OCMStub([restClientClassMock alloc]).andReturn(restClientClassMock);
    OCMStub([restClientClassMock initWithTimeoutInterval:10]).andReturn(restClientClassMock);
    OCMReject([restClientClassMock sendHttpPOSTRequest:OCMOCK_ANY jsonData:OCMOCK_ANY completionHandler:OCMOCK_ANY]);

    SwrveCampaignDelivery *campaignDelivery = [[SwrveCampaignDelivery alloc] initAppGroupId:appGroupId];
    [campaignDelivery sendCarouselPageView:[self carouselUserInfo] requestId:[[NSUUID UUID] UUIDString] itemIndex:0];

    OCMVerifyAll(restClientClassMock);
    [restClientClassMock stopMocking];
}

// Helper methods

- (void)saveDummyUserDefaultsWithQaUser:(BOOL)isQaUser {
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:appGroupId];
    [userDefaults setObject:@{
            SwrveDeliveryRequiredConfigUserIdKey: userId,
            SwrveDeliveryRequiredConfigEventsUrlKey: serverUrl,
            SwrveDeliveryRequiredConfigDeviceIdKey: deviceId,
            SwrveDeliveryRequiredConfigSessionTokenKey: sessionToken,
            SwrveDeliveryRequiredConfigAppVersionKey: appVersion,
            SwrveDeliveryRequiredConfigIsQAUser: [NSNumber numberWithBool:isQaUser]
    }                forKey:SwrveDeliveryConfigKey];
}

- (void)resetUserDefaults {
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:appGroupId];
    [userDefaults setObject:nil forKey:SwrveDeliveryConfigKey];
    NSString *seqNumKey = [userId stringByAppendingString:@"swrve_event_seqnum"];
    [userDefaults setObject:nil forKey:seqNumKey];
}

- (void)assertSendPushDeliveryWithUserInfo:(NSDictionary *)userInfo isSilent:(BOOL)isSilent isDisplayed:(BOOL)isDisplayed  {

    id restClientClassMock = OCMClassMock([SwrveRESTClient class]);
    OCMStub([restClientClassMock alloc]).andReturn(restClientClassMock);
    OCMStub([restClientClassMock initWithTimeoutInterval:10]).andReturn(restClientClassMock);

    id swrveUtilsClassMock = OCMClassMock([SwrveUtils class]);
    OCMStub([swrveUtilsClassMock getTimeEpoch]).andReturn(1580732959342);

    NSURL *expectedURL = [NSURL URLWithString:@"1/batch" relativeToURL:[NSURL URLWithString:@"server.url"]];
    NSError *jsonError;
    NSData *expectedEventBatchNSData = [NSJSONSerialization dataWithJSONObject:@{
            @"app_version": appVersion,
            @"unique_device_id": deviceId,
            @"data": @[
                    @{
                            @"seqnum": @"1",
                            @"actionType": @"delivered",
                            @"time": @1580732959342,
                            @"campaignType": @"push",
                            @"id": @123456,
                            @"payload": @{
                                    @"displayed": [NSNumber numberWithBool:isDisplayed],
                                    @"reason": @"",
                                    @"silent": [NSNumber numberWithBool:isSilent],
                                    @"trackingData": self.trackingData,
                                    @"platform": @"iOS"
                            },
                            @"type": @"generic_campaign_event"
                    }
            ],
            @"session_token": sessionToken,
            @"user": userId,
    }                                                                  options:0 error:&jsonError];

    XCTAssertNil(jsonError);
    OCMExpect([restClientClassMock sendHttpPOSTRequest:expectedURL jsonData:SwrveJSONBodyMatching(expectedEventBatchNSData) completionHandler:OCMOCK_ANY]);

    SwrveCampaignDelivery *campaignDelivery = [[SwrveCampaignDelivery alloc] initAppGroupId:appGroupId];
    [campaignDelivery sendPushDelivery:userInfo];

    [self resetUserDefaults];

    OCMVerifyAll(restClientClassMock);
    [restClientClassMock stopMocking];
    [swrveUtilsClassMock stopMocking];
}

@end
