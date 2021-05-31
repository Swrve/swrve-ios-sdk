#import <XCTest/XCTest.h>
#import "TestableSwrve.h"
#import "SwrveTestHelper.h"
#import "SwrveNotificationConstants.h"
#import "SwrveNotificationManager.h"
#import "SwrveNotificationOptions.h"
#import "SwrveUser.h"

#import <OCMock/OCMock.h>
#import <UserNotifications/UserNotifications.h>

/**
 This group of tests will not run on anything under iOS 10 since it's for UNUserNotification support.
 **/

@interface SwrveUser ()
+ (NSString *)md5FromSource:(NSString *)source;
@end

@interface SwrveNotificationManager (InternalAccess)
+ (UNMutableNotificationContent *)mediaTextFromProvidedContent:(UNMutableNotificationContent *)content;
+ (void)downloadAttachment:(NSString *)mediaUrl withCompletedContentCallback:(void (^)(UNNotificationAttachment *attachment, NSError *error))callback;
+ (NSURL *)cachedUrlFor:(NSURL *)externalUrl withPathExtension:(NSString *)pathExtension inCacheDir:(NSString *)cacheDir;
+ (UNNotificationAttachment *)attachmentFromCache:(NSString *)externalUrlString inCacheDir:(NSString *)cacheDir;
+ (UNNotificationCategory *)buttonsFromUserInfo:(NSDictionary *)userInfo;
+ (UNNotificationCategory *)categoryFromUserInfo:(NSDictionary *)userInfo;
+ (void)updateLastProcessedPushId:(NSString *)pushId;
@end

@interface SwrveTestRichPushHelpers : XCTestCase

@end

@implementation SwrveTestRichPushHelpers

- (void)setUp {
    [super setUp];
    [SwrveTestHelper setUp];
}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [SwrveNotificationManager updateLastProcessedPushId:@""];
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSArray *fileArray = [fileMgr contentsOfDirectoryAtPath:[[NSBundle bundleForClass:[self class]] resourcePath] error:nil];
    for (NSString *filename in fileArray) {
        [fileMgr removeItemAtPath:[[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:filename] error:NULL];
    }

    [super tearDown];
}


- (void) testNotificationConstants {
    
    // internal keys
    XCTAssertEqualObjects(SwrveNotificationDeprecatedDeeplinkKey, @"_d");
    XCTAssertEqualObjects(SwrveNotificationDeeplinkKey, @"_sd");
    XCTAssertEqualObjects(SwrveNotificationIdentifierKey, @"_p");
    
    // notification keys
    XCTAssertEqualObjects(SwrveNotificationContentIdentifierKey, @"_sw");
    XCTAssertEqualObjects(SwrveNotificationContentVersionKey, @"version");
    XCTAssertEqual(SwrveNotificationContentVersion, 1);
    XCTAssertEqualObjects(SwrveNotificationCampaignTypeKey,@"campaign_type");
    XCTAssertEqualObjects(SwrveNotificationCampaignTypeGeo, @"geo");
    XCTAssertEqualObjects(SwrveNotificationCampaignTypePush, @"push");
    XCTAssertEqualObjects(SwrveNotificationEventPayload, @"event_payload");
    XCTAssertEqualObjects(SwrveNotificationAuthenticatedUserKey, @"_aui");
    XCTAssertEqualObjects(SwrveNotificationMediaDownloadFailed, @"media_failed");
    
    // campaign key
    XCTAssertEqualObjects(SwrveCampaignKey, @"campaign");
    
    // rich media keys
    XCTAssertEqualObjects(SwrveNotificationMediaKey, @"media");
    XCTAssertEqualObjects(SwrveNotificationTitleKey, @"title");
    XCTAssertEqualObjects(SwrveNotificationSubtitleKey, @"subtitle");
    XCTAssertEqualObjects(SwrveNotificationBodyKey, @"body");
    XCTAssertEqualObjects(SwrveNotificationUrlKey, @"url");
    XCTAssertEqualObjects(SwrveNotificationFallbackUrlKey, @"fallback_url");
    XCTAssertEqualObjects(SwrveNotificationFallbackDeeplinkKey, @"fallback_sd");
    
    // category button keys
    XCTAssertEqualObjects(SwrveNotificationButtonListKey, @"buttons");
    XCTAssertEqualObjects(SwrveNotificationButtonTitleKey, @"title");
    XCTAssertEqualObjects(SwrveNotificationButtonActionTypeKey, @"action_type");
    XCTAssertEqualObjects(SwrveNotificationButtonActionKey, @"action");
    XCTAssertEqualObjects(SwrveNotificationButtonTypeKey, @"button_type");
    XCTAssertEqualObjects(SwrveNotificationCustomButtonUrlIdentiferKey, @"open_url");
    XCTAssertEqualObjects(SwrveNotificationCategoryOptionsKey, @"category_options");
    XCTAssertEqualObjects(SwrveNotificaitonCustomButtonCampaignIdentiferKey, @"open_campaign");
    
    // category option / action keys
    XCTAssertEqualObjects(SwrveNotificationCategoryTypeOptionsCarPlayKey, @"carplay");
    XCTAssertEqualObjects(SwrveNotificationCategoryTypeOptionsCustomDismissKey, @"custom_dismiss");
    XCTAssertEqualObjects(SwrveNotificationCategoryTypeOptionsHiddenShowTitleKey, @"hidden_show_title");
    XCTAssertEqualObjects(SwrveNotificationCategoryTypeOptionsHiddenShowSubtitleKey, @"hidden_show_subtitle");
    XCTAssertEqualObjects(SwrveNotificationActionTypeForegroundKey, @"foreground");
    XCTAssertEqualObjects(SwrveNotificationActionTypeDestructiveKey, @"destructive");
    XCTAssertEqualObjects(SwrveNotificationActionTypeAuthorisationKey, @"auth-required");
    XCTAssertEqualObjects(SwrveNotificationHiddenPreviewTextPlaceholderKey, @"hidden_placeholder");
    XCTAssertEqualObjects(SwrveNotificationResponseDefaultActionKey, @"com.apple.UNNotificationDefaultActionIdentifier");
}

- (void)testMediaTextFromProvidedContent {
    NSDictionary* mediaLayer = @{@"title":@"rich_title", @"subtitle":@"rich_subtitle", @"body":@"rich_body", @"url":@"https://secure-and-right-url/test-image.png"};
    NSDictionary* sw = @{@"media":mediaLayer};
    NSDictionary* userInfo = @{@"_sw":sw};
    UNNotificationContent *content = [self createTestNotificationContentWithUserInfo:userInfo];
    UNMutableNotificationContent *result = [SwrveNotificationManager mediaTextFromProvidedContent:[content mutableCopy]];
    XCTAssertEqualObjects(result.title, @"rich_title");
    XCTAssertEqualObjects(result.subtitle, @"rich_subtitle");
    XCTAssertEqualObjects(result.body, @"rich_body");
}

- (void)testDownloadAttachmentSuccessful {
    XCTestExpectation *expectation = [self expectationWithDescription:@"[SwrvePushMediaHelper downloadAttachement: Success]"];
    
    id urlsessionmock = OCMPartialMock([NSURLSession sharedSession]);
    OCMExpect([urlsessionmock downloadTaskWithURL:OCMOCK_ANY completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invoke) {
        
        void (^completionHandler)(NSURL *location, NSURLResponse *response, NSError *error);
        
        // sub in a local file path so UNAttachment can verify it
        NSURL *mockedLocation = [self getlocalPathForXCAsset:@"swrve_logo" withExtension:@"png"];
        NSURLResponse *mockedResponse = [[NSURLResponse alloc] init];
        NSError *mockedError = nil;
        [invoke getArgument:&completionHandler atIndex:3];
        completionHandler(mockedLocation, mockedResponse, mockedError);
        
    });
    
    [SwrveNotificationManager downloadAttachment:@"https://www.doesntmattergunnamock/swrve_logo.png" withCompletedContentCallback:^(UNNotificationAttachment *attachment, NSError *error) {
        XCTAssertNotNil(attachment);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];
    
    OCMVerifyAll(urlsessionmock);
    [urlsessionmock stopMocking];
}

- (void)testDownloadAttachmentNetworkError {
    
    //mock NSURLSession
    id urlsessionmock = OCMPartialMock([NSURLSession sharedSession]);
    OCMExpect([urlsessionmock downloadTaskWithURL:OCMOCK_ANY completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invoke) {
        
        void (^completionHandler)(NSURL *location, NSURLResponse *response, NSError *error);
        
        NSURLResponse *mockedResponse = [[NSURLResponse alloc] init];
        NSError *mockedError = [NSError errorWithDomain:@"com.swrve"
                                                   code:-1
                                               userInfo:@{NSLocalizedDescriptionKey: @"No Network"}];
        [invoke getArgument:&completionHandler atIndex:3];
        completionHandler(nil, mockedResponse, mockedError);
        
    });
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"[SwrvePushMediaHelper downloadAttachement: Network Failure]"];
    [SwrveNotificationManager downloadAttachment:@"http://doesntmattergunnafail/failing.png" withCompletedContentCallback:^(UNNotificationAttachment *attachment, NSError *error) {
        XCTAssertNotNil(error);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];
    
    OCMVerifyAll(urlsessionmock);
    [urlsessionmock stopMocking];
}

- (void)testDownloadAttachmentError {
    XCTestExpectation *expectation = [self expectationWithDescription:@"[SwrvePushMediaHelper downloadAttachment: Success]"];
    
    //mock NSURLSession
    id urlsessionmock = OCMPartialMock([NSURLSession sharedSession]);
    OCMExpect([urlsessionmock downloadTaskWithURL:OCMOCK_ANY completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invoke) {
        
        void (^completionHandler)(NSURL *location, NSURLResponse *response, NSError *error);
        
        NSURL *mockedLocation = [NSURL URLWithString:@"totally/messed/up/file"];
        NSURLResponse *mockedResponse = [[NSURLResponse alloc] init];
        NSError *mockedError = nil;
        [invoke getArgument:&completionHandler atIndex:3];
        completionHandler(mockedLocation, mockedResponse, mockedError);
        
    });
    
    [SwrveNotificationManager downloadAttachment:@"http://doesntmattergunnafail/failing.png" withCompletedContentCallback:^(UNNotificationAttachment *attachment, NSError *error) {
        XCTAssertNotNil(error);
//        NSString *errorCode = [NSString stringWithFormat:@"%ld", (long)[error code]];
//        //Should be "Invalid attachment file URL". Error Code 100
//        XCTAssertEqualObjects(errorCode, @"100");
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];
    
    OCMVerifyAll(urlsessionmock);
    [urlsessionmock stopMocking];
}

- (void)testDownloadAttachmentNoExtensionPNG {
    XCTestExpectation *expectation = [self expectationWithDescription:@"[SwrvePushMediaHelper downloadAttachement: Success]"];
    
    id nsurlmock = OCMPartialMock([[NSURLResponse alloc] init]);
    OCMExpect([nsurlmock MIMEType]).andReturn(@"image/png");
    id urlsessionmock = OCMPartialMock([NSURLSession sharedSession]);
    OCMExpect([urlsessionmock downloadTaskWithURL:OCMOCK_ANY completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invoke) {
        
        void (^completionHandler)(NSURL *location, NSURLResponse *response, NSError *error);
        
        // sub in a local file path so UNAttachment can verify it
        NSURL *mockedLocation = [self getlocalPathForXCAsset:@"swrve_logo" withExtension:@"png"];
        NSError *mockedError = nil;
        [invoke getArgument:&completionHandler atIndex:3];
        completionHandler(mockedLocation, nsurlmock, mockedError);
        
    });
    
    [SwrveNotificationManager downloadAttachment:@"https://www.doesntmattergunnamock/swrve_logo" withCompletedContentCallback:^(UNNotificationAttachment *attachment, NSError *error) {
        XCTAssertNotNil(attachment);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];
    
    OCMVerifyAll(urlsessionmock);
    OCMVerifyAll(nsurlmock);
    [urlsessionmock stopMocking];
    [nsurlmock stopMocking];
}

- (void)testDownloadAttachmentNoExtensionGIF {
    XCTestExpectation *expectation = [self expectationWithDescription:@"[SwrvePushMediaHelper downloadAttachement: Success]"];
    
    id nsurlmock = OCMPartialMock([[NSURLResponse alloc] init]);
    OCMExpect([nsurlmock MIMEType]).andReturn(@"image/gif");
    id urlsessionmock = OCMPartialMock([NSURLSession sharedSession]);
    OCMExpect([urlsessionmock downloadTaskWithURL:OCMOCK_ANY completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invoke) {
        
        void (^completionHandler)(NSURL *location, NSURLResponse *response, NSError *error);
        
        // sub in a local file path so UNAttachment can verify it
        NSURL *mockedLocation = [self getlocalPathForXCAsset:@"logo" withExtension:@"gif"];
        NSError *mockedError = nil;
        [invoke getArgument:&completionHandler atIndex:3];
        completionHandler(mockedLocation, nsurlmock, mockedError);
        
    });
    
    [SwrveNotificationManager downloadAttachment:@"https://www.doesntmattergunnamock/swrve_logo" withCompletedContentCallback:^(UNNotificationAttachment *attachment, NSError *error) {
        XCTAssertNotNil(attachment);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];
    
    OCMVerifyAll(urlsessionmock);
    OCMVerifyAll(nsurlmock);
    [urlsessionmock stopMocking];
    [nsurlmock stopMocking];
}

- (void)testAttachmentFromCache {

    NSString *testCacheDir = [SwrveLocalStorage cachePath];
    NSURL *externalUrl = [NSURL URLWithString:@"http://sample/url/testAttachmentFromCache.png"];

    // create cached image with correct cache name in cache dir
    NSURL *cachedImageUrl = [SwrveNotificationManager cachedUrlFor:externalUrl withPathExtension:@"png" inCacheDir:testCacheDir];
    XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:[cachedImageUrl path]]);
    [[@"FakeImageData" dataUsingEncoding:NSUTF8StringEncoding] writeToURL:cachedImageUrl atomically:true];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[cachedImageUrl path]]);

    UNNotificationAttachment *attachment = [SwrveNotificationManager attachmentFromCache:[externalUrl absoluteString] inCacheDir:testCacheDir];
    XCTAssertNotNil(attachment);
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[[attachment URL] path]]);
    XCTAssertNotEqual([cachedImageUrl absoluteString], [[attachment URL] absoluteString]);
    
    NSURL *tempDirUrl = [NSURL fileURLWithPath:NSTemporaryDirectory()];
    NSURL *tempAttachmentUrl = [tempDirUrl URLByAppendingPathComponent:[cachedImageUrl lastPathComponent]];
    
    XCTAssertEqualObjects([[attachment URL] absoluteString], [tempAttachmentUrl absoluteString]);
}

- (void)testAttachmentFromCacheNoFileExtension {

    NSString *testCacheDir = [SwrveLocalStorage cachePath];
    NSURL *testCacheDirUrl = [NSURL URLWithString:testCacheDir];

    // create cached image with correct cache name in cache dir. A file extension will have been inferred.
    NSURL *noFileExtExternalImage = [NSURL URLWithString:@"http://sample/url/testAttachmentFromCacheNoFileExtension"];
    NSString *hashedName = [SwrveUser md5FromSource:[noFileExtExternalImage absoluteString]];
    hashedName = [hashedName stringByAppendingString:@".png"];
    NSURL *noFileExtCachedImage = [NSURL fileURLWithPathComponents:[NSArray arrayWithObjects:[testCacheDirUrl path], hashedName, nil]];
    [[@"FakeImageData" dataUsingEncoding:NSUTF8StringEncoding] writeToURL:noFileExtCachedImage atomically:true];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[noFileExtCachedImage path]]);

    UNNotificationAttachment *attachment = [SwrveNotificationManager attachmentFromCache:[noFileExtExternalImage absoluteString] inCacheDir:testCacheDir];
    XCTAssertNotNil(attachment);
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[[attachment URL] path]]);
    XCTAssertNotEqual([noFileExtCachedImage absoluteString], [[attachment URL] absoluteString]);
    
    NSURL *tempDirUrl = [NSURL fileURLWithPath:NSTemporaryDirectory()];
    NSURL *tempAttachmentUrl = [tempDirUrl URLByAppendingPathComponent:[noFileExtCachedImage lastPathComponent]];
    
    XCTAssertEqualObjects([[attachment URL] absoluteString], [tempAttachmentUrl absoluteString]);
}

- (void)testAttachmentFromCacheNoFileExtensionNotFound {
    NSString *testCacheDir = [[[NSBundle mainBundle] resourceURL] absoluteString];
    NSURL *noFileExtExternalImage = [NSURL URLWithString:@"http://sample/url/testAttachmentFromCacheNoFileExtensionNotFound"];
    UNNotificationAttachment *attachment = [SwrveNotificationManager attachmentFromCache:[noFileExtExternalImage absoluteString] inCacheDir:testCacheDir];
    XCTAssertNil(attachment);
}

- (void) testProduceButtonsFromUserInfoFull {
    NSArray<NSDictionary*> *buttons = @[@{SwrveNotificationButtonTitleKey:@"btn1",SwrveNotificationButtonActionKey:@"action1",
                                          SwrveNotificationButtonTypeKey:@[SwrveNotificationActionTypeForegroundKey]},
                                        @{SwrveNotificationButtonTitleKey:@"btn2",SwrveNotificationButtonActionKey:@"action2"},
                                        @{SwrveNotificationButtonTitleKey:@"btn3",SwrveNotificationButtonActionKey:@"action3",
                                          SwrveNotificationButtonTypeKey:@[SwrveNotificationActionTypeDestructiveKey, SwrveNotificationActionTypeAuthorisationKey]}];
    
    NSDictionary* sw = @{@"buttons" : buttons,
                         @"_p" : @"1",
                         @"category_options" : @[@"carplay"]};
    
    NSDictionary* userInfo = @{@"_sw": sw};
    
    UNNotificationCategory *category = [SwrveNotificationManager categoryFromUserInfo:userInfo];
    XCTAssertNotNil(category);
    XCTAssertTrue(category.options & UNNotificationCategoryOptionAllowInCarPlay, @"UNNotificationCategoryOptionAllowInCarPlay should have membership");
    XCTAssertFalse(category.options & UNNotificationCategoryOptionCustomDismissAction, @"UNNotificationCategoryOptionCustomDismissAction shouldn't have membership");
    
    XCTAssert([category.actions count] == 3 , @"There should be 3 actions");
    XCTAssert([category.actions[0].title isEqualToString:@"btn1"], @"The first button should have the title 'btn1'");
    XCTAssert([category.actions[1].title isEqualToString:@"btn2"], @"The second button should have the title 'btn2'");
    XCTAssert([category.actions[2].title isEqualToString:@"btn3"], @"The third button should have the title 'btn3'");
    XCTAssert([category.actions[0].identifier isEqualToString:@"0"], @"The first identifier should have the title '1'");
    XCTAssert([category.actions[1].identifier isEqualToString: @"1"], @"The second identifier should have the title '2'");
    XCTAssert([category.actions[2].identifier isEqualToString:@"2"], @"The third identifier should have the title '3'");
    
    XCTAssertTrue(category.actions[0].options & UNNotificationActionOptionForeground, @"UNNotificationActionOptionForeground should have membership in btn1");
    XCTAssertFalse(category.actions[1].options & UNNotificationActionOptionForeground, @"UNNotificationActionOptionForeground should not have Membership in btn2");
    XCTAssertTrue(category.actions[2].options & UNNotificationActionOptionDestructive, @"UNNotificationActionOptionDestructive should have membership in btn3");
    XCTAssertTrue(category.actions[2].options & UNNotificationActionOptionAuthenticationRequired, @"UNNotificationActionOptionAuthenticationRequired should have membership in btn3");
}

- (void) testProduceCategoryFromUserNoButtons {
    NSDictionary* sw = @{ @"_p" : @"1",
                         @"category_options" : @[@"carplay", @"hidden_show_title", @"hidden_show_subtitle"]};
    
    NSDictionary* userInfo = @{@"_sw": sw};
    
    UNNotificationCategory *category = [SwrveNotificationManager categoryFromUserInfo:userInfo];
    XCTAssertNotNil(category);
    if(@available(iOS 11.0,*)){
        XCTAssertTrue(category.options & UNNotificationCategoryOptionHiddenPreviewsShowTitle, @"On iOS 11+ UNNotificationCategoryOptionHiddenPreviewsShowTitle should have membership");
        XCTAssertTrue(category.options & UNNotificationCategoryOptionHiddenPreviewsShowSubtitle, @"On iOS 11+ UNNotificationCategoryOptionHiddenPreviewsShowSubtitle should have membership");
    }
    XCTAssertTrue(category.options & UNNotificationCategoryOptionAllowInCarPlay, @"UNNotificationCategoryOptionAllowInCarPlay should have membership");
    XCTAssertFalse(category.options & UNNotificationCategoryOptionCustomDismissAction, @"UNNotificationCategoryOptionCustomDismissAction shouldn't have membership");
}

- (void) testProduceCategoryHiddenPlaceholder {
    NSDictionary* sw = @{ @"_p" : @"1",
                          @"category_options" :  @[@"carplay", @"hidden_show_title", @"hidden_show_subtitle"],
                          @"hidden_placeholder": @"test placeholder"};
    
    NSDictionary* userInfo = @{@"_sw": sw};
    
    UNNotificationCategory *category = [SwrveNotificationManager categoryFromUserInfo:userInfo];
    XCTAssertNotNil(category);
    if(@available(iOS 11.0,*)){
        XCTAssertTrue(category.options & UNNotificationCategoryOptionHiddenPreviewsShowTitle, @"On iOS 11+ UNNotificationCategoryOptionHiddenPreviewsShowTitle should have membership");
        XCTAssertTrue(category.options & UNNotificationCategoryOptionHiddenPreviewsShowSubtitle, @"On iOS 11+ UNNotificationCategoryOptionHiddenPreviewsShowSubtitle should have membership");
        XCTAssertEqualObjects(category.hiddenPreviewsBodyPlaceholder, @"test placeholder");
    }
    XCTAssertTrue(category.options & UNNotificationCategoryOptionAllowInCarPlay, @"UNNotificationCategoryOptionAllowInCarPlay should have membership");
    XCTAssertFalse(category.options & UNNotificationCategoryOptionCustomDismissAction, @"UNNotificationCategoryOptionCustomDismissAction shouldn't have membership");
}

- (void) testActionOptionsForKeys {
    UNNotificationActionOptions result = [SwrveNotificationOptions actionOptionsForKeys:@[@"invalid"]];
    XCTAssertTrue(result == UNNotificationActionOptionNone);
    
    result = [SwrveNotificationOptions actionOptionsForKeys:nil];
    XCTAssertTrue(result == UNNotificationActionOptionNone);
    
    result = [SwrveNotificationOptions actionOptionsForKeys:@[SwrveNotificationActionTypeForegroundKey]];
    XCTAssertTrue(result == UNNotificationActionOptionForeground);
    
    result = [SwrveNotificationOptions actionOptionsForKeys:@[SwrveNotificationActionTypeDestructiveKey]];
    XCTAssertTrue(result == UNNotificationActionOptionDestructive);
    
    result = [SwrveNotificationOptions actionOptionsForKeys:@[SwrveNotificationActionTypeAuthorisationKey]];
    XCTAssertTrue(result == UNNotificationActionOptionAuthenticationRequired);
    
    NSArray *multipleOptions = @[SwrveNotificationActionTypeAuthorisationKey, SwrveNotificationActionTypeDestructiveKey];
    result = [SwrveNotificationOptions actionOptionsForKeys:multipleOptions];
    XCTAssertTrue(result & UNNotificationActionOptionAuthenticationRequired);
    XCTAssertTrue(result & UNNotificationActionOptionDestructive);
    XCTAssertFalse(result & UNNotificationActionOptionForeground); //ensure it's only adding the defined ones
}

- (void) testCategoryOptionsForKeys {
    UNNotificationCategoryOptions result = [SwrveNotificationOptions categoryOptionsForKeys:@[@"invalid"]];
    XCTAssertTrue(result == UNNotificationCategoryOptionNone);
    
    result = [SwrveNotificationOptions categoryOptionsForKeys:nil];
    XCTAssertTrue(result == UNNotificationCategoryOptionNone);
    
    result = [SwrveNotificationOptions categoryOptionsForKeys:@[SwrveNotificationCategoryTypeOptionsCustomDismissKey]];
    XCTAssertTrue(result == UNNotificationCategoryOptionCustomDismissAction);
    
    result = [SwrveNotificationOptions categoryOptionsForKeys:@[SwrveNotificationCategoryTypeOptionsCarPlayKey]];
    XCTAssertTrue(result == UNNotificationCategoryOptionAllowInCarPlay);
    
    if(@available(iOS 11.0,*)){
        result = [SwrveNotificationOptions categoryOptionsForKeys:@[SwrveNotificationCategoryTypeOptionsHiddenShowTitleKey]];
        XCTAssertTrue(result == UNNotificationCategoryOptionHiddenPreviewsShowTitle);
        
        result = [SwrveNotificationOptions categoryOptionsForKeys:@[SwrveNotificationCategoryTypeOptionsHiddenShowSubtitleKey]];
        XCTAssertTrue(result == UNNotificationCategoryOptionHiddenPreviewsShowSubtitle);
        
    } else {
        result = [SwrveNotificationOptions categoryOptionsForKeys:@[SwrveNotificationCategoryTypeOptionsHiddenShowTitleKey]];
        XCTAssertTrue(result == UNNotificationCategoryOptionNone);
        
        result = [SwrveNotificationOptions categoryOptionsForKeys:@[SwrveNotificationCategoryTypeOptionsHiddenShowSubtitleKey]];
        XCTAssertTrue(result == UNNotificationCategoryOptionNone);
    }
    
    NSArray *multipleOptions = @[SwrveNotificationCategoryTypeOptionsCarPlayKey, SwrveNotificationCategoryTypeOptionsCustomDismissKey];
    
    //test bitwise membership
    result = [SwrveNotificationOptions categoryOptionsForKeys:multipleOptions];
    XCTAssertTrue(result & UNNotificationCategoryOptionAllowInCarPlay);
    XCTAssertTrue(result & UNNotificationCategoryOptionCustomDismissAction);
}

#pragma mark - private

- (UNNotificationContent *) createTestNotificationContentWithUserInfo:(NSDictionary *)userInfo {
    UNMutableNotificationContent *testContent = [[UNMutableNotificationContent alloc] init];
    testContent.title = @"test_title";
    testContent.subtitle = @"test_subtitle";
    testContent.body = @"test_body";
    testContent.userInfo = userInfo;
    return [testContent copy];
}

- (NSURL *) getlocalPathForXCAsset:(NSString*) filename withExtension:(NSString *)extension {
    NSBundle *bundle = [NSBundle bundleForClass:[TestableSwrve class]];
    return [[bundle URLForResource:filename withExtension:extension] URLByDeletingPathExtension];
}

@end
