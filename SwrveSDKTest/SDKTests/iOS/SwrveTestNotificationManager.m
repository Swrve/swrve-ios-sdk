#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "SwrvePush.h"
#import "SwrveNotificationManager.h"
#import "SwrveLocalStorage.h"
#import "SwrveTestHelper.h"

@interface SwrveNotificationManager ()
+ (NSURL *)cachedUrlFor:(NSURL *)externalUrl withPathExtension:(NSString *)pathExtension inCacheDir:(NSString *)cacheDir;
+ (void)downloadAttachment:(NSString *)mediaUrl withCompletedContentCallback:(void (^)(UNNotificationAttachment *attachment, NSError *error))callback __IOS_AVAILABLE(10.0) __TVOS_AVAILABLE(10.0);
+ (void)updateLastProcessedPushId:(NSString *)pushId;
@end

@interface SwrveTestNotificationManager : XCTestCase
@property (nonatomic) NSString *trackingData;
@end

@implementation SwrveTestNotificationManager


- (void)setUp {
    [super setUp];
    self.trackingData = @"5ea0fb1b8a24b8f9f76f675b7350200f314312fa";
    [SwrveTestHelper setUp];
}

- (void)tearDown {
    [SwrveNotificationManager updateLastProcessedPushId:@""];
    [SwrveTestHelper tearDown];
    [super tearDown];
}

- (void)testNotificationResponseReceived {
    id mockSwrveCommon = OCMProtocolMock(@protocol(SwrveCommonDelegate));
    [SwrveCommon addSharedInstance:mockSwrveCommon];
    
    NSDictionary *expectedEngagedPayload = @{
        @"trackingData": self.trackingData,
        @"platform": @"iOS",
    };

    NSDictionary *expectedButtonPayload = @{
        @"actionType": @"button_click",
        @"campaignType": @"iam",
        @"contextId": @"identifier",
        @"id": @"123",
        @"payload": @{
            @"buttonText": @"my button",
            @"platform": @"iOS",
            @"trackingData": self.trackingData
        }
    };

    NSDictionary *userInfo = [self userInfoForCampaignType:@"iam"];
    [SwrveNotificationManager notificationResponseReceived:@"identifier" withUserInfo:userInfo];
    
    OCMVerify([mockSwrveCommon queueEvent:@"generic_campaign_event" data:[expectedButtonPayload mutableCopy] triggerCallback:false]);
    OCMVerify([mockSwrveCommon sendPushNotificationEngagedEvent:@"123" withPayload:[expectedEngagedPayload mutableCopy]]);

}

- (void)testNotificationResponseReceivedGeo {
    id mockSwrveCommon = OCMProtocolMock(@protocol(SwrveCommonDelegate));
    [SwrveCommon addSharedInstance:mockSwrveCommon];
    
    NSDictionary *expectedEngagedPayload = @{
        @"actionType": @"engaged",
        @"campaignType": @"geo",
        @"id": @"123",
        @"payload": @{
            @"geofence_id": @"6789",
            @"geoplace_id": @"2345"
        }
    };
    
    NSDictionary *expectedButtonPayload = @{
        @"actionType": @"button_click",
        @"campaignType": @"geo",
        @"contextId": @"identifier",
        @"id": @"123",
        @"payload": @{
            @"buttonText": @"my button",
            @"geofence_id": @"6789",
            @"geoplace_id": @"2345"
        }
    };

    NSDictionary *userInfo = [self userInfoForCampaignType:@"geo"];
    [SwrveNotificationManager notificationResponseReceived:@"identifier" withUserInfo:userInfo];
    
    OCMVerify([mockSwrveCommon queueEvent:@"generic_campaign_event" data:[expectedEngagedPayload mutableCopy] triggerCallback:false]);
    OCMVerify([mockSwrveCommon queueEvent:@"generic_campaign_event" data:[expectedButtonPayload mutableCopy] triggerCallback:false]);
}

- (void)testImageLoadFromCache {
    NSString *mockCacheDir = [[NSBundle bundleForClass:[self class]] resourcePath];
    
    // Create test image files in cache
    NSURL *externalImage = [NSURL URLWithString:@"http://sample/url/testImage.jpg"];
    NSURL *cachedImage = [SwrveNotificationManager cachedUrlFor:externalImage withPathExtension:@"jpg" inCacheDir:mockCacheDir];
    [[@"FakeImageData" dataUsingEncoding:NSUTF8StringEncoding] writeToURL:cachedImage atomically:true];
    
    //SwrveNotificationManager *swrveNotificationManager = [SwrveNotificationManager new];
    id mockSwrveNotificationManager = OCMClassMock([SwrveNotificationManager class]);
    
    id localStorage = OCMClassMock([SwrveLocalStorage class]);
    OCMStub([localStorage swrveCacheFolder]).andReturn(mockCacheDir);
    
    NSDictionary *userInfo = @{@"_sw":@{
        @"media":@{
            @"url":@"http://sample/url/testImage.jpg"
        }
    }
    };
    
    UNMutableNotificationContent *testContent = [[UNMutableNotificationContent alloc] init];
    testContent.userInfo = userInfo;
    
    OCMReject([mockSwrveNotificationManager downloadAttachment:OCMOCK_ANY withCompletedContentCallback:OCMOCK_ANY]);
    
    [SwrveNotificationManager handleContent:testContent withCompletionCallback:^(UNMutableNotificationContent *content) {
        XCTAssertEqualObjects(@"public.jpeg", content.attachments[0].type);
    }];
    
    OCMVerifyAll(mockSwrveNotificationManager);
}

- (void)testPushCategories {
    NSDictionary *userInfo = @{@"_sw":@{
        @"media":@{
            @"title":@"Sample Title",
        },
        @"buttons": @[
            @{
                @"title": @"Custom button open app",
                @"action_type": @"open_app",
                @"action": @""
            }]
    },
    };
    
    UNMutableNotificationContent *testContent = [[UNMutableNotificationContent alloc] init];
    testContent.userInfo = userInfo;
    
    XCTestExpectation *handleContent = [self expectationWithDescription:@"handleContent"];
    [SwrveNotificationManager handleContent:testContent withCompletionCallback:^(UNMutableNotificationContent *content) {
        [handleContent fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
    
    XCTestExpectation *checkContent = [self expectationWithDescription:@"checkContent"];
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center getNotificationCategoriesWithCompletionHandler:^(NSSet<UNNotificationCategory *> *_Nonnull categories) {
        
        UNNotificationCategory *cat =  [[categories allObjects] firstObject];
        UNNotificationAction *action = [[cat actions] firstObject];
        XCTAssertEqualObjects(@"Custom button open app", action.title);
        
        [checkContent fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
    
    [center setNotificationCategories:[NSSet new]];
}

- (NSDictionary *)userInfoForCampaignType:(NSString *)campaignType {
    NSDictionary *standardInfo = @{
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
        @"campaign_type": campaignType,
    };
    
    NSMutableDictionary *allInfo = [standardInfo mutableCopy];
    if ([campaignType isEqualToString:@"geo"]) {
        NSDictionary *event_payload = @{
            @"geoplace_id": @"2345",
            @"geofence_id": @"6789"
        };
        [allInfo setObject:event_payload forKey:@"event_payload" ];
    } else if ([campaignType isEqualToString:@"iam"]) {
        [allInfo setObject:@"iOS" forKey:@"_smp"];
        [allInfo setObject:self.trackingData forKey:@"_td"];
    }
    return allInfo;
}

-(NSDictionary *)addtionalPayload:(NSString *)campaignType actionType:(NSString *)actionType{
    NSMutableDictionary *addtionalPayload = [[NSMutableDictionary alloc] init];
    if ([campaignType isEqualToString:@"geo"]) {
        [addtionalPayload setObject:@"2345" forKey:@"geoplace_id"];
        [addtionalPayload setObject:@"6789" forKey:@"geofence_id"];
    } else if ([campaignType isEqualToString:@"iam"]) {
        [addtionalPayload setObject:self.trackingData forKey:@"trackingData"];
        [addtionalPayload setObject:@"iOS" forKey:@"platform"];
    }

    if ([actionType isEqualToString:@"button_click"]) {
        [addtionalPayload setObject:@"my button" forKey:@"buttonText"];
    }
    return addtionalPayload;
}

- (NSDictionary *)engagedData:(NSString *)campaignType {
    return @{
        @"id": @"123",
        @"campaignType": campaignType,
        @"actionType": @"engaged",
        @"payload" : [self addtionalPayload:campaignType actionType:@"engaged"]
    };
}

- (NSDictionary *)buttonClickData:(NSString *)campaignType {
    return  @{
        @"id": @"123",
        @"campaignType": campaignType,
        @"actionType": @"button_click",
        @"contextId": @"identifier",
        @"payload": [self addtionalPayload:campaignType actionType:@"button_click"]
    };
}

@end
