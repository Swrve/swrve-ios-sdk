#import <XCTest/XCTest.h>
#import "SwrveRESTClient.h"
#import "SwrveSDK.h"
#import "TestableSwrve.h"
#import "SwrveTestHelper.h"
#import "SwrveUser.h"
#import "SwrveProfileManager.h"
#import "SwrveMockNSURLProtocol.h"
#import "SwrveMigrationsManager.h"

@interface SwrveMigrationsManager()
+ (void)setCurrentCacheVersion:(int)cacheVersion;
@end

@interface Swrve(privateAccess)
@property(atomic) SwrveMessageController *messaging;
@property(atomic) int eventBufferBytes;
@property(atomic) SwrveRESTClient *restClient;
@property(atomic) SwrveProfileManager *profileManager;
@property (atomic) SwrveSignatureProtectedFile* resourcesFile;
@property (atomic) SwrveSignatureProtectedFile* resourcesDiffFile;
@property(atomic) NSMutableArray *pausedEventsArray;
- (NSString *)signatureKey;
- (void)sendQueuedEventsWithCallback:(void(^)(NSURLResponse* response, NSData* data, NSError* error))eventBufferCallback
                   eventFileCallback:(void(^)(NSURLResponse* response, NSData* data, NSError* error))eventFileCallback;
- (void)pauseEventSending;
- (void)queuePausedEventsArray;
- (void)maybeFlushToDisk;
- (int)queueEvent:(NSString *)eventType data:(NSMutableDictionary *)eventData triggerCallback:(bool)triggerCallback notifyMessageController:(bool)notifyMessageController;

@end

@interface SwrveMessageController()
@property (atomic) SwrveSignatureProtectedFile* campaignFile;
@end

@interface SwrveProfileManager()
- (void)saveSwrveUser:(SwrveUser *)swrveUser;
- (SwrveUser *)swrveUserWithId:(NSString *)aUserId;
- (NSArray *)swrveUsers;
@property (strong, nonatomic) SwrveRESTClient *restClient;
@property (strong, nonatomic) NSURL *identityURL;
@end

@interface SwrveUser()
@property (nonatomic, strong) NSString *swrveId;
@property (nonatomic, strong) NSString *externalId;
@property (nonatomic) BOOL verified;
@end

@interface SwrveTestUserIdentity : XCTestCase

@end

@implementation SwrveTestUserIdentity

- (NSDictionary *)dicFromCachedContent:(NSString*)content containingValue:(NSString *)value {

    NSMutableArray* cacheLines = [[NSMutableArray alloc] initWithArray:[content componentsSeparatedByString:@"\n"]];
    [cacheLines removeLastObject];

    for (NSString *s in cacheLines) {

        if ([s containsString:value]) {

            NSString *newString = [s substringToIndex:s.length-1];
            NSDictionary * cacheDic = [NSJSONSerialization JSONObjectWithData:[newString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
            return cacheDic;
        }
    }
    return nil;
}

- (void)setUp {
    [super setUp];
    // SwrveTestHelper sets up a mock NSURL protocol so we can intercept network calls and return fake data base on url input. See SwrveMockNSURLProtocol
    [SwrveTestHelper setUp];
}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [super tearDown];
}

- (void)testIdentify_SwrveError {
    NSString *someInitialUserId = @"SwrveUser0";
    [SwrveTestHelper setAlreadyInstalledUserId:someInitialUserId];

    SwrveConfig *config = [[SwrveConfig alloc] init];
    [config setAutoDownloadCampaignsAndResources:NO];

    [SwrveSDK sharedInstanceWithAppID:1030 apiKey:@"Key" config:config];
    Swrve *swrve = [SwrveSDK sharedInstance];
    swrve.batchURL = [NSURL URLWithString:@"200"];

    swrve.profileManager.identityURL = [NSURL URLWithString:@"SwrveError"];

    XCTestExpectation *swrveError = [self expectationWithDescription:@"SwrveError"];
    [swrve identify:@"ExternalID" onSuccess:^(NSString *status, NSString *swrveUserId) {

    } onError:^(NSInteger httpCode, NSString *errorMessage) {
        XCTAssertTrue(errorMessage != nil);
        XCTAssertTrue([errorMessage isEqualToString:@"Unknown Route"]);
        XCTAssertTrue(httpCode == 404);
        [swrveError fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];
}

- (void)testUserIdChanged_EventFailure_WrittenBackToCorrectUserIdCache {
    SwrveUser *verifiedUser = [[SwrveUser alloc] initWithExternalId:@"User0" swrveId:@"SwrveUser0" verified:true];
    SwrveProfileManager *profileManager = [[SwrveProfileManager alloc] init];
    [profileManager saveSwrveUser:verifiedUser];

    verifiedUser = [[SwrveUser alloc] initWithExternalId:@"User1" swrveId:@"SwrveUser1" verified:true];
    profileManager = [[SwrveProfileManager alloc] init];
    [profileManager saveSwrveUser:verifiedUser];

    // set current swrve user as SwrveUser1
    [SwrveTestHelper setAlreadyInstalledUserId:@"SwrveUser1"];

    //normal setup
    SwrveConfig *config = [[SwrveConfig alloc] init];
    [config setAutoDownloadCampaignsAndResources:NO];
    [SwrveSDK sharedInstanceWithAppID:1 apiKey:@"Key" config:config];
    Swrve *swrve = [SwrveSDK sharedInstance];

    // queue event
    [swrve event:@"Event1"];

    // fail events and mock a change in swrve user id before sendQueuedEventsWithCallback completes (below line will change to SwrveUser0)
    // swrveUserIdForEventSending set before the rest call in sendQueuedEventsWithCallback and used in the callback will ensure the events are written back to the correct user.

    swrve.batchURL = [NSURL URLWithString:@"500_SwitchUserID"]; // will switch back to SwrveUser0

    XCTestExpectation *expectation = [self expectationWithDescription:@"EventFile"];
    [swrve sendQueuedEventsWithCallback:^(NSURLResponse *response, NSData *data, NSError *error) {
        [self assertEvent:@"Event1" forUserId:@"SwrveUser1" existsInFile:YES]; //check Event1 is in the cache file for SwrveUser1
        [self assertEvent:@"Event1" forUserId:@"SwrveUser0" existsInFile:NO]; //check Event1 is not in the cache file for the current user SwrveUser0
        [expectation fulfill];
    } eventFileCallback:^(NSURLResponse *response, NSData *data, NSError *error) { }];

    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];
}

- (void)assertEvent:(NSString *)eventName forUserId:(NSString *)userId existsInFile:(BOOL)exists {
    NSString *eventCacheFile = [SwrveLocalStorage eventsFilePathForUserId:userId];
    NSMutableArray *cachedContentArray = [SwrveTestHelper dicArrayFromCachedFile:[NSURL fileURLWithPath:eventCacheFile]];
    NSArray *filtered = [cachedContentArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(name == %@)", eventName]];
    if (exists && [filtered count] == 0) {
        XCTFail(@"Missing expected eventName:%@ for userId:%@", eventName, userId);
        return;
    } else if (!exists && [filtered count] > 0) {
        XCTFail(@"Contains unexpected eventName:%@ for userId:%@", eventName, userId);
    }
}

- (void)assertEvent:(NSString *)eventName forUserId:(NSString *)userId existsInBuffer:(BOOL)exists swrve:(Swrve *)swrve {

    if ([[swrve eventBuffer] count] == 0 && exists) {
        XCTFail(@"Missing expected eventName:%@ for userId:%@", eventName, userId);
        return;
    }

    for (NSString *event in [swrve eventBuffer] ) {
        NSDictionary *eventDic = [SwrveTestHelper makeDictionaryFromEventBufferEntry:event];
        if ([[eventDic objectForKey:@"name"] isEqualToString:eventName]) {
            if (!exists) {
                XCTFail(@"Contains unexpected eventName:%@ for userId:%@", eventName, userId);
            }
        }
    }
}

//TODO review this test when moving to public
- (void)testSendEventsAndLogFile_PrivateCallbacks_500 {
    SwrveConfig *config = [[SwrveConfig alloc] init];
    [config setAutoDownloadCampaignsAndResources:NO];

    [SwrveSDK sharedInstanceWithAppID:1030 apiKey:@"Key" config:config];
    Swrve *swrve = [SwrveSDK sharedInstance];
    swrve.batchURL = [NSURL URLWithString:@"500"];

    [swrve event:@"Test"];

    XCTestExpectation *eventError = [self expectationWithDescription:@"EventError"];
    XCTestExpectation *eventErrorFileCallback = [self expectationWithDescription:@"EventErrorFileCallback"];
    [swrve sendQueuedEventsWithCallback:^(NSURLResponse *response, NSData *data, NSError *error) {
        XCTAssertTrue(error != nil);
        [eventError fulfill];

    } eventFileCallback:^(NSURLResponse *response, NSData *data, NSError *error) {
        // nothing was in the log so it wasn't sent
        XCTAssertTrue(response == nil);
        XCTAssertTrue(data == nil);
        XCTAssertTrue(error == nil);
        [eventErrorFileCallback fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];

    // Send events again, log file will get sent and fail this time

    XCTestExpectation *logError = [self expectationWithDescription:@"LogError"];
    XCTestExpectation *logFileEventError = [self expectationWithDescription:@"LogFileEventError"];
    [swrve sendQueuedEventsWithCallback:^(NSURLResponse *response, NSData *data, NSError *error) {
        //there maybe events that were added to buffer after inital write to file above, so no checks here.
        [logError fulfill];
    } eventFileCallback:^(NSURLResponse *response, NSData *data, NSError *error) {
        //there should be events sent from file and they should fail with an error.
        XCTAssertTrue(error != nil);
        [logFileEventError fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];
}

- (void)testSendEventsAndLogFile_PrivateCallbacks_200 {
    SwrveConfig *config = [[SwrveConfig alloc] init];
    [config setAutoDownloadCampaignsAndResources:NO];

    [SwrveSDK sharedInstanceWithAppID:1030 apiKey:@"Key" config:config];
    Swrve *swrve = [SwrveSDK sharedInstance];
    swrve.batchURL = [NSURL URLWithString:@"200"];

    [swrve event:@"Test"];

    XCTestExpectation *eventError = [self expectationWithDescription:@"EventError"];
    XCTestExpectation *eventFileCallbackError = [self expectationWithDescription:@"eventFileCallbackError"];
    [swrve sendQueuedEventsWithCallback:^(NSURLResponse *response, NSData *data, NSError *error) {
        XCTAssertTrue(error == nil);
        [eventError fulfill];

    } eventFileCallback:^(NSURLResponse *response, NSData *data, NSError *error) {
        // nothing was in the log so it wasn't sent
        XCTAssertTrue(response == nil);
        XCTAssertTrue(data == nil);
        XCTAssertTrue(error == nil);
        [eventFileCallbackError fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];

    [swrve event:@"Test2"];
    [swrve saveEventsToDisk];

    XCTestExpectation *logError = [self expectationWithDescription:@"logError"];
    XCTestExpectation *logFileEventError = [self expectationWithDescription:@"LogFileEventError"];
    [swrve sendQueuedEventsWithCallback:^(NSURLResponse *response, NSData *data, NSError *error) {
        XCTAssertTrue(error == nil);
        [logError fulfill];
    } eventFileCallback:^(NSURLResponse *response, NSData *data, NSError *error) {
        XCTAssertTrue(error == nil);
        [logFileEventError fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];
}

- (void)testIdentify_Body {
    NSString *someInitialUserId = @"SwrveUser0";
    [SwrveTestHelper setAlreadyInstalledUserId:someInitialUserId];

    SwrveConfig *config = [[SwrveConfig alloc] init];
    [config setAutoDownloadCampaignsAndResources:NO];

    [SwrveSDK sharedInstanceWithAppID:1030 apiKey:@"Key" config:config];
    Swrve *swrve = [SwrveSDK sharedInstance];
    swrve.batchURL = [NSURL URLWithString:@"200"];

    swrve.profileManager.identityURL = [NSURL URLWithString:@"IdentifyBody"];

    XCTestExpectation *bodyExpectation = [self expectationWithDescription:@"IdentifyBody"];
    [swrve identify:@"ExternalID" onSuccess:^(NSString *status, NSString *swrveUserId) {
        [bodyExpectation fulfill];
    } onError:^(NSInteger httpCode, NSString *errorMessage) {

    }];

    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];
}

- (void)testIdentify_Switching_Users_NewSession {
    //setup a verfired user
    NSString *someInitialUserId = @"SwrveUser1";
    [SwrveLocalStorage saveSwrveUserId:someInitialUserId];
    SwrveUser *verifiedUser = [[SwrveUser alloc] initWithExternalId:@"User1" swrveId:@"SwrveUser1" verified:true];
    SwrveProfileManager *profileManager = [[SwrveProfileManager alloc]init];
    [profileManager saveSwrveUser:verifiedUser];

    SwrveConfig *config = [[SwrveConfig alloc] init];
    [config setAutoDownloadCampaignsAndResources:NO];

    [SwrveSDK sharedInstanceWithAppID:1030 apiKey:@"Key" config:config];
    Swrve *swrve = [SwrveSDK sharedInstance];

    //fail all events so they will end up cache files
    swrve.batchURL = [NSURL URLWithString:@"500"];

    //mock return SwrveUser2
    swrve.profileManager.identityURL = [NSURL URLWithString:@"User2"];

    //do this so the session start events will end up in cache files
    [swrve appDidBecomeActive:nil];

    [swrve identify:@"User2" onSuccess:^(NSString *status, NSString *swrveUserId) {
    } onError:^(NSInteger httpCode, NSString *errorMessage) {
    }];

    XCTestExpectation *expectation = [self expectationWithDescription:@"SwrveUser1"];
    [SwrveTestHelper waitForBlock:0.005 conditionBlock:^BOOL(){
        //confirm Swrve.first_session exists in cache for intial user
        NSString *eventCacheFile = [SwrveLocalStorage eventsFilePathForUserId:@"SwrveUser1"];
        NSMutableArray *cachedContentArray = [SwrveTestHelper dicArrayFromCachedFile:[NSURL fileURLWithPath:eventCacheFile]];
        NSArray *filtered = [cachedContentArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(name == %@)", @"Swrve.first_session"]];
        return [filtered count] == 1;

    } expectation:expectation];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];

    //confirm Swrve.first_session does not exist in cache for new user
    NSString *eventCacheFile = [SwrveLocalStorage eventsFilePathForUserId:@"SwrveUser2"];
    NSMutableArray *cachedContentArray = [SwrveTestHelper dicArrayFromCachedFile:[NSURL fileURLWithPath:eventCacheFile]];
    NSArray *filtered = [cachedContentArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(name == %@)", @"Swrve.first_session"]];
    XCTAssertTrue([filtered count] == 0);

    // switch back to swrve user 1 , confirm frist session event still in cahce
    [swrve identify:@"User1" onSuccess:^(NSString *status, NSString *swrveUserId) {
    } onError:^(NSInteger httpCode, NSString *errorMessage) {
    }];

    expectation = [self expectationWithDescription:@"User id changed to SwrveUser1"];
    [SwrveTestHelper waitForBlock:0.005 conditionBlock:^BOOL(){

        //confirm Swrve.first_session still exists in cache
        NSString *eventCacheFile = [SwrveLocalStorage eventsFilePathForUserId:@"SwrveUser1"];
        NSMutableArray *cachedContentArray = [SwrveTestHelper dicArrayFromCachedFile:[NSURL fileURLWithPath:eventCacheFile]];
        NSArray *filtered = [cachedContentArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(name == %@)", @"Swrve.first_session"]];
        return [filtered count] == 1;

    } expectation:expectation];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

- (void)testIdentify_Switching_Users_NewSession_OffLine {
    SwrveConfig* config = [[SwrveConfig alloc] init];
    [config setAutoDownloadCampaignsAndResources:NO];

    [SwrveSDK sharedInstanceWithAppID:1030 apiKey:@"Key" config:config];
    Swrve *swrve = [SwrveSDK sharedInstance];

    //fail all events so they will end up cache files
    swrve.batchURL = [NSURL URLWithString:@"500"];

    //fail identity call
    swrve.profileManager.identityURL = [NSURL URLWithString:@"500"];
    [swrve appDidBecomeActive:nil];

    //============================================================================

    // User5 identify
    __block NSString *user1SwrveUserID = swrve.userID;
    [swrve identify:@"User5" onSuccess:^(NSString *status, NSString *swrveUserId) {
    } onError:^(NSInteger httpCode, NSString *errorMessage) {
    }];

    XCTestExpectation *expectation = [self expectationWithDescription:@"User5 events 1"];
    
    [SwrveTestHelper waitForBlock:0.005 conditionBlock:^BOOL(){
        NSString *eventCacheFile = [SwrveLocalStorage eventsFilePathForUserId:swrve.userID];
        NSMutableArray *cachedContentArray = [SwrveTestHelper dicArrayFromCachedFile:[NSURL fileURLWithPath:eventCacheFile]];
        NSArray *filtered = [cachedContentArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"session_start"]];
        return [filtered count] == 1;

    } expectation:expectation];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];

    //============================================================================

    // User6 identify
    [swrve identify:@"User6" onSuccess:^(NSString *status, NSString *swrveUserId) {
    } onError:^(NSInteger httpCode, NSString *errorMessage) {
    }];

    expectation = [self expectationWithDescription:@"User6 events 1 "];
    [SwrveTestHelper waitForBlock:0.005 conditionBlock:^BOOL(){
        NSString *eventCacheFile = [SwrveLocalStorage eventsFilePathForUserId:swrve.userID];
        NSMutableArray *cachedContentArray = [SwrveTestHelper dicArrayFromCachedFile:[NSURL fileURLWithPath:eventCacheFile]];
        NSArray *filtered = [cachedContentArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"session_start"]];
        return [filtered count] == 1  && (![swrve.userID isEqualToString:user1SwrveUserID]); //ensure user2

    } expectation:expectation];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    
    //============================================================================

    // Switch back to User5
    [swrve identify:@"User5" onSuccess:^(NSString *status, NSString *swrveUserId) {
    } onError:^(NSInteger httpCode, NSString *errorMessage) {
    }];

    expectation = [self expectationWithDescription:@"User5 events 2"];
    [SwrveTestHelper waitForBlock:0.005 conditionBlock:^BOOL(){
        // Should be 2 session start events for User 1
        NSString *eventCacheFile = [SwrveLocalStorage eventsFilePathForUserId:swrve.userID];
        NSMutableArray *cachedContentArray = [SwrveTestHelper dicArrayFromCachedFile:[NSURL fileURLWithPath:eventCacheFile]];
        NSArray *filtered = [cachedContentArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"session_start"]];
        
        return [filtered count] == 2;

    } expectation:expectation];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testIdentify_Switching_Users_Succeeds {
    NSString *someInitialUserId = @"SwrveUser0";
    [SwrveTestHelper setAlreadyInstalledUserId:someInitialUserId];

    SwrveConfig *config = [[SwrveConfig alloc] init];
    [config setAutoDownloadCampaignsAndResources:NO];

    [SwrveSDK sharedInstanceWithAppID:1030 apiKey:@"Key" config:config];
    Swrve *swrve = [SwrveSDK sharedInstance];
    swrve.batchURL = [NSURL URLWithString:@"200"];

    swrve.profileManager.identityURL = [NSURL URLWithString:@"User1"]; //will return SwrveUser1

    //The current userID should be SwrveUser0
    XCTAssertTrue([swrve.userID isEqualToString:@"SwrveUser0"]);
    XCTAssertTrue([swrve.profileManager.userId  isEqualToString:@"SwrveUser0"]);
    XCTAssertTrue([[SwrveLocalStorage swrveUserId] isEqualToString:@"SwrveUser0"]);

    XCTestExpectation *expectation = [self expectationWithDescription:@"User id changed to SwrveUser1"];
    [swrve identify:@"User1" onSuccess:^(NSString *status, NSString *swrveUserId) {
        XCTAssertTrue([swrve.userID isEqualToString:@"SwrveUser1"],@"Value: %@", swrve.userID);
        XCTAssertTrue([swrve.profileManager.userId  isEqualToString:@"SwrveUser1"],@"Value: %@", swrve.profileManager.userId);
        XCTAssertTrue([[SwrveLocalStorage swrveUserId] isEqualToString:@"SwrveUser1"],@"Value: %@", [SwrveLocalStorage swrveUserId]);

        [expectation fulfill];
    } onError:^(NSInteger httpCode, NSString *errorMessage) {

    }];

    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];
}

- (void)testIdentify_Switching_Users_Using_Cache {
    NSString *someInitialUserId = @"SwrveUser0";
    [SwrveTestHelper setAlreadyInstalledUserId:someInitialUserId];

    // save a verified user
    SwrveUser *verifiedUser = [[SwrveUser alloc] initWithExternalId:@"User1" swrveId:@"SwrveUser1" verified:true];
    SwrveProfileManager *profileManager = [[SwrveProfileManager alloc] init];
    [profileManager saveSwrveUser:verifiedUser];

    SwrveConfig *config = [[SwrveConfig alloc] init];
    [config setAutoDownloadCampaignsAndResources:NO];

    [SwrveSDK sharedInstanceWithAppID:1030 apiKey:@"Key" config:config];
    Swrve *swrve = [SwrveSDK sharedInstance];
    swrve.batchURL = [NSURL URLWithString:@"200"];

    // will be loaded from cache anyway
    swrve.profileManager.identityURL = [NSURL URLWithString:@"200"];

    // swrve user id and resource files should be under SwrveUser0
    XCTAssertTrue([swrve.userID isEqualToString:@"SwrveUser0"],@"Value: %@", swrve.userID);
    XCTAssertTrue([swrve.profileManager.userId  isEqualToString:@"SwrveUser0"],@"Value: %@", swrve.profileManager.userId );
    XCTAssertTrue([[SwrveLocalStorage swrveUserId] isEqualToString:@"SwrveUser0"],@"Value: %@", [SwrveLocalStorage swrveUserId]);

    __block NSString *expectedResourceFile = [swrve.resourcesFile.filename.absoluteString lastPathComponent];
    __block NSString *expectedResourceDiffFile = [swrve.resourcesDiffFile.filename.absoluteString lastPathComponent];
    __block NSString *expectedCampaignFile  = [swrve.messaging.campaignFile.filename.absoluteString lastPathComponent];
    __block NSString *expectedEventFile = [swrve.eventFilename.absoluteString lastPathComponent];

    XCTAssertTrue([expectedResourceFile isEqualToString:@"SwrveUser0srcngt2.txt"],@"Value: %@", expectedResourceFile);
    XCTAssertTrue([expectedResourceDiffFile isEqualToString:@"SwrveUser0rsdfngt2.txt"],@"Value: %@", expectedResourceDiffFile);
    XCTAssertTrue([expectedCampaignFile isEqualToString:@"SwrveUser0cmcc2.json"],@"Value: %@", expectedCampaignFile);
    XCTAssertTrue([expectedEventFile isEqualToString:@"SwrveUser0swrve_events.txt"],@"Value: %@", expectedEventFile);

    XCTestExpectation *expectation = [self expectationWithDescription:@"User id changed to SwrveUser1"];

    [swrve identify:@"User1" onSuccess:^(NSString *status, NSString *swrveUserId) {

        // swrve user id and resource files should now be under SwrveUser1
        XCTAssertTrue([swrve.userID isEqualToString:@"SwrveUser1"],@"Value: %@", swrve.userID);
        XCTAssertTrue([swrve.profileManager.userId  isEqualToString:@"SwrveUser1"],@"Value: %@", swrve.profileManager.userId );
        XCTAssertTrue([[SwrveLocalStorage swrveUserId] isEqualToString:@"SwrveUser1"],@"Value: %@", [SwrveLocalStorage swrveUserId]);

        expectedResourceFile = [swrve.resourcesFile.filename.absoluteString lastPathComponent];
        expectedResourceDiffFile = [swrve.resourcesDiffFile.filename.absoluteString lastPathComponent];
        expectedCampaignFile = [swrve.messaging.campaignFile.filename.absoluteString lastPathComponent];
        expectedEventFile = [swrve.eventFilename.absoluteString lastPathComponent];

        XCTAssertTrue([expectedResourceFile isEqualToString:@"SwrveUser1srcngt2.txt"],@"Value: %@", expectedResourceFile);
        XCTAssertTrue([expectedResourceDiffFile isEqualToString:@"SwrveUser1rsdfngt2.txt"],@"Value: %@", expectedResourceDiffFile);
        XCTAssertTrue([expectedCampaignFile isEqualToString:@"SwrveUser1cmcc2.json"],@"Value: %@", expectedCampaignFile);
        XCTAssertTrue([expectedEventFile isEqualToString:@"SwrveUser1swrve_events.txt"],@"Value: %@", expectedEventFile);

        [expectation fulfill];

    } onError:^(NSInteger httpCode, NSString *errorMessage) {


    }];

    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];
}

- (void)testIdentify_Switch_Between_3_Users {
    SwrveConfig *config = [[SwrveConfig alloc] init];
    [config setAutoDownloadCampaignsAndResources:NO];

    [SwrveSDK sharedInstanceWithAppID:1030 apiKey:@"Key" config:config];
    Swrve *swrve = [SwrveSDK sharedInstance];
    swrve.batchURL = [NSURL URLWithString:@"200"];

    swrve.profileManager.identityURL = [NSURL URLWithString:@"User1"]; //will return SwrveUser1

    __block NSString *expectedResourceFile = nil;
    __block NSString *expectedResourceDiffFile = nil;
    __block NSString *expectedCampaignFile = nil;
    __block NSString *expectedEventFile = nil;

    XCTestExpectation *expectation1 = [self expectationWithDescription:@"Swrve User1 loaded"];

    [swrve identify:@"User1" onSuccess:^(NSString *status, NSString *swrveUserId) {

        // swrve user id and resource files should now be under SwrveUser1

        XCTAssertTrue([swrve.userID isEqualToString:@"SwrveUser1"],@"Value: %@", swrve.userID);
        XCTAssertTrue([swrve.profileManager.userId  isEqualToString:@"SwrveUser1"],@"Value: %@", swrve.profileManager.userId );
        XCTAssertTrue([[SwrveLocalStorage swrveUserId] isEqualToString:@"SwrveUser1"],@"Value: %@", [SwrveLocalStorage swrveUserId]);

        expectedResourceFile = [swrve.resourcesFile.filename.absoluteString lastPathComponent];
        expectedResourceDiffFile = [swrve.resourcesDiffFile.filename.absoluteString lastPathComponent];
        expectedCampaignFile = [swrve.messaging.campaignFile.filename.absoluteString lastPathComponent];
        expectedEventFile = [swrve.eventFilename.absoluteString lastPathComponent];

        XCTAssertTrue([expectedResourceFile isEqualToString:@"SwrveUser1srcngt2.txt"],@"Value: %@", expectedResourceFile);
        XCTAssertTrue([expectedResourceDiffFile isEqualToString:@"SwrveUser1rsdfngt2.txt"],@"Value: %@", expectedResourceDiffFile);
        XCTAssertTrue([expectedCampaignFile isEqualToString:@"SwrveUser1cmcc2.json"],@"Value: %@", expectedCampaignFile);
        XCTAssertTrue([expectedEventFile isEqualToString:@"SwrveUser1swrve_events.txt"],@"Value: %@", expectedEventFile);

        [expectation1 fulfill];

    } onError:^(NSInteger httpCode, NSString *errorMessage) {


    }];

    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];

    //=================================================================================

    swrve.profileManager.identityURL = [NSURL URLWithString:@"User2"]; //will return SwrveUser2

    XCTestExpectation *expectation2 = [self expectationWithDescription:@"Swrve User2 loaded"];
    [swrve identify:@"User2" onSuccess:^(NSString *status, NSString *swrveUserId) {

        // swrve user id and resource files should now be under SwrveUser2

        XCTAssertTrue([swrve.userID isEqualToString:@"SwrveUser2"],@"Value: %@", swrve.userID);
        XCTAssertTrue([swrve.profileManager.userId  isEqualToString:@"SwrveUser2"],@"Value: %@", swrve.profileManager.userId );
        XCTAssertTrue([[SwrveLocalStorage swrveUserId] isEqualToString:@"SwrveUser2"],@"Value: %@", [SwrveLocalStorage swrveUserId]);

        expectedResourceFile = [swrve.resourcesFile.filename.absoluteString lastPathComponent];
        expectedResourceDiffFile = [swrve.resourcesDiffFile.filename.absoluteString lastPathComponent];
        expectedCampaignFile = [swrve.messaging.campaignFile.filename.absoluteString lastPathComponent];
        expectedEventFile = [swrve.eventFilename.absoluteString lastPathComponent];

        XCTAssertTrue([expectedResourceFile isEqualToString:@"SwrveUser2srcngt2.txt"],@"Value: %@", expectedResourceFile);
        XCTAssertTrue([expectedResourceDiffFile isEqualToString:@"SwrveUser2rsdfngt2.txt"],@"Value: %@", expectedResourceDiffFile);
        XCTAssertTrue([expectedCampaignFile isEqualToString:@"SwrveUser2cmcc2.json"],@"Value: %@", expectedCampaignFile);
        XCTAssertTrue([expectedEventFile isEqualToString:@"SwrveUser2swrve_events.txt"],@"Value: %@", expectedEventFile);

        [expectation2 fulfill];

    } onError:^(NSInteger httpCode, NSString *errorMessage) {

    }];

    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];

    //=================================================================================

    swrve.profileManager.identityURL = [NSURL URLWithString:@"User3"]; //will return SwrveUser3

    XCTestExpectation *expectation3 = [self expectationWithDescription:@"Swrve User3 loaded"];
    [swrve identify:@"User3" onSuccess:^(NSString *status, NSString *swrveUserId) {

        // swrve user id and resource files should now be under SwrveUser3

        XCTAssertTrue([swrve.userID isEqualToString:@"SwrveUser3"],@"Value: %@", swrve.userID);
        XCTAssertTrue([swrve.profileManager.userId  isEqualToString:@"SwrveUser3"],@"Value: %@", swrve.profileManager.userId );
        XCTAssertTrue([[SwrveLocalStorage swrveUserId] isEqualToString:@"SwrveUser3"],@"Value: %@", [SwrveLocalStorage swrveUserId]);

        expectedResourceFile = [swrve.resourcesFile.filename.absoluteString lastPathComponent];
        expectedResourceDiffFile = [swrve.resourcesDiffFile.filename.absoluteString lastPathComponent];
        expectedCampaignFile = [swrve.messaging.campaignFile.filename.absoluteString lastPathComponent];
        expectedEventFile = [swrve.eventFilename.absoluteString lastPathComponent];

        XCTAssertTrue([expectedResourceFile isEqualToString:@"SwrveUser3srcngt2.txt"],@"Value: %@", expectedResourceFile);
        XCTAssertTrue([expectedResourceDiffFile isEqualToString:@"SwrveUser3rsdfngt2.txt"],@"Value: %@", expectedResourceDiffFile);
        XCTAssertTrue([expectedCampaignFile isEqualToString:@"SwrveUser3cmcc2.json"],@"Value: %@", expectedCampaignFile);
        XCTAssertTrue([expectedEventFile isEqualToString:@"SwrveUser3swrve_events.txt"],@"Value: %@", expectedEventFile);

        [expectation3 fulfill];

    } onError:^(NSInteger httpCode, NSString *errorMessage) {

    }];

    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];
}

- (void)testIdentify_Flush_Events_Succeed_Switching_Users_Fails {
    NSString *someInitialUserId = @"SomeUserID";
    [SwrveTestHelper setAlreadyInstalledUserId:someInitialUserId];

    SwrveConfig *config = [[SwrveConfig alloc] init];
    [config setAutoDownloadCampaignsAndResources:NO];

    [SwrveSDK sharedInstanceWithAppID:1030 apiKey:@"Key" config:config];
    Swrve *swrve = [SwrveSDK sharedInstance];
    swrve.batchURL = [NSURL URLWithString:@"200"];

    swrve.profileManager.identityURL = [NSURL URLWithString:@"500"];

    // Queue event before identify , event sending is set to succeed with a 200 so this should not end up in cache or buffer
    [swrve event:@"Event 1"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Swrve user id should stay as SomeUserID"];
    [swrve identify:@"User1" onSuccess:^(NSString *status, NSString *swrveUserId) {

    } onError:^(NSInteger httpCode, NSString *errorMessage) {
        // swrve user id and event file should not of changed
        NSString *initialEventFilename = [someInitialUserId stringByAppendingString:@"swrve_events.txt"];
        XCTAssertTrue([[swrve.eventFilename.absoluteString lastPathComponent] isEqualToString:initialEventFilename],@"Value: %@",[swrve.eventFilename.absoluteString lastPathComponent]);
        XCTAssertTrue([swrve.userID isEqualToString:someInitialUserId],@"Value: %@", swrve.userID);
        XCTAssertTrue([[SwrveLocalStorage swrveUserId] isEqualToString:someInitialUserId],@"Value: %@", [SwrveLocalStorage swrveUserId]);

        NSArray * eventsBuffer = [swrve eventBuffer];
        XCTAssertTrue([eventsBuffer count] == 0,@"Value: %lu", (unsigned long)[eventsBuffer count]);

        NSString *eventCacheContents = [SwrveTestHelper fileContentsFromURL:[swrve eventFilename]];
        XCTAssertTrue([eventCacheContents isEqualToString:@""],@"Value: %@", eventCacheContents);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:20 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];

    //=================================================================================

    // Try again , with different user
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"Swrve user id should be a new GUID"];
    [swrve identify:@"User2" onSuccess:^(NSString *status, NSString *swrveUserId) {

    } onError:^(NSInteger httpCode, NSString *errorMessage) {

        // swrve user id and event file should be under new GUID and not the initial SomeUserID

        NSString *currentSwrveUserID = [swrve userID];
        XCTAssertTrue((bool)[[NSUUID alloc] initWithUUIDString:currentSwrveUserID]);

        NSString *initialEventFilename = [someInitialUserId stringByAppendingString:@"swrve_events.txt"];
        XCTAssertTrue(![[swrve.eventFilename.absoluteString lastPathComponent] isEqualToString:initialEventFilename],@"Value: %@",[swrve.eventFilename.absoluteString lastPathComponent]  );
        XCTAssertTrue(![swrve.userID isEqualToString:someInitialUserId],@"Value: %@", swrve.userID);
        XCTAssertTrue(![[SwrveLocalStorage swrveUserId] isEqualToString:someInitialUserId],@"Value: %@", [SwrveLocalStorage swrveUserId]);

        NSArray * eventsBuffer = [swrve eventBuffer];
        XCTAssertTrue([eventsBuffer count] == 0,@"Value: %lu", (unsigned long)[eventsBuffer count]);

        NSString *eventCacheContents = [SwrveTestHelper fileContentsFromURL:[swrve eventFilename]];
        XCTAssertTrue([eventCacheContents isEqualToString:@""],@"Value: %@", eventCacheContents);

        [expectation2 fulfill];
    }];

    [self waitForExpectationsWithTimeout:20.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];
}

- (void)testIdentify_Flush_Events_Succeeds_Switching_Users_Succeeds {
    NSString *someInitialUserId = @"SwrveUser1";
    [SwrveTestHelper setAlreadyInstalledUserId:someInitialUserId];

    SwrveUser *verifiedUser = [[SwrveUser alloc] initWithExternalId:@"User1" swrveId:@"SwrveUser1" verified:true];
    SwrveProfileManager *profileManager = [[SwrveProfileManager alloc] init];
    [profileManager saveSwrveUser:verifiedUser];

    SwrveConfig *config = [[SwrveConfig alloc] init];
    [config setAutoDownloadCampaignsAndResources:NO];

    [SwrveSDK sharedInstanceWithAppID:1030 apiKey:@"Key" config:config];
    Swrve *swrve = [SwrveSDK sharedInstance];
    swrve.batchURL = [NSURL URLWithString:@"200"];

    swrve.profileManager.identityURL = [NSURL URLWithString:@"User2"]; // will return SwrveUser2

    // Queue event before identify, This event should be sent under SwrveUser1
    [swrve event:@"Event 1"];

    XCTestExpectation *expectation1 = [self expectationWithDescription:@"SwrveUser2 loaded"];
    [swrve identify:@"User2" onSuccess:^(NSString *status, NSString *swrveUserId) {

        XCTAssertTrue([swrve.userID isEqualToString:@"SwrveUser2"],@"Value: %@", swrve.userID);
        XCTAssertTrue([[SwrveLocalStorage swrveUserId] isEqualToString:@"SwrveUser2"],@"Value: %@", [SwrveLocalStorage swrveUserId]);

        NSArray * eventsBuffer = [swrve eventBuffer];
        XCTAssertTrue([eventsBuffer count] == 0,@"Value: %lu", (unsigned long)[eventsBuffer count]);

        NSString *eventCacheContents = [SwrveTestHelper fileContentsFromURL:[swrve eventFilename]];
        XCTAssertTrue([eventCacheContents isEqualToString:@""],@"Value: %@", eventCacheContents);

        NSString  *expectedResourceFile = [swrve.resourcesFile.filename.absoluteString lastPathComponent];
        NSString  *expectedResourceDiffFile = [swrve.resourcesDiffFile.filename.absoluteString lastPathComponent];
        NSString  *expectedCampaignFile = [swrve.messaging.campaignFile.filename.absoluteString lastPathComponent];
        NSString  *expectedEventFile = [swrve.eventFilename.absoluteString lastPathComponent];

        XCTAssertTrue([expectedResourceFile isEqualToString:@"SwrveUser2srcngt2.txt"],@"Value: %@", expectedResourceFile);
        XCTAssertTrue([expectedResourceDiffFile isEqualToString:@"SwrveUser2rsdfngt2.txt"],@"Value: %@", expectedResourceDiffFile);
        XCTAssertTrue([expectedCampaignFile isEqualToString:@"SwrveUser2cmcc2.json"],@"Value: %@", expectedCampaignFile);
        XCTAssertTrue([expectedEventFile isEqualToString:@"SwrveUser2swrve_events.txt"],@"Value: %@", expectedEventFile);

        [expectation1 fulfill];

    } onError:^(NSInteger httpCode, NSString *errorMessage) {

    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];
}

- (void)testIdentify_Flush_Events_Fail_Switching_Users_Fail  {
    NSString *someInitialUserId = @"SomeUserID";
    [SwrveTestHelper setAlreadyInstalledUserId:someInitialUserId];

    SwrveConfig *config = [[SwrveConfig alloc] init];
    [config setAutoDownloadCampaignsAndResources:NO];

    [SwrveSDK sharedInstanceWithAppID:1030 apiKey:@"Key" config:config];
    Swrve *swrve = [SwrveSDK sharedInstance];
    swrve.batchURL = [NSURL URLWithString:@"500"];

    swrve.profileManager.identityURL = [NSURL URLWithString:@"500"];

    // Queue event before identify, event sending is set to fail with a 500 so this should be written to cache.
    [swrve event:@"Event 1"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"UserId should stay as SomeUserID"];
    [swrve identify:@"User1" onSuccess:^(NSString *status, NSString *swrveUserId) {

    } onError:^(NSInteger httpCode, NSString *errorMessage) {

        NSString *expectedEventFilename = [someInitialUserId stringByAppendingString:@"swrve_events.txt"];
        XCTAssertTrue([[swrve.eventFilename.absoluteString lastPathComponent] isEqualToString:expectedEventFilename],@"Value: %@", [swrve.eventFilename.absoluteString lastPathComponent]);
        XCTAssertTrue([swrve.userID isEqualToString:someInitialUserId],@"Value: %@", swrve.userID);
        XCTAssertTrue([[SwrveLocalStorage swrveUserId] isEqualToString:someInitialUserId],@"Value: %@",[SwrveLocalStorage swrveUserId]);

        NSString *eventCacheContents = [SwrveTestHelper fileContentsFromURL:[swrve eventFilename]];
        NSDictionary *dic = [self dicFromCachedContent:eventCacheContents containingValue:@"Event 1"];
        XCTAssertTrue([dic[@"name"] isEqualToString:@"Event 1"]);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];

    //=================================================================================

    XCTestExpectation *expectation2 = [self expectationWithDescription:@"UserId should be differnt"];
    [swrve identify:@"User2" onSuccess:^(NSString *status, NSString *swrveUserId) {

    } onError:^(NSInteger httpCode, NSString *errorMessage) {

        //confirm filenames haven't changed as the call to identify failed
        NSString *initialFilename = [someInitialUserId stringByAppendingString:@"swrve_events.txt"];
        XCTAssertTrue(![[swrve.eventFilename.absoluteString lastPathComponent] isEqualToString:initialFilename],@"Value: %@", [swrve.eventFilename.absoluteString lastPathComponent]);
        XCTAssertTrue(![swrve.userID isEqualToString:someInitialUserId],@"Value: %@", swrve.userID);
        XCTAssertTrue(![[SwrveLocalStorage swrveUserId] isEqualToString:someInitialUserId],@"Value: %@",[SwrveLocalStorage swrveUserId]);

        NSArray * eventsBuffer = [swrve eventBuffer];
        XCTAssertTrue([eventsBuffer count] == 0);

        //confirm that event 1 is not in the current cache
        NSString *eventCacheContents = [SwrveTestHelper fileContentsFromURL:[swrve eventFilename]];
        NSDictionary *dic = [self dicFromCachedContent:eventCacheContents containingValue:@"Event 1"];
        XCTAssertFalse([dic[@"name"] isEqualToString:@"Event 1"]);

        //confirm that event 1 is in the cache for User1
        NSString* user1EventCache = [SwrveLocalStorage eventsFilePathForUserId:@"SomeUserID"];
        eventCacheContents = [SwrveTestHelper fileContentsFromURL:[NSURL fileURLWithPath:user1EventCache]];
        dic = [self dicFromCachedContent:eventCacheContents containingValue:@"Event 1"];
        XCTAssertTrue([dic[@"name"] isEqualToString:@"Event 1"]);

        [expectation2 fulfill];
    }];

    [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];

    //=================================================================================

    //Retry User1

    XCTestExpectation *expectation3 = [self expectationWithDescription:@"UserId should be SomeUserID"];
    [swrve identify:@"User1" onSuccess:^(NSString *status, NSString *swrveUserId) {

    } onError:^(NSInteger httpCode, NSString *errorMessage) {

        NSString *expectedEventFilename = [someInitialUserId stringByAppendingString:@"swrve_events.txt"];
        XCTAssertTrue([[swrve.eventFilename.absoluteString lastPathComponent] isEqualToString:expectedEventFilename],@"Value: %@", [swrve.eventFilename.absoluteString lastPathComponent]);
        XCTAssertTrue([swrve.userID isEqualToString:someInitialUserId],@"Value: %@", swrve.userID);
        XCTAssertTrue([[SwrveLocalStorage swrveUserId] isEqualToString:someInitialUserId],@"Value: %@",[SwrveLocalStorage swrveUserId]);

        NSArray * eventsBuffer = [swrve eventBuffer];
        XCTAssertTrue([eventsBuffer count] == 0,@"Value: %lu",(unsigned long)[eventsBuffer count]);

        NSString *eventCacheContents = [SwrveTestHelper fileContentsFromURL:[swrve eventFilename]];
        NSDictionary *dic = [self dicFromCachedContent:eventCacheContents containingValue:@"Event 1"];
        XCTAssertTrue([dic[@"name"] isEqualToString:@"Event 1"],@"Value: %@", dic[@"name"]);

        [expectation3 fulfill];
    }];

    [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];
}

- (void)testIdentify_Flush_Events_Fail_Switching_User_Succeeds {
    NSString *someInitialUserId = @"SwrveUser1";
    [SwrveTestHelper setAlreadyInstalledUserId:someInitialUserId];

    SwrveUser *verifiedUser = [[SwrveUser alloc] initWithExternalId:@"User1" swrveId:@"SwrveUser1" verified:true];
    SwrveProfileManager *profileManager = [[SwrveProfileManager alloc] init];
    [profileManager saveSwrveUser:verifiedUser];

    SwrveConfig *config = [[SwrveConfig alloc] init];
    [config setAutoDownloadCampaignsAndResources:NO];

    [SwrveSDK sharedInstanceWithAppID:1030 apiKey:@"Key" config:config];
    Swrve *swrve = [SwrveSDK sharedInstance];
    swrve.batchURL = [NSURL URLWithString:@"500"];

    swrve.profileManager.identityURL = [NSURL URLWithString:@"User2"]; // will return SwrveUser2

    // Queue event before identify , event sending is set to fail with a 500 so this should be written to cache.
    [swrve event:@"Event 1"];

    XCTestExpectation *expectation1 = [self expectationWithDescription:@"Swrve User2 loaded"];
    [swrve identify:@"User2" onSuccess:^(NSString *status, NSString *swrveUserId) {

        NSString  *expectedResourceFile = [swrve.resourcesFile.filename.absoluteString lastPathComponent];
        NSString  *expectedResourceDiffFile = [swrve.resourcesDiffFile.filename.absoluteString lastPathComponent];
        NSString  *expectedCampaignFile = [swrve.messaging.campaignFile.filename.absoluteString lastPathComponent];
        NSString  *expectedEventFile = [swrve.eventFilename.absoluteString lastPathComponent];

        XCTAssertTrue([expectedResourceFile isEqualToString:@"SwrveUser2srcngt2.txt"],@"Value: %@", expectedResourceFile);
        XCTAssertTrue([expectedResourceDiffFile isEqualToString:@"SwrveUser2rsdfngt2.txt"],@"Value: %@", expectedResourceDiffFile);
        XCTAssertTrue([expectedCampaignFile isEqualToString:@"SwrveUser2cmcc2.json"],@"Value: %@", expectedCampaignFile);
        XCTAssertTrue([expectedEventFile isEqualToString:@"SwrveUser2swrve_events.txt"],@"Value: %@", expectedEventFile);

        [expectation1 fulfill];

    } onError:^(NSInteger httpCode, NSString *errorMessage) {

    }];

    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];
}

- (void)testEndpoint {
    SwrveConfig *config = [[SwrveConfig alloc] init];
    [config setAutoDownloadCampaignsAndResources:NO];

    [SwrveSDK sharedInstanceWithAppID:1030 apiKey:@"Key" config:config];
    Swrve *swrve = [SwrveSDK sharedInstance];

    XCTAssertTrue([swrve.profileManager.identityURL.absoluteString isEqualToString:@"https://1030.identity.swrve.com"]);
}

- (void)testIdentify_SwrveUser_Cache_Object_Updated {
    SwrveConfig *config = [[SwrveConfig alloc] init];
    [config setAutoDownloadCampaignsAndResources:NO];

    [SwrveSDK sharedInstanceWithAppID:1030 apiKey:@"Key" config:config];
    Swrve *swrve = [SwrveSDK sharedInstance];

    // fail identify (SwrveUser will be saved to cache)
    swrve.profileManager.identityURL = [NSURL URLWithString:@"500"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Attempt Identify"];
    [swrve identify:@"User1" onSuccess:^(NSString *status, NSString *swrveUserId) {

    } onError:^(NSInteger httpCode, NSString *errorMessage) {
         [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];

    // check details of this SwrveUser in Cache
    SwrveUser *swrveUser = [swrve.profileManager swrveUserWithId:[swrve userID]];

    XCTAssert([swrveUser.swrveId isEqualToString:[swrve userID]]); // UUID
    XCTAssert([swrveUser.externalId isEqualToString:@"User1"]);
    XCTAssertFalse(swrveUser.verified);

    // set identify call to succeed
    swrve.profileManager.identityURL = [NSURL URLWithString:@"User1"];

    // identify again, it should succeed this time
    expectation = [self expectationWithDescription:@"User id changed to SwrveUser1"];
    [swrve identify:@"User1" onSuccess:^(NSString *status, NSString *swrveUserId) {
        // confirm this SwrveUser details in cache have been updated
        SwrveUser *swrveUser = [swrve.profileManager swrveUserWithId:@"User1"];
        XCTAssert([swrveUser.swrveId isEqualToString:@"SwrveUser1"]);
        XCTAssert([swrveUser.externalId isEqualToString:@"User1"]);
        XCTAssertTrue(swrveUser.verified);

        [expectation fulfill];
    } onError:^(NSInteger httpCode, NSString *errorMessage) {

    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];
}

- (void)testIdentify_Forbidden_Email {
    SwrveConfig *config = [[SwrveConfig alloc] init];
    [config setAutoDownloadCampaignsAndResources:NO];

    [SwrveSDK sharedInstanceWithAppID:1030 apiKey:@"Key" config:config];
    Swrve *swrve = [SwrveSDK sharedInstance];

    //set identify call to fail with forbidden 403
    swrve.profileManager.identityURL = [NSURL URLWithString:@"Email"];
    NSString *userId = [swrve userID];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Email forbidden"];
    [swrve identify:@"k@b.com" onSuccess:^(NSString *status, NSString *swrveUserId) {

    } onError:^(NSInteger httpCode, NSString *errorMessage) {
        XCTAssertTrue([[swrve.profileManager swrveUsers] count] == 0);
        //user id should not have changed
        XCTAssertTrue([swrve.profileManager.userId isEqualToString:userId]);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];

    //set identify call to succeed
    swrve.profileManager.identityURL = [NSURL URLWithString:@"ReturnSameUserId"];

    expectation = [self expectationWithDescription:@"Change user"];
    [swrve identify:@"User1" onSuccess:^(NSString *status, NSString *swrveUserId) {
        XCTAssertTrue([[swrve.profileManager swrveUsers] count] == 1);
        //user id should not have changed
        XCTAssertTrue([swrve.profileManager.userId isEqualToString:userId]);
        [expectation fulfill];
    } onError:^(NSInteger httpCode, NSString *errorMessage) {

    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];

    //set identify call to fail again with forbidden 403
    swrve.profileManager.identityURL = [NSURL URLWithString:@"Email"];
    userId = [swrve userID];

    expectation = [self expectationWithDescription:@"Email forbidden"];
    [swrve identify:@"k@b2.com" onSuccess:^(NSString *status, NSString *swrveUserId) {

    } onError:^(NSInteger httpCode, NSString *errorMessage) {
        XCTAssertTrue([[swrve.profileManager swrveUsers] count] == 1);
        //user id should change
        XCTAssertFalse([swrve.profileManager.userId isEqualToString:userId]);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];
}

- (void)testIdentify_EnableEventSending_AppDidBecomeActive {
    SwrveConfig *config = [[SwrveConfig alloc] init];
    [config setAutoDownloadCampaignsAndResources:NO];

    [SwrveSDK sharedInstanceWithAppID:1030 apiKey:@"Key" config:config];
    Swrve *swrve = [SwrveSDK sharedInstance];
    SwrveProfileManager *profileManager = [swrve profileManager];
    [swrve pauseEventSending];
    enum SwrveTrackingState trackingState = [profileManager trackingState];
    XCTAssertTrue(trackingState == EVENT_SENDING_PAUSED);
    [swrve appDidBecomeActive:nil];
    trackingState = [profileManager trackingState];
    XCTAssertTrue(trackingState == STARTED);
}

- (void)testQueuePausedEventsIsTheadSafe {
    SwrveConfig *config = [[SwrveConfig alloc] init];
    [config setAutoDownloadCampaignsAndResources:NO];
    [SwrveSDK sharedInstanceWithAppID:1 apiKey:@"Key" config:config];
    Swrve *swrve = [SwrveSDK sharedInstance];
    [swrve pauseEventSending];

    XCTestExpectation *expectation1 = [self expectationWithDescription:@"swrve.pausedEventsArray didn't work as it should"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"queuePausedEventsArray didn't work as it should"];

    // Force add assync few events into our pausedEventsArray.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (int i=0; i<1000; i++) {
            NSString *eventname = [NSString stringWithFormat:@"event %d",i];
            [swrve queueEvent:eventname data:[@{@"Event":@"whatever"} mutableCopy] triggerCallback:false notifyMessageController:false];
        }
        [expectation1 fulfill];
    });

    // At same time we do try purge then and if isn't thread safe it would cause a run time exception.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (int i=0; i<1000; i++) {
            [swrve queuePausedEventsArray];
        }
        [expectation2 fulfill];
    });

    [self waitForExpectations:@[expectation1, expectation2] timeout:10 enforceOrder: NO];
}

- (void)testMigrationOfSwrveInstallDate {
    //setup install time pre migration , data saved in file with user id appended eg 'XXXXXswrve.install_date'
    NSString *someInitialUserId = @"SomeUserID";
    [SwrveLocalStorage saveSwrveUserId:someInitialUserId];
    [SwrveLocalStorage saveUserJoinedTime:1234567889 forUserId:someInitialUserId];

    //confirm there is no install date saved without user id
    UInt64 installDate = [SwrveLocalStorage userJoinedTimeSeconds:@""];
    XCTAssertTrue(installDate == 0);

    SwrveMigrationsManager *migrationsManager = [[SwrveMigrationsManager alloc] initWithConfig:[ImmutableSwrveConfig new]];
    [SwrveMigrationsManager setCurrentCacheVersion:0];
    [migrationsManager checkMigrations];
    //migration should of been called and moved the installDate to file 'swrve.install_date'
    installDate = [SwrveLocalStorage userJoinedTimeSeconds:@""];
    XCTAssertTrue(installDate == 1234567889);

    //confirm install time is still saved for that user
    installDate = [SwrveLocalStorage userJoinedTimeSeconds:@"SomeUserID"];
    XCTAssertTrue(installDate == 1234567889);
}

- (void)testIdentify_InstallDate_SamePerUser_UserInitDate_DifferentPerUser {
    SwrveConfig* config = [[SwrveConfig alloc] init];
    [config setAutoDownloadCampaignsAndResources:NO];
    [SwrveSDK sharedInstanceWithAppID:1030 apiKey:@"Key" config:config];
    Swrve *swrve = [SwrveSDK sharedInstance];

    UInt64 installTimeSecondsInStorgage = [SwrveLocalStorage userJoinedTimeSeconds:@""];
    XCTAssertFalse(installTimeSecondsInStorgage == 0);

    NSNumber *installTimeSecondsIvar = (NSNumber *)[swrve valueForKey:@"appInstallTimeSeconds"];

    swrve.profileManager.identityURL = [NSURL URLWithString:@"User1"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Attempt Identify"];
    [swrve identify:@"User1" onSuccess:^(NSString *status, NSString *swrveUserId) {
        [self checkCorrectInstallAndUserInitTimes:swrve installTime:[installTimeSecondsIvar longValue]];
        [expectation fulfill];
    } onError:^(NSInteger httpCode, NSString *errorMessage) {

    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];

    swrve.profileManager.identityURL = [NSURL URLWithString:@"User2"];
    expectation = [self expectationWithDescription:@"Attempt Identify"];
    [swrve identify:@"User2" onSuccess:^(NSString *status, NSString *swrveUserId) {
        [self checkCorrectInstallAndUserInitTimes:swrve installTime:[installTimeSecondsIvar longValue]];
        [expectation fulfill];
    } onError:^(NSInteger httpCode, NSString *errorMessage) {

    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];

    //switch back to use 1 and confirm install time is still the same
    swrve.profileManager.identityURL = [NSURL URLWithString:@"User1"];
    expectation = [self expectationWithDescription:@"Attempt Identify"];
    [swrve identify:@"User1" onSuccess:^(NSString *status, NSString *swrveUserId) {
        [self checkCorrectInstallAndUserInitTimes:swrve installTime:[installTimeSecondsIvar longValue]];
        [expectation fulfill];
    } onError:^(NSInteger httpCode, NSString *errorMessage) {

    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];
}

-(void)checkCorrectInstallAndUserInitTimes:(Swrve *)swrve  installTime:(long)installTimeSeconds {
    //private ivar , can access with KVC
    XCTAssertTrue(installTimeSeconds == [SwrveLocalStorage userJoinedTimeSeconds:@""]);
    NSNumber *userInitTimeSeconds = (NSNumber *)[swrve valueForKey:@"userJoinedTimeSeconds"];
    XCTAssertTrue([userInitTimeSeconds longValue] == (long) [SwrveLocalStorage userJoinedTimeSeconds:swrve.userID]);
}

- (void)testSendQueuedEventsWithCallback_UserIdNil {
    SwrveConfig* config = [[SwrveConfig alloc] init];
    [config setAutoDownloadCampaignsAndResources:NO];
    [SwrveSDK sharedInstanceWithAppID:1030 apiKey:@"Key" config:config];
    Swrve *swrve = [SwrveSDK sharedInstance];

    id profileManagerPartialMock = OCMPartialMock(swrve.profileManager);
    OCMStub([profileManagerPartialMock userId]).andReturn(nil);
    swrve.profileManager = profileManagerPartialMock; // this should never be the case
    [swrve sendQueuedEventsWithCallback:nil eventFileCallback:nil];
    //if here the method has correctly returned early and hasn't crashed.
}

- (void)testIdentify_With_Nil_ExternalId {
    // Test:  Anonymous -> Identify New User
    // Confirm no change if nil or empty
    //====================================

    //setup a verfired user
    NSString *someInitialUserId = @"SwrveUser1";
    [SwrveTestHelper setAlreadyInstalledUserId:someInitialUserId];
    SwrveUser *verifiedUser = [[SwrveUser alloc] initWithExternalId:@"User1" swrveId:@"SwrveUser1" verified:true];
    SwrveProfileManager *profileManager = [[SwrveProfileManager alloc] init];
    [profileManager saveSwrveUser:verifiedUser];

    SwrveConfig *config = [[SwrveConfig alloc] init];
    [config setAutoDownloadCampaignsAndResources:NO];

    [SwrveSDK sharedInstanceWithAppID:1030 apiKey:@"Key" config:config];
    Swrve *swrve = [SwrveSDK sharedInstance];

    //====================================

    XCTestExpectation *expectation = [self expectationWithDescription:@"Anonymous"];
    NSString *swrveUserIdBeforIdentityCall = swrve.userID;
    [swrve identify:nil onSuccess:nil onError:^(NSInteger httpCode, NSString *errorMessage) {
        // no change
        XCTAssertTrue([[swrve.profileManager swrveUsers] count] == 1);
        XCTAssertTrue([swrve.userID isEqualToString:swrveUserIdBeforIdentityCall]);

        XCTAssertTrue(httpCode == -1);
        XCTAssertEqualObjects(errorMessage,@"External user id cannot be nil or empty");
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];

    //====================================

    expectation = [self expectationWithDescription:@"New User"];
    swrveUserIdBeforIdentityCall = swrve.userID;
    swrve.profileManager.identityURL = [NSURL URLWithString:@"ReturnSameUserId"];
    [swrve identify:@"ReturnSameUserId" onSuccess:^(NSString *status, NSString *swrveUserId) {
        // should be new swrve id
        XCTAssertTrue(![swrve.userID isEqualToString:swrveUserIdBeforIdentityCall]);
        XCTAssertTrue([[swrve.profileManager swrveUsers] count] == 2);
        [expectation fulfill];
    } onError:nil];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testIdentify_GetExternalId {
    SwrveConfig* config = [[SwrveConfig alloc] init];
    [config setAutoDownloadCampaignsAndResources:NO];
    [SwrveSDK sharedInstanceWithAppID:1030 apiKey:@"Key" config:config];
    Swrve *swrve = [SwrveSDK sharedInstance];

    XCTAssertEqualObjects(@"", [SwrveSDK externalUserId]);

    swrve.profileManager.identityURL = [NSURL URLWithString:@"User1"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"User 1"];
    [swrve identify:@"User1" onSuccess:^(NSString *status, NSString *swrveUserId) {

        XCTAssertEqualObjects(@"User1", [SwrveSDK externalUserId]);
        [expectation fulfill];

    } onError:nil];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];

    swrve.profileManager.identityURL = [NSURL URLWithString:@"User2"];
    expectation = [self expectationWithDescription:@"User 2"];
    [swrve identify:@"User2" onSuccess:^(NSString *status, NSString *swrveUserId) {

        XCTAssertEqualObjects(@"User2", [SwrveSDK externalUserId]);
        [expectation fulfill];

    } onError:nil];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testIdentify_QueueEvent_While_Identify {
    SwrveConfig *config = [[SwrveConfig alloc] init];
    [config setAutoDownloadCampaignsAndResources:NO];
    [SwrveSDK sharedInstanceWithAppID:1030 apiKey:@"Key" config:config];
    Swrve *swrve = [SwrveSDK sharedInstance];

    //====================================
    // Mock stuff.
    swrve.profileManager.identityURL = [NSURL URLWithString:@"QueueEventWhileIdentifying"];

    // pausedEventsArray should be zero to start with and finish with.
    // The SwrveMockNSURLProtocol will check a test event gets added to this array
    XCTAssertTrue([[swrve pausedEventsArray] count] == 0);

    XCTestExpectation *expectation = [self expectationWithDescription:@"QueueEventWhileIdentifying"];
    [swrve identify:@"RandomUserId" onSuccess:^(NSString *status, NSString *swrveUserId) {
        XCTAssertTrue([[swrve pausedEventsArray] count] == 0);
        [expectation fulfill];
    }       onError:nil];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testIdentify_QueueEvent_While_IdentifyWith500Error {

    [NSURLProtocol registerClass:[SwrveMockNSURLProtocol class]];

    // Init SDK.
    SwrveConfig *config = [[SwrveConfig alloc] init];
    [config setAutoDownloadCampaignsAndResources:NO];
    [SwrveSDK sharedInstanceWithAppID:1030 apiKey:@"Key" config:config];
    Swrve *swrve = [SwrveSDK sharedInstance];

    //====================================
    // Mock stuff.
    swrve.profileManager.identityURL = [NSURL URLWithString:@"Queue500EventWhileIdentifying"];

    // pausedEventsArray should be zero to start with and finish with.
    // The SwrveMockNSURLProtocol will check a test event gets added to this array
    XCTAssertTrue([[swrve pausedEventsArray] count] == 0);

    XCTestExpectation *expectation = [self expectationWithDescription:@"Queue500EventWhileIdentifying"];
    [swrve identify:@"RandomUserId" onSuccess:^(NSString *status, NSString *swrveUserId) {

        XCTFail(@"This test should not successfully identify.");
    } onError:^(NSInteger httpCode, NSString *errorMessage) {

        XCTAssertTrue([[swrve pausedEventsArray] count] == 0);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testIdentify_MaybeFlush_EventSendingPaused {
    SwrveConfig *config = [[SwrveConfig alloc] init];
    [config setAutoDownloadCampaignsAndResources:NO];
    [SwrveSDK sharedInstanceWithAppID:1030 apiKey:@"Key" config:config];
    Swrve *swrve = [SwrveSDK sharedInstance];

    [swrve event:@"TestEvent"];
    [swrve pauseEventSending];
    swrve.eventBufferBytes  = KB(500);
    [swrve maybeFlushToDisk];

    NSArray *eventsBuffer = [swrve eventBuffer];
    XCTAssertTrue([eventsBuffer count] == 1);
}

- (void)testIdentify_AfterCall_Event_Queuing_Unpaused {
    SwrveConfig *config = [[SwrveConfig alloc] init];
    [config setAutoDownloadCampaignsAndResources:NO];
    [SwrveSDK sharedInstanceWithAppID:1030 apiKey:@"Key" config:config];
    Swrve *swrve = [SwrveSDK sharedInstance];

    XCTestExpectation *expectation = [self expectationWithDescription:@"RandomUserId"];
    [swrve identify:@"RandomUserId" onSuccess:^(NSString *status, NSString *swrveUserId) {
        [expectation fulfill];
    } onError:nil];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];

    [swrve event:@"TestEvent"];
    [self assertEvent:@"TestEvent" forUserId:swrve.userID existsInBuffer:YES swrve:swrve];
}

- (void)testIdentifyKeepsMessageListeners {
    NSString *someInitialUserId = @"SwrveUser0";
    [SwrveTestHelper setAlreadyInstalledUserId:someInitialUserId];

    SwrveConfig *config = [[SwrveConfig alloc] init];
    [config setAutoDownloadCampaignsAndResources:NO];

    [SwrveSDK sharedInstanceWithAppID:1030 apiKey:@"Key" config:config];
    Swrve *swrve = [SwrveSDK sharedInstance];
    swrve.batchURL = [NSURL URLWithString:@"200"];
    swrve.profileManager.identityURL = [NSURL URLWithString:@"IdentifyBody"];

    XCTestExpectation *bodyExpectation = [self expectationWithDescription:@"IdentifyBody"];
    [swrve identify:@"ExternalID" onSuccess:^(NSString *status, NSString *swrveUserId) {
        [bodyExpectation fulfill];
    } onError:^(NSInteger httpCode, NSString *errorMessage) {

    }];
    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];
}

@end
