#ifndef SWRVE_NO_PUSH

#import <XCTest/XCTest.h>
#import <OCMock/OCMockObject.h>
#import <OCMock/OCMock.h>

#import "SwrvePush.h"
#import "SwrveNotificationManager.h"

@interface SwrveTestNotificationManager : XCTestCase

@end

@implementation SwrveTestNotificationManager

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testNotificationResponseReceivedWithCampaignType {

    id mockSwrveCommon = [OCMockObject niceMockForProtocol:@protocol(SwrveCommonDelegate)];
    [SwrveCommon addSharedInstance:mockSwrveCommon];

    NSDictionary *engagedExpectedData = @{
            @"id": @"123",
            @"campaignType": @"geo",
            @"actionType": @"engaged",
            @"payload": @{
                    @"geoplace_id": @"2345",
                    @"geofence_id": @"6789"
            }
    };
    OCMExpect([mockSwrveCommon queueEvent:@"generic_campaign_event" data:engagedExpectedData triggerCallback:false]);

    NSDictionary *buttonClickExpectedData = @{
            @"id": @"123",
            @"campaignType": @"geo",
            @"actionType": @"button_click",
            @"contextId": @"identifier",
            @"payload": @{
                    @"geoplace_id": @"2345",
                    @"geofence_id": @"6789",
                    @"buttonText": @"my button"
            }
    };
    OCMExpect([mockSwrveCommon queueEvent:@"generic_campaign_event" data:buttonClickExpectedData triggerCallback:false]);

    NSDictionary *userInfo = @{
            @"_p": @"123",
            @"_siw": @"100",
            @"_sw": @{
                    @"subtitle": @"my subtitle",
                    @"title": @"my title",
                    @"media": @{
                            @"title": @"my title",
                            @"body": @"my body",
                            @"subtitle": @"my subtitle"
                    },
                    @"buttons": @[@{
                            @"title": @"my button",
                            @"action_type": @"open_campaign",
                            @"action": @"298233"
                    }],
                    @"version": @1
            },
            @"campaign_type": @"geo",
            @"event_payload": @{
                    @"geoplace_id": @"2345",
                    @"geofence_id": @"6789"
            }
    };
    [SwrveNotificationManager notificationResponseReceived:@"identifier" withUserInfo:userInfo];

    OCMVerifyAll(mockSwrveCommon);
}

@end

#endif // SWRVE_NO_PUSH
