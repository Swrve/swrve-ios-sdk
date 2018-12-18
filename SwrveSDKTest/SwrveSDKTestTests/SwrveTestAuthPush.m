#import <XCTest/XCTest.h>
#import "SwrveSDK.h"
#import "SwrveNotificationManager.h"
#import <OCMock/OCMock.h>

@interface SwrveNotificationManager()
+ (void)downloadAttachment:(NSString *)mediaUrl withCompletedContentCallback:(void (^)(UNNotificationAttachment *attachment, NSError *error))callback;
@end

@interface SwrvePush()
+ (SwrvePush *)sharedInstance;
- (void)handleAuthenticatedPushNotification:(NSDictionary *)userInfo;
@end

@interface SwrveTestAuthPush : XCTestCase

@end

@implementation SwrveTestAuthPush

   static id currentMockCenter;

- (void)testAuthPushMediaDownloadSucceeds {
    IMP originalCurrentCenterImp = [self replaceCurrentNotificationCenter];
    currentMockCenter = OCMClassMock([UNUserNotificationCenter class]);
    
    id mediaHelperMock = OCMClassMock([SwrveNotificationManager class]);
    OCMStub([mediaHelperMock downloadAttachment:OCMOCK_ANY withCompletedContentCallback:OCMOCK_ANY]).andDo(^(NSInvocation *invoke) {
   
        void (^withCompletedContentCallback)(UNNotificationAttachment *attachment, NSError *error);
        
        NSURL *attachmentURL = [[NSBundle mainBundle] URLForResource:@"logo" withExtension:@"gif"];
        UNNotificationAttachment *attachment = [UNNotificationAttachment attachmentWithIdentifier:@"" URL:attachmentURL options:nil error:nil];
        
        NSError *mockedError = nil;
        [invoke getArgument:&withCompletedContentCallback atIndex:3];
        withCompletedContentCallback(attachment, mockedError);
    });
    
    id swrvePushMock = [OCMockObject partialMockForObject:[SwrvePush sharedInstance]];
    
    [SwrveLocalStorage saveSwrveUserId:@"1234"];
    
    NSDictionary *userInfo = @{
                               @"_p":@"1",
                               @"_aui": @"1234",
                               @"_sw":@{
                                       @"media": @{
                                               @"title": @"rich_title",
                                               @"body":  @"rich_body",
                                               @"subtitle": @"rich_subtitle",
                                               @"url": @"media download will succeed"
                                               }
                                       },
                               @"version": @1
                               };
    
    XCTestExpectation *addNotificationRequest = [self expectationWithDescription:@"addNotificationRequest"];

    void (^addNotificationRequestObserver)(NSInvocation *) = ^(NSInvocation *invoke) {
        __unsafe_unretained UNNotificationRequest * request = nil;
        [invoke getArgument:&request atIndex:2];

        XCTAssertEqualObjects(request.content.userInfo[@"_sw"][@"media"][@"title"],@"rich_title");
        [addNotificationRequest fulfill];
    };;
    
    OCMStub([currentMockCenter addNotificationRequest:OCMOCK_ANY withCompletionHandler:OCMOCK_ANY]).andDo(addNotificationRequestObserver);

    [swrvePushMock handleAuthenticatedPushNotification:userInfo];
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"addNotificationRequest not called");
        }
    }];
    
    OCMVerify([currentMockCenter addNotificationRequest:OCMOCK_ANY withCompletionHandler:OCMOCK_ANY]);
    OCMVerifyAll(currentMockCenter);
    
    // Test cleanup
    [self restoreCurrentNotificationCenter:originalCurrentCenterImp];
    [currentMockCenter stopMocking];
    [mediaHelperMock stopMocking];
    [swrvePushMock stopMocking];
}

// Auth push does not suppport fallback text for media, when media download fails, the auth push won't show
- (void)testAuthPushMediaDownloadFails {
    IMP originalCurrentCenterImp = [self replaceCurrentNotificationCenter];
    currentMockCenter = OCMClassMock([UNUserNotificationCenter class]);
    
    XCTestExpectation *mediaFailedDownload = [self expectationWithDescription:@"mediaFailedDownload"];
    
    id mediaHelperMock = [OCMockObject mockForClass:[SwrveNotificationManager class]];
    [[[mediaHelperMock expect] andDo:^(NSInvocation *invoke) {
        
        void (^withCompletedContentCallback)(UNNotificationAttachment *attachment, NSError *error);
        //deliberately return no attachement indicating a failure.
        UNNotificationAttachment *attachment = nil;
        NSError *mockedError = nil;
        [invoke getArgument:&withCompletedContentCallback atIndex:3];
        withCompletedContentCallback(attachment, mockedError);
        [mediaFailedDownload fulfill];
        
    }] downloadAttachment:OCMOCK_ANY withCompletedContentCallback:OCMOCK_ANY];
    
    id swrvePushMock = [OCMockObject partialMockForObject:[SwrvePush sharedInstance]];
    
    [SwrveLocalStorage saveSwrveUserId:@"1234"];
    
    NSDictionary *userInfo = @{
                               @"_p":@"1",
                               @"_aui": @"1234",
                               @"_sw":@{
                                       @"media": @{
                                               @"title": @"rich_title",
                                               @"body":  @"rich_body",
                                               @"subtitle": @"rich_subtitle",
                                               @"url": @"media download will fail"
                                               }
                                       },
                               @"version": @1
                               };
    
    [swrvePushMock handleAuthenticatedPushNotification:userInfo];
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"addNotificationRequest not called");
        }
    }];
    
    OCMReject([currentMockCenter addNotificationRequest:OCMOCK_ANY withCompletionHandler:OCMOCK_ANY]);
    OCMVerifyAll(currentMockCenter);
    
    // Test cleanup
    [self restoreCurrentNotificationCenter:originalCurrentCenterImp];
    [currentMockCenter stopMocking];
    [mediaHelperMock stopMocking];
    [swrvePushMock stopMocking];
}

 //Replace the [UNUserNotificationCenter currentNotificationCenter] method to return a mock using a method in this class and return the
 //original method implementation to be able to restore it at the end of the test
- (IMP) replaceCurrentNotificationCenter {
    Class notificationCenterClass = [UNUserNotificationCenter class];
    SEL currentCenterSelector = @selector(currentNotificationCenter);
    Method originalMethod = class_getClassMethod(notificationCenterClass, currentCenterSelector);
    IMP newImplementation = [[self class] methodForSelector:currentCenterSelector];
    return method_setImplementation(originalMethod, newImplementation);
}
- (void) restoreCurrentNotificationCenter:(IMP)originalCurrentCenterImp {
    Class notificationCenterClass = [UNUserNotificationCenter class];
    SEL currentCenterSelector = @selector(currentNotificationCenter);
    Method originalMethod = class_getClassMethod(notificationCenterClass, currentCenterSelector);
    method_setImplementation(originalMethod, originalCurrentCenterImp);
}

// This test temporarily replaces [UNUserNotificationCenter currentNotificationCenter] with this implementation to return a controllable mock
+ (UNUserNotificationCenter *)currentNotificationCenter {
    return currentMockCenter;
}

@end
