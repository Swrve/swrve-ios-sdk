#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SwrveSEConfig.h"

#import "SwrvePush.h"
#import "SwrveNotificationManager.h"
#import "SwrveLocalStorage.h"
#import "SwrveTestHelper.h"

@interface SwrveNotificationManager ()
+ (NSURL *)cachedUrlFor:(NSURL *)externalUrl withPathExtension:(NSString *)pathExtension inCacheDir:(NSString *)cacheDir;
+ (void)downloadAttachment:(NSString *)mediaUrl withCompletedContentCallback:(void (^)(UNNotificationAttachment *attachment, NSError *error))callback;
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
    [SwrveNotificationManager notificationResponseReceived:@"identifier" withUserInfo:userInfo notificationRequestId:@"someId"];
    
    OCMVerify([mockSwrveCommon queueEvent:@"generic_campaign_event" data:[expectedButtonPayload mutableCopy] triggerCallback:false]);
    OCMVerify([mockSwrveCommon sendPushNotificationEngagedEvent:@"123" withPayload:[expectedEngagedPayload mutableCopy]]);

}

- (void)testCarouselItemTapReportsSlideIndexAndItemDeeplink {
    id mockSwrveCommon = OCMProtocolMock(@protocol(SwrveCommonDelegate));
    OCMStub([mockSwrveCommon appGroupIdentifier]).andReturn(@"app.groupid");
    [SwrveCommon addSharedInstance:mockSwrveCommon];

    id fileManagerMock = OCMPartialMock([NSFileManager defaultManager]);
    OCMStub([fileManagerMock containerURLForSecurityApplicationGroupIdentifier:OCMOCK_ANY]).andReturn([NSURL new]);

    // The index the content extension recorded is reported as-is, and the item's own action
    // replaces the notification's deeplink.
    [SwrveSEConfig saveCarouselItemTap:@"app.groupid"
                             requestId:@"someId"
                             itemIndex:1
                                action:@"https://www.example.com/"];

    NSDictionary *expectedEngagedPayload = @{
        @"trackingData": self.trackingData,
        @"platform": @"iOS",
        @"deeplink": @"https://www.example.com/",
        @"carousel": @YES,
        @"slide": @1
    };

    NSMutableDictionary *userInfo = [[self userInfoForCampaignType:@"iam"] mutableCopy];
    NSMutableDictionary *sw = [[userInfo objectForKey:@"_sw"] mutableCopy];
    [sw setObject:@[@{@"image_url": @"https://example.com/item0.png"},
                    @{@"image_url": @"https://example.com/item1.png"}] forKey:@"carousel"];
    [userInfo setObject:sw forKey:@"_sw"];

    [SwrveNotificationManager notificationResponseReceived:SwrveNotificationResponseDefaultActionKey
                                              withUserInfo:userInfo
                                     notificationRequestId:@"someId"];

    OCMVerify([mockSwrveCommon sendPushNotificationEngagedEvent:@"123" withPayload:[expectedEngagedPayload mutableCopy]]);
    [fileManagerMock stopMocking];
}

- (void)testCarouselItemTapSendsSlideClick {
    id mockSwrveCommon = OCMProtocolMock(@protocol(SwrveCommonDelegate));
    OCMStub([mockSwrveCommon appGroupIdentifier]).andReturn(@"app.groupid");
    [SwrveCommon addSharedInstance:mockSwrveCommon];

    id fileManagerMock = OCMPartialMock([NSFileManager defaultManager]);
    OCMStub([fileManagerMock containerURLForSecurityApplicationGroupIdentifier:OCMOCK_ANY]).andReturn([NSURL new]);

    [SwrveSEConfig saveCarouselItemTap:@"app.groupid"
                             requestId:@"someId"
                             itemIndex:1
                                action:@"https://www.example.com/"];

    NSDictionary *expectedSlideClick = @{
        @"id": @"123",
        @"campaignType": @"push",
        @"actionType": @"slide_click",
        @"contextId": @"1",
        @"payload": @{
            @"carousel": @YES,
            @"slide": @1,
            @"trackingData": self.trackingData,
            @"platform": @"iOS",
            @"deeplink": @"https://www.example.com/"
        }
    };

    [SwrveNotificationManager notificationResponseReceived:SwrveNotificationResponseDefaultActionKey
                                              withUserInfo:[self carouselUserInfo]
                                     notificationRequestId:@"someId"];

    OCMVerify(times(1), [mockSwrveCommon queueEvent:@"generic_campaign_event" data:[expectedSlideClick mutableCopy] triggerCallback:false]);
    OCMVerify([mockSwrveCommon sendQueuedEvents]);
    OCMVerify(times(1), [mockSwrveCommon sendPushNotificationEngagedEvent:@"123" withPayload:OCMOCK_ANY]);
    [fileManagerMock stopMocking];
}

- (void)testOpenAppCarouselItemTapSendsSlideClick {
    id mockSwrveCommon = OCMProtocolMock(@protocol(SwrveCommonDelegate));
    OCMStub([mockSwrveCommon appGroupIdentifier]).andReturn(@"app.groupid");
    [SwrveCommon addSharedInstance:mockSwrveCommon];

    id fileManagerMock = OCMPartialMock([NSFileManager defaultManager]);
    OCMStub([fileManagerMock containerURLForSecurityApplicationGroupIdentifier:OCMOCK_ANY]).andReturn([NSURL new]);

    // An open_app item has no action, so the index is all its tap record carries, and the push's
    // deeplink isn't reported in its place
    [SwrveSEConfig saveCarouselItemTap:@"app.groupid" requestId:@"someId" itemIndex:0 action:nil];

    NSDictionary *expectedSlideClick = @{
        @"id": @"123",
        @"campaignType": @"push",
        @"actionType": @"slide_click",
        @"contextId": @"0",
        @"payload": @{
            @"carousel": @YES,
            @"slide": @0,
            @"trackingData": self.trackingData,
            @"platform": @"iOS"
        }
    };

    [SwrveNotificationManager notificationResponseReceived:SwrveNotificationResponseDefaultActionKey
                                              withUserInfo:[self carouselUserInfo]
                                     notificationRequestId:@"someId"];

    OCMVerify(times(1), [mockSwrveCommon queueEvent:@"generic_campaign_event" data:[expectedSlideClick mutableCopy] triggerCallback:false]);
    [fileManagerMock stopMocking];
}

- (void)testBodyTapOnCarouselPushStillReportsCarousel {
    id mockSwrveCommon = OCMProtocolMock(@protocol(SwrveCommonDelegate));
    [SwrveCommon addSharedInstance:mockSwrveCommon];

    // No carousel item was tapped — the user pressed the notification body. That is still an
    // engagement with a carousel push, so `carousel` must be reported. `slide` must not be, since
    // no particular item was engaged with.
    NSDictionary *expectedEngagedPayload = @{
        @"trackingData": self.trackingData,
        @"platform": @"iOS",
        @"carousel": @YES
    };

    NSMutableDictionary *userInfo = [[self userInfoForCampaignType:@"iam"] mutableCopy];
    NSMutableDictionary *sw = [[userInfo objectForKey:@"_sw"] mutableCopy];
    [sw setObject:@[@{@"image_url": @"https://example.com/item0.png"}] forKey:@"carousel"];
    [userInfo setObject:sw forKey:@"_sw"];

    [SwrveNotificationManager notificationResponseReceived:SwrveNotificationResponseDefaultActionKey
                                              withUserInfo:userInfo
                                     notificationRequestId:@"someId"];

    OCMVerify([mockSwrveCommon sendPushNotificationEngagedEvent:@"123" withPayload:[expectedEngagedPayload mutableCopy]]);
    OCMVerify(never(), [mockSwrveCommon queueEvent:@"generic_campaign_event" data:OCMOCK_ANY triggerCallback:false]);
}

- (void)testBodyTapOnNonCarouselPushDoesNotReportCarousel {
    id mockSwrveCommon = OCMProtocolMock(@protocol(SwrveCommonDelegate));
    [SwrveCommon addSharedInstance:mockSwrveCommon];

    NSDictionary *expectedEngagedPayload = @{
        @"trackingData": self.trackingData,
        @"platform": @"iOS"
    };

    NSMutableDictionary *userInfo = [[self userInfoForCampaignType:@"iam"] mutableCopy];

    [SwrveNotificationManager notificationResponseReceived:SwrveNotificationResponseDefaultActionKey
                                              withUserInfo:userInfo
                                     notificationRequestId:@"someId"];

    OCMVerify([mockSwrveCommon sendPushNotificationEngagedEvent:@"123" withPayload:[expectedEngagedPayload mutableCopy]]);
    OCMVerify(never(), [mockSwrveCommon queueEvent:@"generic_campaign_event" data:OCMOCK_ANY triggerCallback:false]);
}

- (void)testNotificationResponseReceivedWithInvalidDeeplinkStillSendsDeeplinkPayload {
    id mockApplication = OCMPartialMock([UIApplication sharedApplication]);
    OCMStub([mockApplication canOpenURL:OCMOCK_ANY]).andReturn(NO);

    id mockSwrveCommon = OCMProtocolMock(@protocol(SwrveCommonDelegate));
    [SwrveCommon addSharedInstance:mockSwrveCommon];

    NSDictionary *expectedEngagedPayload = @{
        @"trackingData": self.trackingData,
        @"platform": @"iOS",
        @"deeplink": @":/somelink/"
    };

    NSMutableDictionary *userInfo = [[self userInfoForCampaignType:@"iam"] mutableCopy];
    [userInfo setObject:@":/somelink/" forKey:SwrveNotificationDeeplinkKey];
    NSURL *deeplink = [SwrveNotificationManager notificationResponseReceived:SwrveNotificationResponseDefaultActionKey withUserInfo:userInfo notificationRequestId:@"someId"];

    XCTAssertNil(deeplink);
    OCMVerify([mockSwrveCommon sendPushNotificationEngagedEvent:@"123" withPayload:[expectedEngagedPayload mutableCopy]]);
    [mockApplication stopMocking];
}

- (void)testNotificationResponseReceivedWithUnopenableDeeplinkStillSendsDeeplinkPayload {
    id mockApplication = OCMPartialMock([UIApplication sharedApplication]);
    OCMStub([mockApplication canOpenURL:OCMOCK_ANY]).andReturn(NO);

    id mockSwrveCommon = OCMProtocolMock(@protocol(SwrveCommonDelegate));
    [SwrveCommon addSharedInstance:mockSwrveCommon];

    NSDictionary *expectedEngagedPayload = @{
        @"trackingData": self.trackingData,
        @"platform": @"iOS",
        @"deeplink": @"oldprotocol://custom"
    };

    NSMutableDictionary *userInfo = [[self userInfoForCampaignType:@"iam"] mutableCopy];
    [userInfo setObject:@"oldprotocol://custom" forKey:SwrveNotificationDeeplinkKey];
    NSURL *deeplink = [SwrveNotificationManager notificationResponseReceived:SwrveNotificationResponseDefaultActionKey withUserInfo:userInfo notificationRequestId:@"someId"];

    XCTAssertNil(deeplink);
    OCMVerify([mockSwrveCommon sendPushNotificationEngagedEvent:@"123" withPayload:[expectedEngagedPayload mutableCopy]]);
    [mockApplication stopMocking];
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
    [SwrveNotificationManager notificationResponseReceived:@"identifier" withUserInfo:userInfo notificationRequestId:@"someId"];
    
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

- (UNMutableNotificationContent *)carouselContentWithCategory:(NSString *)category {
    UNMutableNotificationContent *testContent = [[UNMutableNotificationContent alloc] init];
    testContent.userInfo = @{@"_sw": @{
        @"carousel": @[
            @{@"image_url": @"https://sample/url/item0.png"}
        ]
    }};
    if (category != nil) {
        testContent.categoryIdentifier = category;
    }
    return testContent;
}

- (NSString *)categoryAfterHandleContent:(UNMutableNotificationContent *)testContent {
    __block NSString *result = nil;
    XCTestExpectation *handleContent = [self expectationWithDescription:@"handleContent"];
    [SwrveNotificationManager handleContent:testContent withCompletionCallback:^(UNMutableNotificationContent *content) {
        result = content.categoryIdentifier;
        [handleContent fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
    return result;
}

- (void)testCarouselCategoryAddedWhenNoneSet {
    NSString *category = [self categoryAfterHandleContent:[self carouselContentWithCategory:nil]];
    XCTAssertEqualObjects(@"swrve.carousel", category);
}

- (void)testCarouselCategoryAddedWithAppGroup {
    UNMutableNotificationContent *testContent = [self carouselContentWithCategory:nil];

    __block UNMutableNotificationContent *result = nil;
    XCTestExpectation *handleContent = [self expectationWithDescription:@"handleContent"];
    [SwrveNotificationManager handleContent:testContent withAppGroupIdentifier:@"group.com.swrve.carouseltests" withCompletionCallback:^(UNMutableNotificationContent *content) {
        result = content;
        [handleContent fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:nil];

    XCTAssertEqualObjects(@"swrve.carousel", result.categoryIdentifier);
}

- (void)testCarouselCategoryDoesNotOverwriteExistingCategory {
    NSString *category = [self categoryAfterHandleContent:[self carouselContentWithCategory:@"customerCategory"]];
    XCTAssertEqualObjects(@"customerCategory", category);
}

- (void)testCarouselCategoryNotAddedWithoutCarousel {
    UNMutableNotificationContent *testContent = [[UNMutableNotificationContent alloc] init];
    testContent.userInfo = @{@"_sw": @{@"media": @{@"title": @"Sample Title"}}};

    NSString *category = [self categoryAfterHandleContent:testContent];
    XCTAssertEqualObjects(@"", category);
}

- (void)testGeneratedButtonCategoryWinsOverCarouselCategory {
    UNMutableNotificationContent *testContent = [[UNMutableNotificationContent alloc] init];
    testContent.userInfo = @{@"_sw": @{
        @"carousel": @[
            @{@"image_url": @"https://sample/url/item0.png"}
        ],
        @"buttons": @[
            @{@"title": @"Custom button open app", @"action_type": @"open_app", @"action": @""}
        ]
    }};

    NSString *category = [self categoryAfterHandleContent:testContent];
    XCTAssertNotEqualObjects(@"swrve.carousel", category);
    XCTAssertTrue([category hasPrefix:@"swrve-"], @"expected a generated category, got %@", category);

    [[UNUserNotificationCenter currentNotificationCenter] setNotificationCategories:[NSSet new]];
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

/// Has a push deeplink of its own, so tests can check an item's event never reports it.
- (NSDictionary *)carouselUserInfo {
    NSMutableDictionary *userInfo = [[self userInfoForCampaignType:@"iam"] mutableCopy];
    [userInfo setObject:@"swrve://push-deeplink" forKey:@"_sd"];
    NSMutableDictionary *sw = [[userInfo objectForKey:@"_sw"] mutableCopy];
    [sw setObject:@[@{@"image_url": @"https://example.com/item0.png"},
                    @{@"image_url": @"https://example.com/item1.png"}] forKey:@"carousel"];
    [userInfo setObject:sw forKey:@"_sw"];
    return userInfo;
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
