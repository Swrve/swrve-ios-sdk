#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "SwrvePush.h"
#import "SwrveNotificationManager.h"
#import "SwrveLocalStorage.h"

@interface SwrveNotificationManager ()
+ (NSURL *)cachedUrlFor:(NSURL *)externalUrl withPathExtension:(NSString *)pathExtension inCacheDir:(NSString *)cacheDir;
+ (void)downloadAttachment:(NSString *)mediaUrl withCompletedContentCallback:(void (^)(UNNotificationAttachment *attachment, NSError *error))callback __IOS_AVAILABLE(10.0) __TVOS_AVAILABLE(10.0);
@end

@interface SwrveTestNotificationManager : XCTestCase

@end

@implementation SwrveTestNotificationManager

- (void)testNotificationResponseReceivedWithCampaignType {

    id mockSwrveCommon = OCMProtocolMock(@protocol(SwrveCommonDelegate));
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
    OCMExpect([mockSwrveCommon queueEvent:@"generic_campaign_event" data:[engagedExpectedData mutableCopy] triggerCallback:false]);

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
    OCMExpect([mockSwrveCommon queueEvent:@"generic_campaign_event" data:[buttonClickExpectedData mutableCopy] triggerCallback:false]);

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

@end
