#import <XCTest/XCTest.h>
#import "SwrveTestHelper.h"
#import "SwrveMigrationsManager.h"
#import "SwrveRESTClient.h"

@interface Swrve (Internal)
@property(atomic) SwrveRESTClient *restClient;
@property(atomic) SwrveSignatureProtectedFile *resourcesFile;
@property(atomic) SwrveSignatureProtectedFile *resourcesDiffFile;
- (void)appDidBecomeActive:(NSNotification *)notification;
- (void)updateResources:(NSArray *)resourceJson writeToCache:(BOOL)writeToCache;
@end

@interface SwrveMigrationsManager ()
+ (void)markAsMigrated;
@end

@interface SwrveTestUserResources : XCTestCase

@end

@implementation SwrveTestUserResources

- (void)setUp {
    [super setUp];
    [SwrveTestHelper setUp];
}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [super tearDown];
}

/**
 * Test methods in resource manager to retrieve resource attribute values
 * and ensure at startup resources are read from cache file
 */
- (void)testResourceManager {
    NSString *testCacheFileContents = @"[{\"uid\": \"animal.ant\", \"name\": \"ant\", \"cost\": \"5.50\", \"quantity\": \"6\"},{\"uid\": \"animal.bear\",\"name\": \"bear\", \"cost\": \"9.99\",\"quantity\": \"20\"}]";
    
    // Initialise Swrve and write to resources cache file
    Swrve *swrveMock = [SwrveTestHelper swrveMockWithMockedRestClient];
    swrveMock = [swrveMock initWithAppID:572 apiKey:@"SomeAPIKey"];
    [swrveMock appDidBecomeActive:nil];
    [[swrveMock resourcesFile] writeWithRespectToPlatform:[testCacheFileContents dataUsingEncoding:NSUTF8StringEncoding]];
    [SwrveMigrationsManager markAsMigrated];
    
    // Restart swrve, resource manager will be initialised by contents of cache
    // Getting resources periodically from API will fail (invalid api key) so will keep using cached contents
    [swrveMock shutdown];
    swrveMock = [SwrveTestHelper swrveMockWithMockedRestClient];
    SwrveConfig *config = [[SwrveConfig alloc] init];
    __block int callbackCounter = 0;
    config.resourcesUpdatedCallback = ^() {
        // Callback functionality
        callbackCounter++;
    };
    swrveMock = [swrveMock initWithAppID:572 apiKey:@"SomeAPIKey" config:config]; // callbackCounter will increment once
    [swrveMock appDidBecomeActive:nil]; // callbackCounter will increment once

    // Get the Swrve Resource Manager and check its contents
    SwrveResourceManager *resourceManager = [swrveMock resourceManager];

    XCTAssertEqual(2, [[resourceManager resources] count]);

    XCTAssertNotNil([resourceManager resourceWithId:@"animal.ant"]);
    XCTAssertEqualObjects([resourceManager attributeAsString:@"name" fromResourceWithId:@"animal.ant" withDefault:@"anonymous"], @"ant");
    XCTAssertEqual([resourceManager attributeAsFloat:@"cost" fromResourceWithId:@"animal.ant" withDefault:0], 5.50);
    XCTAssertEqual([resourceManager attributeAsInt:@"quantity" fromResourceWithId:@"animal.ant" withDefault:0], 6);

    XCTAssertNotNil([resourceManager resourceWithId:@"animal.bear"]);
    XCTAssertEqualObjects([resourceManager attributeAsString:@"name" fromResourceWithId:@"animal.bear" withDefault:@"anonymous"], @"bear");
    //XCTAssertEqual([resourceManager attributeAsFloat:@"cost" fromResourceWithId:@"animal.bear" withDefault:0], 9.99f, FLT_EPSILON, @"");
    XCTAssertEqual([resourceManager attributeAsFloat:@"cost" fromResourceWithId:@"animal.bear" withDefault:0], 9.99f);
    XCTAssertEqual([resourceManager attributeAsInt:@"quantity" fromResourceWithId:@"animal.bear" withDefault:0], 20);

    // Overwrite content of resource manager manually as if data was received from API and check content has been updated
    NSDictionary *resourceExample = @{@"uid": @"animal.zebra",
            @"cost": @4.99,
            @"tail": @"YES",
            @"purchased": @"NO"};

    NSArray *resourcesExample = [NSArray arrayWithObjects:resourceExample, nil];

    [swrveMock updateResources:resourcesExample writeToCache:YES];
    XCTAssertEqual(1, [[resourceManager resources] count]);

    SwrveResource *resource = [resourceManager resourceWithId:@"animal.zebra"];
    XCTAssertNotNil(resource);

    XCTAssertEqual([resource attributeAsString:@"uid" withDefault:@"none"], @"animal.zebra");
    XCTAssertEqual([resource attributeAsFloat:@"cost" withDefault:0], 4.99f);
    XCTAssertTrue([resource attributeAsBool:@"tail" withDefault:NO]);
    XCTAssertFalse([resource attributeAsBool:@"purchased" withDefault:YES]);
    
    XCTAssertEqual(callbackCounter, 2);
    [swrveMock refreshCampaignsAndResources];
    XCTAssertEqual(callbackCounter, 2); // callback should not be called again because the flag campaignsAndResourcesInitialized prevents it. 
}

- (void)testGetUserResourcesCallback {
    NSString *testCacheFileContents = @"[{\"uid\": \"animal.ant\", \"name\": \"ant\", \"cost\": \"550\", \"cost_type\": \"gold\"},{\"uid\": \"animal.bear\",\"name\": \"bear\", \"cost\": \"999\",\"cost_type\": \"gold\"}]";
    // Initialise Swrve and write to resources cache file
    Swrve *swrveMock = [SwrveTestHelper swrveMockWithMockedRestClient];
    swrveMock = [swrveMock initWithAppID:572 apiKey:@"SomeAPIKey"];
    [swrveMock appDidBecomeActive:nil];
    [[swrveMock resourcesFile] writeWithRespectToPlatform:[testCacheFileContents dataUsingEncoding:NSUTF8StringEncoding]];
    [SwrveMigrationsManager markAsMigrated];

    // Restart swrve, getting resources from API will fail, so resources initialised by cache
    [swrveMock shutdown];
    swrveMock = [SwrveTestHelper swrveMockWithMockedRestClient];
    swrveMock = [swrveMock initWithAppID:572 apiKey:@"SomeAPIKey"];
    [swrveMock appDidBecomeActive:nil];
    
    // Ensure that the sdk has all the necessary items in place before running the callback test
    XCTestExpectation *expectation = [self expectationWithDescription:@"sdk has succesfully started"];
    [SwrveTestHelper waitForBlock:0.05 conditionBlock:^BOOL(){
        return ([swrveMock started] && [swrveMock resourcesFile] && [swrveMock resourcesDiffFile]);
    } expectation:expectation];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];

    BOOL __block calledBack = NO;
    [swrveMock userResources:^(NSDictionary *resources, NSString *resourcesAsJSON) {
        // Check that json parameter has correct content
        NSError *error = nil;
        NSArray *resourcesJsonToDict = [NSJSONSerialization JSONObjectWithData:[resourcesAsJSON dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
        XCTAssertNil(error);
        XCTAssertNotNil(resourcesJsonToDict);
        XCTAssertEqual(2, [resourcesJsonToDict count]);

        for (NSDictionary *dict in resourcesJsonToDict) {
            if ([[dict objectForKey:@"uid"] isEqualToString:@"animal.ant"]) {
                XCTAssertNotNil([dict objectForKey:@"cost"]);
                XCTAssertEqualObjects([dict objectForKey:@"cost"], @"550");
                XCTAssertNotNil([dict objectForKey:@"cost_type"]);
                XCTAssertEqualObjects([dict objectForKey:@"cost_type"], @"gold");
                XCTAssertNotNil([dict objectForKey:@"name"]);
                XCTAssertEqualObjects([dict objectForKey:@"name"], @"ant");
                XCTAssertNotNil([dict objectForKey:@"uid"]);
                XCTAssertEqualObjects([dict objectForKey:@"uid"], @"animal.ant");
            } else {
                XCTAssertNotNil([dict objectForKey:@"cost"]);
                XCTAssertEqualObjects([dict objectForKey:@"cost"], @"999");
                XCTAssertNotNil([dict objectForKey:@"cost_type"]);
                XCTAssertEqualObjects([dict objectForKey:@"cost_type"], @"gold");
                XCTAssertNotNil([dict objectForKey:@"name"]);
                XCTAssertEqualObjects([dict objectForKey:@"name"], @"bear");
                XCTAssertNotNil([dict objectForKey:@"uid"]);
                XCTAssertEqualObjects([dict objectForKey:@"uid"], @"animal.bear");
            }
        }

        // Check that dictionary has correct content
        XCTAssertNotNil(resources);
        XCTAssertEqual(2, [resources count]);
        XCTAssertNotNil([resources objectForKey:@"animal.ant"]);
        XCTAssertNotNil([resources objectForKey:@"animal.bear"]);

        NSDictionary *ant = [resources objectForKey:@"animal.ant"];
        XCTAssertNotNil([ant objectForKey:@"cost"]);
        XCTAssertEqualObjects([ant objectForKey:@"cost"], @"550");
        XCTAssertNotNil([ant objectForKey:@"cost_type"]);
        XCTAssertEqualObjects([ant objectForKey:@"cost_type"], @"gold");
        XCTAssertNotNil([ant objectForKey:@"name"]);
        XCTAssertEqualObjects([ant objectForKey:@"name"], @"ant");
        XCTAssertNotNil([ant objectForKey:@"uid"]);
        XCTAssertEqualObjects([ant objectForKey:@"uid"], @"animal.ant");

        NSDictionary *bear = [resources objectForKey:@"animal.bear"];
        XCTAssertNotNil([bear objectForKey:@"cost"]);
        XCTAssertEqualObjects([bear objectForKey:@"cost"], @"999");
        XCTAssertNotNil([bear objectForKey:@"cost_type"]);
        XCTAssertEqualObjects([bear objectForKey:@"cost_type"], @"gold");
        XCTAssertNotNil([bear objectForKey:@"name"]);
        XCTAssertEqualObjects([bear objectForKey:@"name"], @"bear");
        XCTAssertNotNil([bear objectForKey:@"uid"]);
        XCTAssertEqualObjects([bear objectForKey:@"uid"], @"animal.bear");

        calledBack = YES;
    }];

    // Run the main run loop to allow Swrve object to process callbacks
    NSDate *futureTime = [NSDate dateWithTimeIntervalSinceNow:5];
    while (true) {
        if ((calledBack == YES) ||
                ([[NSDate date] compare:futureTime] == NSOrderedDescending)) {
            break;
        }
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:futureTime];
    }

    // Check callback was called
    XCTAssertTrue(calledBack);
}

- (void)testGetUserResourcesDiffCallback {
    NSString *__block testCacheFileContents = @"[{ \"uid\": \"animal.ant\", \"diff\": { \"cost\": { \"old\": \"550\", \"new\": \"666\" }}}, { \"uid\": \"animal.bear\", \"diff\": { \"level\": { \"old\": \"10\", \"new\": \"9000\" }}}]";

    // Initialise Swrve and write to resources diff cache file
    NSData *mockData = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];
    Swrve *swrveMock = [SwrveTestHelper swrveMockWithMockedRestClientResponseCode:500 mockData:mockData];
    swrveMock = [swrveMock initWithAppID:572 apiKey:@"SomeAPIKey"];
    [swrveMock appDidBecomeActive:nil];
    [[swrveMock resourcesDiffFile] writeWithRespectToPlatform:[testCacheFileContents dataUsingEncoding:NSUTF8StringEncoding]];
    [[swrveMock resourcesFile] writeWithRespectToPlatform:[testCacheFileContents dataUsingEncoding:NSUTF8StringEncoding]];
    [SwrveMigrationsManager markAsMigrated];

    XCTestExpectation *callback = [self expectationWithDescription:@"callback"];
    // Getting resources diff from API will fail, so resources diff initialised by cache
    [swrveMock userResourcesDiffWithListener:^(NSDictionary *oldResourcesValues, NSDictionary *newResourcesValues, NSString *resourcesAsJSON, BOOL fromServer, NSError *error) {
        XCTAssertEqualObjects(resourcesAsJSON, testCacheFileContents);

        XCTAssertEqual(2, [newResourcesValues count]);
        XCTAssertNotNil([newResourcesValues objectForKey:@"animal.ant"]);
        NSDictionary *newValue1 = [newResourcesValues objectForKey:@"animal.ant"];
        XCTAssertEqualObjects([newValue1 objectForKey:@"cost"], @"666");
        NSDictionary *newValue2 = [newResourcesValues objectForKey:@"animal.bear"];
        XCTAssertEqualObjects([newValue2 objectForKey:@"level"], @"9000");

        XCTAssertEqual(2, [oldResourcesValues count]);
        XCTAssertNotNil([oldResourcesValues objectForKey:@"animal.ant"]);
        NSDictionary *oldValue1 = [oldResourcesValues objectForKey:@"animal.ant"];
        XCTAssertEqualObjects([oldValue1 objectForKey:@"cost"], @"550");
        NSDictionary *oldValue2 = [oldResourcesValues objectForKey:@"animal.bear"];
        XCTAssertEqualObjects([oldValue2 objectForKey:@"level"], @"10");
        [callback fulfill];
    }];

    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"No message shown");
        }
    }];
}

- (void)testUserResourcesDiffListenerWithFalseFromServer {
    NSString *__block testCacheFileContents = @"[{ \"uid\": \"animal.ant\", \"diff\": { \"cost\": { \"old\": \"550\", \"new\": \"666\" }}}, { \"uid\": \"animal.bear\", \"diff\": { \"level\": { \"old\": \"10\", \"new\": \"9000\" }}}]";

    // Initialise Swrve and write to resources diff cache file
    NSData *mockData = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];
    Swrve *swrveMock = [SwrveTestHelper swrveMockWithMockedRestClientResponseCode:500 mockData:mockData];
    swrveMock = [swrveMock initWithAppID:572 apiKey:@"SomeAPIKey"];
    [swrveMock appDidBecomeActive:nil];
    [[swrveMock resourcesDiffFile] writeWithRespectToPlatform:[testCacheFileContents dataUsingEncoding:NSUTF8StringEncoding]];
    [[swrveMock resourcesFile] writeWithRespectToPlatform:[testCacheFileContents dataUsingEncoding:NSUTF8StringEncoding]];
    [SwrveMigrationsManager markAsMigrated];

    XCTestExpectation *callback = [self expectationWithDescription:@"callback"];
    // Getting resources diff from API will fail, so resources diff initialised by cache
    [swrveMock userResourcesDiffWithListener:^(NSDictionary *oldResourcesValues, NSDictionary *newResourcesValues, NSString *resourcesAsJSON, BOOL fromServer, NSError *error) {
        XCTAssertFalse(fromServer);
        XCTAssertNil(error);

        XCTAssertEqualObjects(resourcesAsJSON, testCacheFileContents);

        XCTAssertEqual(2, [newResourcesValues count]);
        XCTAssertNotNil([newResourcesValues objectForKey:@"animal.ant"]);
        NSDictionary *newValue1 = [newResourcesValues objectForKey:@"animal.ant"];
        XCTAssertEqualObjects([newValue1 objectForKey:@"cost"], @"666");
        NSDictionary *newValue2 = [newResourcesValues objectForKey:@"animal.bear"];
        XCTAssertEqualObjects([newValue2 objectForKey:@"level"], @"9000");

        XCTAssertEqual(2, [oldResourcesValues count]);
        XCTAssertNotNil([oldResourcesValues objectForKey:@"animal.ant"]);
        NSDictionary *oldValue1 = [oldResourcesValues objectForKey:@"animal.ant"];
        XCTAssertEqualObjects([oldValue1 objectForKey:@"cost"], @"550");
        NSDictionary *oldValue2 = [oldResourcesValues objectForKey:@"animal.bear"];
        XCTAssertEqualObjects([oldValue2 objectForKey:@"level"], @"10");
        [callback fulfill];
    }];

    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"No message shown");
        }
    }];
}

- (void)testUserResourcesDiffListenerWithCorruptData {
    NSString *__block testCacheFileContents = @"[{ \"corrupt data\": \"corrupt data\"}]";

    // Initialise Swrve and write to resources diff cache file
    NSData *mockData = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];
    Swrve *swrveMock = [SwrveTestHelper swrveMockWithMockedRestClientResponseCode:500 mockData:mockData];
    swrveMock = [swrveMock initWithAppID:572 apiKey:@"SomeAPIKey"];
    [swrveMock appDidBecomeActive:nil];
    [[swrveMock resourcesDiffFile] writeWithRespectToPlatform:[testCacheFileContents dataUsingEncoding:NSUTF8StringEncoding]];
    [[swrveMock resourcesFile] writeWithRespectToPlatform:[testCacheFileContents dataUsingEncoding:NSUTF8StringEncoding]];
    [SwrveMigrationsManager markAsMigrated];

    XCTestExpectation *callback = [self expectationWithDescription:@"callback"];
    // Getting resources diff from API will fail, so resources diff initialised by cache
    [swrveMock userResourcesDiffWithListener:^(NSDictionary *oldResourcesValues, NSDictionary *newResourcesValues, NSString *resourcesAsJSON, BOOL fromServer, NSError *error) {
        XCTAssertFalse(fromServer);
        XCTAssertNotNil(error);
        [callback fulfill];
    }];

    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"No message shown");
        }
    }];
}

- (void)testUserResourcesDiffListenerWithTrueFromServer {

    NSData *mockData = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];
    Swrve *swrveMock = [SwrveTestHelper swrveMockWithMockedRestClientResponseCode:200 mockData:mockData];
    swrveMock = [swrveMock initWithAppID:572 apiKey:@"SomeAPIKey"];
    [swrveMock appDidBecomeActive:nil];

    NSString *__block testCacheFileContents = @"[{ \"uid\": \"animal.ant\", \"diff\": { \"cost\": { \"old\": \"550\", \"new\": \"666\" }}}, { \"uid\": \"animal.bear\", \"diff\": { \"level\": { \"old\": \"10\", \"new\": \"9000\" }}}]";
    [[swrveMock resourcesDiffFile] writeWithRespectToPlatform:[testCacheFileContents dataUsingEncoding:NSUTF8StringEncoding]];
    [[swrveMock resourcesFile] writeWithRespectToPlatform:[testCacheFileContents dataUsingEncoding:NSUTF8StringEncoding]];
    [SwrveMigrationsManager markAsMigrated];

    // mock server content with a new animal.ant difference......666 in cache, but 777 from server
    NSString *__block testServerFileContents = @"[{ \"uid\": \"animal.ant\", \"diff\": { \"cost\": { \"old\": \"550\", \"new\": \"777\" }}}, { \"uid\": \"animal.bear\", \"diff\": { \"level\": { \"old\": \"10\", \"new\": \"9000\" }}}]";
    NSData *userResorcesMockData = [testServerFileContents dataUsingEncoding:NSUTF8StringEncoding];
    SwrveRESTClient *restClient = [[SwrveRESTClient alloc] initWithTimeoutInterval:60];
    id mockRestClient = OCMPartialMock(restClient);
    id mockResponse = OCMClassMock([NSHTTPURLResponse class]);
    OCMStub([mockResponse statusCode]).andReturn(200);
    OCMStub([mockRestClient sendHttpRequest:OCMOCK_ANY completionHandler:([OCMArg invokeBlockWithArgs:mockResponse, userResorcesMockData, [NSNull null], nil])]);
    swrveMock.restClient = mockRestClient;

    XCTestExpectation *callback = [self expectationWithDescription:@"callback"];
    // Getting resources diff from API will fail, so resources diff initialised by cache
    [swrveMock userResourcesDiffWithListener:^(NSDictionary *oldResourcesValues, NSDictionary *newResourcesValues, NSString *resourcesAsJSON, BOOL fromServer, NSError *error) {
        XCTAssertTrue(fromServer);
        XCTAssertNil(error);

        XCTAssertEqualObjects(resourcesAsJSON, testServerFileContents);

        XCTAssertEqual(2, [newResourcesValues count]);
        XCTAssertNotNil([newResourcesValues objectForKey:@"animal.ant"]);
        NSDictionary *newValue1 = [newResourcesValues objectForKey:@"animal.ant"];
        XCTAssertEqualObjects([newValue1 objectForKey:@"cost"], @"777"); // this is the server difference from the cache
        NSDictionary *newValue2 = [newResourcesValues objectForKey:@"animal.bear"];
        XCTAssertEqualObjects([newValue2 objectForKey:@"level"], @"9000");

        XCTAssertEqual(2, [oldResourcesValues count]);
        XCTAssertNotNil([oldResourcesValues objectForKey:@"animal.ant"]);
        NSDictionary *oldValue1 = [oldResourcesValues objectForKey:@"animal.ant"];
        XCTAssertEqualObjects([oldValue1 objectForKey:@"cost"], @"550");
        NSDictionary *oldValue2 = [oldResourcesValues objectForKey:@"animal.bear"];
        XCTAssertEqualObjects([oldValue2 objectForKey:@"level"], @"10");
        [callback fulfill];
    }];

    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"No message shown");
        }
    }];
}

@end
