#import <XCTest/XCTest.h>
#import "SwrveCampaignDelivery.h"
#import <OCMock/OCMock.h>
#import <SwrveSEConfig.h>
#import "SwrveUtils.h"
#import "SwrveRESTClient.h"

@interface SwrveTestSwrveCampaignDeliveryIOS : XCTestCase

@property id classNSFileManagerMock;

@end

@interface SwrveCampaignDelivery (Private)

- (NSDictionary *)pushDeliveryEvent:(NSDictionary *)userInfo userId:(NSString *)userId;

@end

@implementation SwrveTestSwrveCampaignDeliveryIOS

NSString *userId = @"userId";
NSString *serverUrl = @"server.url";
NSString *deviceId = @"deviceId";
NSString *sessionToken = @"sessionToken";
NSString *appVersion = @"appVersion";
NSString *appGroupId = @"app.groupid";

- (void)setUp {
    [super setUp];
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
                    @{      @"displayed": [NSNumber numberWithInt:isDisplayed],
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
                    @"silent": [NSNumber numberWithBool:NO]
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
                    @"payload": @"{\"silent\":false,\"displayed\":true,\"reason\":\"\"}",
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
    OCMExpect([restClientClassMock sendHttpPOSTRequest:expectedURL jsonData:expectedEventBatchNSData completionHandler:OCMOCK_ANY]);

    NSDictionary *userInfo = @{
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
                                    @"silent": [NSNumber numberWithBool:isSilent]
                            },
                            @"type": @"generic_campaign_event"
                    }
            ],
            @"session_token": sessionToken,
            @"user": userId,
    }                                                                  options:0 error:&jsonError];

    XCTAssertNil(jsonError);
    OCMExpect([restClientClassMock sendHttpPOSTRequest:expectedURL jsonData:expectedEventBatchNSData completionHandler:OCMOCK_ANY]);

    SwrveCampaignDelivery *campaignDelivery = [[SwrveCampaignDelivery alloc] initAppGroupId:appGroupId];
    [campaignDelivery sendPushDelivery:userInfo];

    [self resetUserDefaults];

    OCMVerifyAll(restClientClassMock);
    [restClientClassMock stopMocking];
    [swrveUtilsClassMock stopMocking];
}

@end
