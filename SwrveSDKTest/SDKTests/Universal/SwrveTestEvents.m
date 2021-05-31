#import <XCTest/XCTest.h>
#import "TestableSwrve.h"
#import "SwrveTestHelper.h"
#import "TestableSwrveRESTClient.h"
#import "SwrveReceiptProvider.h"
#import "SwrveLocalStorage.h"
#import "SwrvePermissions.h"
#import "SwrveProfileManager.h"

#import <OCMock/OCMock.h>

NSString const *iso8601regex = @"\\d{4}-(?:0[1-9]|1[0-2])-(?:0[1-9]|[1-2]\\d|3[0-1])T(?:[0-1]\\d|2[0-3]):[0-5]\\d:[0-5]\\d.\\d\\d\\d(Z|[+]\\d\\d:\\d\\d)";

@interface Swrve()
@property(atomic) SwrveProfileManager *profileManager;
@end


@interface SwrveTestEvents : XCTestCase

@property TestableSwrve* swrve;

- (NSDictionary*)makeDictionaryFromEventCacheLine:(NSString*)cacheLine;
- (NSArray*)makeArrayFromCacheFileContent:(NSString*)content;

@end


@implementation SwrveTestEvents

id classMockSwrvePermissions;

- (NSDictionary*)makeDictionaryFromEventCacheLine:(NSString*)cacheLine
{
    XCTAssert([cacheLine hasSuffix:@","]);
    return [SwrveTestHelper makeDictionaryFromEventBufferEntry:[cacheLine substringToIndex:cacheLine.length-1]];
}

- (NSString*)getURLFromEventRequest:(NSString*)eventRequest
{
    NSRange range = [eventRequest rangeOfString:@"{"];
    if (range.location == NSNotFound) {
        return eventRequest;
    }
    NSString * dictString = [eventRequest substringToIndex:range.location];
    return [dictString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (NSArray*)makeArrayFromCacheFileContent:(NSString*)content
{
    NSMutableArray* cacheLines = [[NSMutableArray alloc] initWithArray:[content componentsSeparatedByString:@"\n"]];

    NSString* lastObject = (NSString*)[cacheLines lastObject];
    XCTAssertEqualObjects(lastObject, @"");

    [cacheLines removeLastObject];
    return cacheLines;
}

- (void)setUp {
    [super setUp];
    [SwrveTestHelper setUp];
    
    classMockSwrvePermissions = [SwrveTestHelper mockPushRequest];
}

- (void)tearDown {
    [self.swrve shutdown];
    self.swrve = nil;
    [SwrveTestHelper tearDown];
    if (classMockSwrvePermissions) {
        [classMockSwrvePermissions stopMocking];
    }
    [super tearDown];
}

- (void)setupSwrveMigrated:(bool)markMigrated {
    SwrveConfig *config = [[SwrveConfig alloc]init];
    config.autoSendEventsOnResume = false;
    config.autoDownloadCampaignsAndResources = false;
    if (markMigrated) {
        [SwrveTestHelper setAlreadyInstalledUserId:@"SomeUserID"];
    }
    [self setSwrve:[[TestableSwrve alloc] initWithAppID:572 apiKey:@"SomeAPIKey" config:config]];
    [self.swrve appDidBecomeActive:nil];
}

- (void)testInitialEventsMigrated {
    [self setupSwrveMigrated:true];
    // All events should be sent after init, buffer should be empty
    NSArray* eventsBuffer = [[self swrve] eventBuffer];
    XCTAssertEqual([eventsBuffer count], 0);

    TestableSwrveRESTClient *restClient = (TestableSwrveRESTClient *)[self.swrve restClient];
    
    NSArray* eventRequests = [restClient eventRequests];
    int initEventsFound = 0;

    // We should find at 2 events in the event requests: session_start, device_update. Swrve.first_session should not be present
    for (NSString* requestString in eventRequests) {
        NSDictionary* eventRequest = [SwrveTestHelper makeDictionaryFromEventRequest:requestString];

        // Should only contain batch events
        NSString* eventRequestURL = [self getURLFromEventRequest:requestString];
        XCTAssertEqualObjects(eventRequestURL, @"https://572.api.swrve.com/1/batch");

        // Get event data from request
        XCTAssertNotNil([eventRequest objectForKey:@"data"]);
        NSArray* eventData = [eventRequest objectForKey:@"data"];

        for (NSDictionary* event in eventData) {
            // Check which event this is
            XCTAssertNotNil([event objectForKey:@"type"]);
            XCTAssertNotNil([event objectForKey:@"time"]);
            XCTAssertNotNil([event objectForKey:@"seqnum"]);

            XCTAssert([[event objectForKey:@"time"] isKindOfClass:[NSNumber class]]);
            NSString* eventType = [event objectForKey:@"type"];

            if ([eventType isEqualToString:@"session_start"]) {
                initEventsFound += 1;
            } else if ([eventType isEqualToString:@"event"]) {
                NSString* eventName = [event objectForKey:@"name"];
                if ([eventName isEqualToString:@"Swrve.first_session"]) {
                    initEventsFound += 1;
                }
            } else if ([eventType isEqualToString:@"device_update"]) {
                initEventsFound += 1;
            }
        }

        XCTAssertEqual(initEventsFound, 2);

        // Check order of the events
        XCTAssertEqualObjects([eventData[0] objectForKey:@"type"], @"session_start");
        XCTAssertEqualObjects([eventData[1] objectForKey:@"type"], @"device_update");
        break;
    }
}

- (void)testInitialEventsNotMigrated {
    [self setupSwrveMigrated:false];
    // All events should be sent after init, buffer should be empty
    NSArray* eventsBuffer = [[self swrve] eventBuffer];
    XCTAssertEqual([eventsBuffer count], 0);

    TestableSwrveRESTClient *restClient = (TestableSwrveRESTClient *)[self.swrve restClient];
    
    NSArray* eventRequests = [restClient eventRequests];
    int initEventsFound = 0;

    // We should find at 3 events in the event requests: session_start, user_update and Swrve.first_session
    for (NSString* requestString in eventRequests) {
        NSDictionary* eventRequest = [SwrveTestHelper makeDictionaryFromEventRequest:requestString];

        // Should only contain batch events
        NSString* eventRequestURL = [self getURLFromEventRequest:requestString];
        XCTAssertEqualObjects(eventRequestURL, @"https://572.api.swrve.com/1/batch");

        // Get event data from request
        XCTAssertNotNil([eventRequest objectForKey:@"data"]);
        NSArray* eventData = [eventRequest objectForKey:@"data"];

        for (NSDictionary* event in eventData) {
            // Check which event this is
            XCTAssertNotNil([event objectForKey:@"type"]);
            XCTAssertNotNil([event objectForKey:@"time"]);
            XCTAssertNotNil([event objectForKey:@"seqnum"]);

            XCTAssert([[event objectForKey:@"time"] isKindOfClass:[NSNumber class]]);
            NSString* eventType = [event objectForKey:@"type"];

            if ([eventType isEqualToString:@"session_start"]) {
                initEventsFound += 1;
            } else if ([eventType isEqualToString:@"event"]) {
                NSString* eventName = [event objectForKey:@"name"];
                if ([eventName isEqualToString:@"Swrve.first_session"]) {
                    initEventsFound += 1;
                }
            } else if ([eventType isEqualToString:@"device_update"]) {
                initEventsFound += 1;
            }
        }

        XCTAssertEqual(initEventsFound, 3);

        // Check order of the events
        XCTAssertEqualObjects([eventData[0] objectForKey:@"type"], @"session_start");
        XCTAssertEqualObjects([eventData[1] objectForKey:@"type"], @"event");
        XCTAssertEqualObjects([eventData[2] objectForKey:@"type"], @"device_update");
        break;
    }
}

- (void)testPurchaseItem {
    [self setupSwrveMigrated:true];
    [self.swrve purchaseItem:@"toy" currency:@"silver" cost:23 quantity:43];

    //
    // Read memory buffer (time will be different each run)
    //

    // {"item":"toy","currency":"silver","type":"purchase","time":1383139285634,"cost":23,"quantity":43}

    NSArray* eventsBuffer = [[self swrve] eventBuffer];
    XCTAssertEqual([eventsBuffer count], 1);

    NSString * line1Str = (NSString*)(eventsBuffer[0]);
    NSDictionary * line1 = [SwrveTestHelper makeDictionaryFromEventBufferEntry:line1Str];
    XCTAssertEqual([line1 count], 7);
    XCTAssertEqualObjects([line1 objectForKey:@"item"], @"toy");
    XCTAssertEqualObjects([line1 objectForKey:@"currency"], @"silver");
    XCTAssertEqualObjects([line1 objectForKey:@"type"], @"purchase");
    XCTAssertEqualObjects([line1 objectForKey:@"cost"], [NSNumber numberWithInt:23]);
    XCTAssertEqualObjects([line1 objectForKey:@"quantity"], [NSNumber numberWithInt:43]);
    XCTAssertNotNil([line1 objectForKey:@"time"]);
    XCTAssert([[line1 objectForKey:@"time"] isKindOfClass:[NSNumber class]]);
    XCTAssertNotNil([line1 objectForKey:@"seqnum"]);
}

- (void)testEvent_NoPayload {
    [self setupSwrveMigrated:true];
    [self.swrve event:@"Some.Event"];

    //
    // Read memory buffer (time will be different each run)
    //

    // {"type":"event","name":"Some.Event","time":1383139578495,"payload":{}}

    NSArray* eventsBuffer = [[self swrve] eventBuffer];
    XCTAssertEqual([eventsBuffer count], 1);

    NSString * line1Str = (NSString*)(eventsBuffer[0]);
    NSDictionary * line1 = [SwrveTestHelper makeDictionaryFromEventBufferEntry:line1Str];
    XCTAssertEqual([line1 count], 5);
    XCTAssertEqualObjects([line1 objectForKey:@"type"], @"event");
    XCTAssertEqualObjects([line1 objectForKey:@"name"], @"Some.Event");
    XCTAssertNotNil([line1 objectForKey:@"payload"]);
    XCTAssert([[line1 objectForKey:@"payload"] isKindOfClass:[NSDictionary class]]);
    XCTAssertEqual([[line1 objectForKey:@"payload"] count], 0);
    XCTAssertNotNil([line1 objectForKey:@"time"]);
    XCTAssert([[line1 objectForKey:@"time"] isKindOfClass:[NSNumber class]]);
    XCTAssertNotNil([line1 objectForKey:@"seqnum"]);
}

-(void)testRestrictedEventName {
    [self setupSwrveMigrated:true];
    [self.swrve event:@"Some.Event"];
    [self.swrve event:nil];
    [self.swrve event:@"Swrve.thisEventIsRestrictedAndWillNotBeQueued"];

    NSArray* eventsBuffer = [[self swrve] eventBuffer];
    XCTAssertEqual([eventsBuffer count], 1);
}

-(void)testEvent_Payload {
    [self setupSwrveMigrated:true];
    [self.swrve event:@"SomeOther_Event"
              payload:[NSDictionary dictionaryWithObjectsAndKeys:
                       @"FirstValue", @"FirstKey",
                       @"SecondValue", @"SecondKey",
                       [NSNumber numberWithInt:3], @"ThirdKey",
                       nil]];
    //
    // Read memory buffer (time will be different each run)
    //

    // {"type":"event","name":"SomeOther_Event","time":1383139937177,"payload":{"FirstKey":"FirstValue","ThirdKey":3,"SecondKey":"SecondValue"}}

    NSArray * eventsBuffer = [[self swrve] eventBuffer];
    XCTAssertEqual([eventsBuffer count], 1);

    NSString * line1Str = (NSString*)(eventsBuffer[0]);
    NSDictionary * line1 = [SwrveTestHelper makeDictionaryFromEventBufferEntry:line1Str];
    XCTAssertEqual([line1 count], 5);
    XCTAssertEqualObjects([line1 objectForKey:@"type"], @"event");
    XCTAssertEqualObjects([line1 objectForKey:@"name"], @"SomeOther_Event");
    XCTAssertNotNil([line1 objectForKey:@"payload"]);
    XCTAssert([[line1 objectForKey:@"payload"] isKindOfClass:[NSDictionary class]]);
    NSDictionary * payload = (NSDictionary*)([line1 objectForKey:@"payload"]);
    XCTAssertEqualObjects([payload objectForKey:@"FirstKey"], @"FirstValue");
    XCTAssertEqualObjects([payload objectForKey:@"SecondKey"], @"SecondValue");
    XCTAssertEqualObjects([payload objectForKey:@"ThirdKey"], [NSNumber numberWithInteger:3]);
    XCTAssertNotNil([line1 objectForKey:@"time"]);
    XCTAssert([[line1 objectForKey:@"time"] isKindOfClass:[NSNumber class]]);
    XCTAssertNotNil([line1 objectForKey:@"seqnum"]);
}

-(void)testEvent_PayloadNoTrigger {
    [self setupSwrveMigrated:true];
    [self.swrve eventWithNoCallback:@"NoTriggerEvent"
                            payload:[NSDictionary dictionaryWithObjectsAndKeys:
                                     @"SomeValue", @"SomeKey",
                                     nil]];

    //
    // Read memory buffer (time will be different each run)
    //

    // {"type":"event","name":"NoTriggerEvent","time":1383140227529,"payload":{"SomeKey":"SomeValue"}}

    NSArray* eventsBuffer = [[self swrve] eventBuffer];
    XCTAssertEqual([eventsBuffer count], 1);

    NSString * line1Str = (NSString*)(eventsBuffer[0]);
    NSDictionary * line1 = [SwrveTestHelper makeDictionaryFromEventBufferEntry:line1Str];
    XCTAssertEqual([line1 count], 5);
    XCTAssertEqualObjects([line1 objectForKey:@"type"], @"event");
    XCTAssertEqualObjects([line1 objectForKey:@"name"], @"NoTriggerEvent");
    XCTAssertNotNil([line1 objectForKey:@"payload"]);
    XCTAssert([[line1 objectForKey:@"payload"] isKindOfClass:[NSDictionary class]]);
    NSDictionary * payload = (NSDictionary*)([line1 objectForKey:@"payload"]);
    XCTAssertEqualObjects([payload objectForKey:@"SomeKey"], @"SomeValue");
    XCTAssertNotNil([line1 objectForKey:@"time"]);
    XCTAssert([[line1 objectForKey:@"time"] isKindOfClass:[NSNumber class]]);
    XCTAssertNotNil([line1 objectForKey:@"seqnum"]);
}

-(void)testEvent_PayloadNoTriggerNilPayload {
    [self setupSwrveMigrated:true];
    [self.swrve eventWithNoCallback:@"NoTriggerOrPayload"
                            payload:nil];

    //
    // Read memory buffer (time will be different each run)
    //

    // {"type":"event","name":"NoTriggerOrPayload","time":1383140334466,"payload":{}}

    NSArray* eventsBuffer = [[self swrve] eventBuffer];
    XCTAssertEqual([eventsBuffer count], 1);

    NSString * line1Str = (NSString*)(eventsBuffer[0]);
    NSDictionary * line1 = [SwrveTestHelper makeDictionaryFromEventBufferEntry:line1Str];
    XCTAssertEqual([line1 count], 5);
    XCTAssertEqualObjects([line1 objectForKey:@"type"], @"event");
    XCTAssertEqualObjects([line1 objectForKey:@"name"], @"NoTriggerOrPayload");
    XCTAssertNotNil([line1 objectForKey:@"payload"]);
    XCTAssert([[line1 objectForKey:@"payload"] isKindOfClass:[NSDictionary class]]);
    XCTAssertEqual([[line1 objectForKey:@"payload"] count], 0);
    XCTAssertNotNil([line1 objectForKey:@"time"]);
    XCTAssert([[line1 objectForKey:@"time"] isKindOfClass:[NSNumber class]]);
    XCTAssertNotNil([line1 objectForKey:@"seqnum"]);
}

-(void)testIAP {
    [self setupSwrveMigrated:true];
    NSString* expectedReceipt = @"ZmFrZV9yZWNlaXB0";

    SwrveIAPRewards* iapRewards = [SwrveIAPRewards new];
    [iapRewards addCurrency:@"gold" withAmount:18];
    
    id dummyPayment = OCMPartialMock([SKPayment new]);
    OCMStub([dummyPayment productIdentifier]).andReturn(@"my_product_id");
    OCMStub([dummyPayment quantity]).andReturn([[NSNumber alloc] initWithInt:8]);

    id dummyTransaction = OCMPartialMock([SKPaymentTransaction new]);
    OCMStub([dummyTransaction payment]).andReturn(dummyPayment);
    OCMStub([dummyTransaction transactionState]).andReturn(SKPaymentTransactionStatePurchased);

    NSDecimalNumber* price = [[NSDecimalNumber alloc] initWithDouble:9.99];
    id dummyProduct = OCMPartialMock([SKProduct new]);
    OCMStub([dummyProduct price]).andReturn(price);
    NSDictionary *localeComponents = [NSDictionary dictionaryWithObject:@"EUR" forKey:NSLocaleCurrencyCode];
    NSString *localeIdentifier = [NSLocale localeIdentifierFromComponents:localeComponents];
    NSLocale *localeForDefaultCurrency = [[NSLocale alloc] initWithLocaleIdentifier:localeIdentifier];
    OCMStub([dummyProduct priceLocale]).andReturn(localeForDefaultCurrency);

    id receiptProviderPartialMock = OCMPartialMock(self.swrve.receiptProvider);
    OCMStub([receiptProviderPartialMock readMainBundleAppStoreReceipt]).andReturn([@"fake_receipt" dataUsingEncoding:NSUTF8StringEncoding]);
    self.swrve.receiptProvider = receiptProviderPartialMock;
    
    [self.swrve iap:dummyTransaction product:dummyProduct rewards:iapRewards];

    NSArray * eventsBuffer = [[self swrve] eventBuffer];
    XCTAssertEqual([eventsBuffer count], 1);

    NSString * line1Str = (NSString*)(eventsBuffer[0]);
    NSDictionary * line1 = [SwrveTestHelper makeDictionaryFromEventBufferEntry:line1Str];
    XCTAssertEqual([line1 count], 9);
    XCTAssertEqualObjects([line1 objectForKey:@"type"], @"iap");
    XCTAssertEqualObjects([line1 objectForKey:@"receipt"], expectedReceipt);
    XCTAssertEqualObjects([line1 objectForKey:@"app_store"], @"apple");
    XCTAssertEqualObjects([line1 objectForKey:@"cost"], price);
    XCTAssertEqualObjects([line1 objectForKey:@"local_currency"], @"EUR");
    XCTAssertNotNil([line1 objectForKey:@"payload"]);
    NSDictionary* payload = [line1 valueForKey:@"payload"];
    XCTAssertEqualObjects([payload objectForKey:@"product_id"], @"my_product_id");

    XCTAssertNotNil([line1 objectForKey:@"time"]);
    XCTAssert([[line1 objectForKey:@"time"] isKindOfClass:[NSNumber class]]);
    XCTAssert([[line1 objectForKey:@"rewards"] isKindOfClass:[NSDictionary class]]);
    NSDictionary *rewards = [line1 objectForKey:@"rewards"];
    XCTAssert([[rewards objectForKey:@"gold"] isKindOfClass:[NSDictionary class]]);
    NSDictionary *gold = [rewards objectForKey:@"gold"];
    XCTAssertEqualObjects([gold objectForKey:@"amount"], [NSNumber numberWithInt:18]);
    XCTAssertEqualObjects([gold objectForKey:@"type"], @"currency");
}

-(void)testUnvalidatedIAP {
    [self setupSwrveMigrated:true];

    SwrveIAPRewards* iapRewards = [SwrveIAPRewards new];
    [iapRewards addCurrency:@"gold" withAmount:18];

    [self.swrve unvalidatedIap:iapRewards localCost:9.99 localCurrency:@"EUR" productId:@"product_id" productIdQuantity:1];

    NSArray * eventsBuffer = [[self swrve] eventBuffer];

    XCTAssertEqual([eventsBuffer count], 1);

    NSString * line1Str = (NSString*)(eventsBuffer[0]);
    NSDictionary * line1 = [SwrveTestHelper makeDictionaryFromEventBufferEntry:line1Str];
    XCTAssertEqual([line1 count], 9);
    XCTAssertEqualObjects([line1 objectForKey:@"type"], @"iap");
    XCTAssertEqualObjects([line1 objectForKey:@"app_store"], @"unknown");
    XCTAssertEqualObjects([line1 objectForKey:@"cost"], [[NSNumber alloc] initWithDouble:9.99]);
    XCTAssertEqualObjects([line1 objectForKey:@"local_currency"], @"EUR");
    XCTAssertEqualObjects([line1 objectForKey:@"product_id"], @"product_id");
    XCTAssertEqualObjects([line1 objectForKey:@"quantity"], [NSNumber numberWithInteger:1]);

    XCTAssertNotNil([line1 objectForKey:@"time"]);
    XCTAssert([[line1 objectForKey:@"time"] isKindOfClass:[NSNumber class]]);
    XCTAssert([[line1 objectForKey:@"rewards"] isKindOfClass:[NSDictionary class]]);
    NSDictionary * rewards = [line1 objectForKey:@"rewards"];
    XCTAssert([[rewards objectForKey:@"gold"] isKindOfClass:[NSDictionary class]]);
    NSDictionary * gold = [rewards objectForKey:@"gold"];
    XCTAssertEqualObjects([gold objectForKey:@"amount"], [NSNumber numberWithInt:18]);
    XCTAssertEqualObjects([gold objectForKey:@"type"], @"currency");
}

-(void)testBadRewards {
    [self setupSwrveMigrated:true];
    SwrveIAPRewards* iapRewards = [SwrveIAPRewards new];
    XCTAssertEqual([iapRewards.rewards count], 0);

    [iapRewards addItem:nil withQuantity:123];
    XCTAssertEqual([iapRewards.rewards count], 0);

    [iapRewards addItem:@"" withQuantity:123];
    XCTAssertEqual([iapRewards.rewards count], 0);

    [iapRewards addItem:@"Book" withQuantity:-1];
    XCTAssertEqual([iapRewards.rewards count], 0);

    [iapRewards addCurrency:@"Silver" withAmount:-1];
    XCTAssertEqual([iapRewards.rewards count], 0);
}

-(void)testGoodRewards {
    SwrveIAPRewards * iapRewards = [SwrveIAPRewards new];
    [iapRewards addCurrency:@"Gold" withAmount:23];
    XCTAssertEqual(iapRewards.rewards.count, 1);
    XCTAssertNotNil([iapRewards.rewards objectForKey:@"Gold"]);
    NSDictionary * goldReward = [iapRewards.rewards objectForKey:@"Gold"];
    XCTAssertEqualObjects([goldReward objectForKey:@"amount"], [NSNumber numberWithInt:23]);
    XCTAssertEqualObjects([goldReward objectForKey:@"type"], @"currency");
}

-(void)testCurrencyGiven {
    [self setupSwrveMigrated:true];
    [self.swrve currencyGiven:@"USD" givenAmount:123.54];

    //
    // Read memory buffer (time will be different each run)
    //

    //{"type":"currency_given","given_amount":123.54,"time":1383137702885,"given_currency":"USD"}

    NSArray* eventsBuffer = [[self swrve] eventBuffer];
    XCTAssertEqual([eventsBuffer count], 1);

    NSString * line1Str = (NSString*)(eventsBuffer[0]);
    NSDictionary * line1 = [SwrveTestHelper makeDictionaryFromEventBufferEntry:line1Str];
    XCTAssertEqual([line1 count], 5);
    XCTAssertEqualObjects([line1 objectForKey:@"type"], @"currency_given");
    XCTAssertEqualWithAccuracy([[line1 objectForKey:@"given_amount"] floatValue], 123.54f, 0.0001);
    XCTAssertNotNil([line1 objectForKey:@"time"]);
    XCTAssert([[line1 objectForKey:@"time"] isKindOfClass:[NSNumber class]]);
    XCTAssertNotNil([line1 objectForKey:@"seqnum"]);
    XCTAssertEqualObjects([line1 objectForKey:@"given_currency"], @"USD");
}

- (void)testUserUpdate {
    [self setupSwrveMigrated:true];
    [self.swrve userUpdate:[NSDictionary dictionaryWithObjectsAndKeys:
                            @"SomeVal", @"TestParam",
                            @"456", @"OtherTestParam",
                            [NSNumber numberWithInt:17], @"SomeNumber",
                            nil]];

    //
    // UserUpdates are not cached in memory buffer
    //

    NSArray* eventsBuffer = [[self swrve] eventBuffer];
    XCTAssertEqual([eventsBuffer count], 0);

    XCTAssertEqual(self.swrve.userUpdates.count, 3);
    XCTAssertEqualObjects([self.swrve.userUpdates objectForKey:@"type"], @"user");
    XCTAssert([[self.swrve.userUpdates objectForKey:@"time"] isKindOfClass:[NSNumber class]]);
    XCTAssertNotNil([self.swrve.userUpdates objectForKey:@"attributes"]);
    NSDictionary * attributes = (NSDictionary*)([self.swrve.userUpdates objectForKey:@"attributes"]);
    XCTAssertEqualObjects([attributes objectForKey:@"SomeNumber"], [NSNumber numberWithInt:17]);
    XCTAssertEqualObjects([attributes objectForKey:@"OtherTestParam"], @"456");
    XCTAssertEqualObjects([attributes objectForKey:@"TestParam"], @"SomeVal");
}

-(void)testMultipleUserUpdates {
    [self setupSwrveMigrated:true];
    [self.swrve userUpdate:[NSDictionary dictionaryWithObjectsAndKeys:
                            @"SomeVal", @"TestParam",
                            @"456", @"OtherTestParam",
                            [NSNumber numberWithInt:17], @"SomeNumber",
                            nil]];

    [self.swrve userUpdate:[NSDictionary dictionaryWithObjectsAndKeys:
                            @"SomeVal", @"TestParam",
                            @"123", @"OtherTestParam",
                            [NSNumber numberWithInt:27], @"SomeNumber",
                            nil]];

    [self.swrve userUpdate:[NSDictionary dictionaryWithObjectsAndKeys:
                            @"123", @"OtherTestParam",
                            @"789", @"NewParam",
                            [NSNumber numberWithInt:37], @"SomeNumber",
                            nil]];

    // Should only have the latest values

    NSArray *eventsBuffer = [[self swrve] eventBuffer];
    XCTAssertEqual([eventsBuffer count], 0);

    XCTAssertEqual(self.swrve.userUpdates.count, 3);
    XCTAssertEqualObjects([self.swrve.userUpdates objectForKey:@"type"], @"user");
    XCTAssert([[self.swrve.userUpdates objectForKey:@"time"] isKindOfClass:[NSNumber class]]);
    XCTAssertNotNil([self.swrve.userUpdates objectForKey:@"attributes"]);
    NSDictionary *attributes = (NSDictionary*)([self.swrve.userUpdates objectForKey:@"attributes"]);
    XCTAssertEqualObjects([attributes objectForKey:@"SomeNumber"], [NSNumber numberWithInt:37]);
    XCTAssertEqualObjects([attributes objectForKey:@"OtherTestParam"], @"123");
    XCTAssertEqualObjects([attributes objectForKey:@"TestParam"], @"SomeVal");
    XCTAssertEqualObjects([attributes objectForKey:@"NewParam"], @"789");
}

-(void)testUserUpdatesSaveToFile {
    [self setupSwrveMigrated:true];
    // Clear event cache file
    [[self swrve] resetEventCache];

    [self.swrve userUpdate:[NSDictionary dictionaryWithObjectsAndKeys:
                            @"SomeVal", @"TestParam",
                            @"456", @"OtherTestParam",
                            [NSNumber numberWithInt:17], @"SomeNumber",
                            nil]];
    [self.swrve saveEventsToDisk];

    NSString *eventCacheContents = [SwrveTestHelper fileContentsFromURL:[[self swrve] eventFilename]];

    NSArray *cacheLines = [self makeArrayFromCacheFileContent:eventCacheContents];
    XCTAssertNotNil(cacheLines);
    XCTAssertEqual(cacheLines.count, 1);

    NSDictionary *line = [self makeDictionaryFromEventCacheLine:(NSString*)(cacheLines[0])];
    XCTAssertEqual(line.count, 4);
    XCTAssertEqualObjects([line objectForKey:@"type"], @"user");
    XCTAssert([[line objectForKey:@"time"] isKindOfClass:[NSNumber class]]);
    XCTAssertNotNil([line objectForKey:@"seqnum"]);
    XCTAssertNotNil([line objectForKey:@"attributes"]);
    NSDictionary *attributes = (NSDictionary*)([line objectForKey:@"attributes"]);
    XCTAssertEqualObjects([attributes objectForKey:@"SomeNumber"], [NSNumber numberWithInt:17]);
    XCTAssertEqualObjects([attributes objectForKey:@"OtherTestParam"], @"456");
    XCTAssertEqualObjects([attributes objectForKey:@"TestParam"], @"SomeVal");
}

-(void)testUserUpdateWithNameAndDate {
    [self setupSwrveMigrated:true];
    [self.swrve userUpdate:@"test_date" withDate:[NSDate date]];

    NSArray* eventsBuffer = [[self swrve] eventBuffer];
    XCTAssertEqual([eventsBuffer count], 0);
    XCTAssertEqual(self.swrve.userUpdates.count, 3);
    XCTAssertEqualObjects([self.swrve.userUpdates objectForKey:@"type"], @"user");
    XCTAssert([[self.swrve.userUpdates objectForKey:@"time"] isKindOfClass:[NSNumber class]]);
    XCTAssertNotNil([self.swrve.userUpdates objectForKey:@"attributes"]);
    NSDictionary * attributes = (NSDictionary*)([self.swrve.userUpdates objectForKey:@"attributes"]);
    XCTAssert([[attributes objectForKey:@"test_date"] isKindOfClass:[NSString class]]);

    NSPredicate *testAttributes = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", iso8601regex];
    NSString *dateString = [attributes objectForKey:@"test_date"];

    XCTAssertTrue([testAttributes evaluateWithObject:dateString]);
}

- (void)testUserUpdateWithNameAndDateIsUTC {
    [self setupSwrveMigrated:true];
    NSInteger march10th2013 = 1362873600;
    NSDate *prospectDate = [NSDate dateWithTimeIntervalSince1970:march10th2013];
    NSTimeZone *timezone = [NSTimeZone timeZoneWithName:@"UTC"];
    NSInteger timediffSeconds = [timezone secondsFromGMTForDate: prospectDate];
    NSDate *dateForTesting = [prospectDate dateByAddingTimeInterval:timediffSeconds];

    [self.swrve userUpdate:@"test_date" withDate:dateForTesting];

    NSArray* eventsBuffer = [[self swrve] eventBuffer];
    XCTAssertEqual([eventsBuffer count], 0);
    XCTAssertEqual(self.swrve.userUpdates.count, 3);
    XCTAssertEqualObjects([self.swrve.userUpdates objectForKey:@"type"], @"user");
    XCTAssert([[self.swrve.userUpdates objectForKey:@"time"] isKindOfClass:[NSNumber class]]);
    XCTAssertNotNil([self.swrve.userUpdates objectForKey:@"attributes"]);
    NSDictionary *attributes = (NSDictionary*)([self.swrve.userUpdates objectForKey:@"attributes"]);
    XCTAssert([[attributes objectForKey:@"test_date"] isKindOfClass:[NSString class]]);

    NSPredicate *testAttributes = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", iso8601regex];
    NSString *dateString = [attributes objectForKey:@"test_date"];
    XCTAssertTrue([testAttributes evaluateWithObject:dateString]);
    XCTAssertEqualObjects(dateString, @"2013-03-10T00:00:00.000Z");
}

-(void)testUserUpdateWithNullName {
    [self setupSwrveMigrated:true];
    [self.swrve userUpdate:nil withDate:[NSDate date]];

    NSArray *eventsBuffer = [[self swrve] eventBuffer];
    XCTAssertEqual([eventsBuffer count], 0);
    NSDictionary *attributes = (NSDictionary*)([self.swrve.userUpdates objectForKey:@"attributes"]);
    XCTAssertEqual(attributes.count, 0); //should be empty
}

-(void)testUserUpdateWithNullDate {
   [self setupSwrveMigrated:true];
   [self.swrve userUpdate:@"test_date" withDate:nil];

    NSArray *eventsBuffer = [[self swrve] eventBuffer];
    XCTAssertEqual([eventsBuffer count], 0);
    NSDictionary *attributes = (NSDictionary*)([self.swrve.userUpdates objectForKey:@"attributes"]);
    XCTAssertEqual(attributes.count, 0); //should be empty
}

// test iso8601Regex to ensure test regex is correct

- (void)testActiveTestRegex {
    NSPredicate *regexTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", iso8601regex];

    NSArray *badStrings = [NSArray arrayWithObjects:@"2015-03-16T23:59:59+00:00", @"2015-03-16T23:59:59+00", @"2015-03-16T23:59:59+0000", @"2015-03-16T23:59:59.000+00", @"2015-03-16T23:59:59.000+0000", @"2015-03-16T23:59:59+09:00", @"2015-03-16T23:59:59+10", @"2015-03-16T23:59:59-0100", @"2015-03-16T23:59:59.000+00", @"2015-03-16T23:59:59.000+0000",@"2015-03-16T23:59:59.500+00", @"2015-03-16T23:59:59.600+0000", @"goldfish", nil];

    NSArray *goodStrings = [NSArray arrayWithObjects:@"2015-03-16T23:59:59.000Z", @"2015-03-16T23:59:59.000+00:00", @"2015-03-16T23:59:59.000Z", @"2015-03-16T23:59:59.999+00:00",  nil];

    //should be all false
    for (NSString *string in badStrings){
        XCTAssertFalse([regexTest evaluateWithObject:string]);
    }

    //should be all true
    for (NSString *string in goodStrings){
        XCTAssertTrue([regexTest evaluateWithObject:string]);
    }
}

-(void)testSaveEvents {
    [self setupSwrveMigrated:true];
    // Clear event cache file
    [[self swrve] resetEventCache];

    [self.swrve sessionStart];
    [self.swrve purchaseItem:@"thing" currency:@"gold" cost:32 quantity:4];

    // session start will be sent immediately, other event will be queued
    NSArray* eventsBuffer = [[self swrve] eventBuffer];
    XCTAssertEqual([eventsBuffer count], 1);

    [self.swrve saveEventsToDisk];

    eventsBuffer = [[self swrve] eventBuffer];
    XCTAssertEqual([eventsBuffer count], 0);

    //
    // Read content of event cache file (timestamps will be different each run)
    //

    //{"type":"session_start","time":1383132451697},\n
    //                       {"item":"thing","currency":"gold","type":"purchase","time":1383132451697,"cost":32,"quantity":4},\n
    //                       {"type":"session_end","time":1383132451697},\n"));

    NSString * eventCacheContents = [SwrveTestHelper fileContentsFromURL:[[self swrve] eventFilename]];

    NSArray* cacheLines = [self makeArrayFromCacheFileContent:eventCacheContents];
    XCTAssertNotNil(cacheLines);
    XCTAssertEqual(cacheLines.count, 1);

    NSDictionary * line1 = [self makeDictionaryFromEventCacheLine:(NSString*)(cacheLines[0])];
    XCTAssertEqual([line1 count], 7);
    XCTAssertEqualObjects([line1 objectForKey:@"item"], @"thing");
    XCTAssertEqualObjects([line1 objectForKey:@"currency"], @"gold");
    XCTAssertEqualObjects([line1 objectForKey:@"type"], @"purchase");
    XCTAssertEqualObjects([line1 objectForKey:@"cost"], [NSNumber numberWithInt:32]);
    XCTAssertEqualObjects([line1 objectForKey:@"quantity"], [NSNumber numberWithInt:4]);
    XCTAssertNotNil([line1 objectForKey:@"time"]);
    XCTAssert([[line1 objectForKey:@"time"] isKindOfClass:[NSNumber class]]);
    XCTAssertNotNil([line1 objectForKey:@"seqnum"]);
}

-(void)testMultipleEventSaves {
    [self setupSwrveMigrated:true];
    [[self swrve] resetEventCache];

    [self.swrve event:@"randomEvent"];
    [self.swrve saveEventsToDisk];

    //
    // Read content of event cache file (timestamps will be different each run)
    //

    // {"type":"session_start","time":1383153314951},\n{"type":"session_end","time":1383153314952},\n"

    NSString *eventCacheContents = [SwrveTestHelper fileContentsFromURL:[[self swrve] eventFilename]];
    NSArray *cacheLines = [self makeArrayFromCacheFileContent:eventCacheContents];
    XCTAssertNotNil(cacheLines);
    XCTAssertEqual(cacheLines.count, 1);

    NSDictionary *line1 = [self makeDictionaryFromEventCacheLine:(NSString*)(cacheLines[0])];
    XCTAssertEqual([line1 count], 5);
    XCTAssertEqualObjects([line1 objectForKey:@"type"], @"event");
    XCTAssertNotNil([line1 objectForKey:@"time"]);
    XCTAssert([[line1 objectForKey:@"time"] isKindOfClass:[NSNumber class]]);
    XCTAssertNotNil([line1 objectForKey:@"seqnum"]);
    XCTAssertEqualObjects([line1 objectForKey:@"name"], @"randomEvent");
}

-(void)testEmptySave {
    [self setupSwrveMigrated:true];
    [[self swrve] resetEventCache];
    [[[self swrve] eventBuffer] removeAllObjects];

    [self.swrve saveEventsToDisk];

    NSString *eventCacheContents = [SwrveTestHelper fileContentsFromURL:[[self swrve] eventFilename]];
    XCTAssertEqualObjects(eventCacheContents, @"");
}

- (void)testSessionToken {
    [self setupSwrveMigrated:true];
    NSString *sessionToken = self.swrve.profileManager.sessionToken;

    //
    // Check token - time stamp will change each run
    //

    // "572=SomeUserID=1383142573=62c58c523e3c42825d2ca8a21e2723f0"

    XCTAssertNotNil(sessionToken);

    NSArray *elements = [sessionToken componentsSeparatedByString:@"="];
    XCTAssertEqual(elements.count, 4);
    XCTAssertEqualObjects(elements[0], @"572");
    XCTAssertEqualObjects(elements[1], @"SomeUserID");

    // Ensure only numbers in third element
    NSCharacterSet *notNumbers = [[NSCharacterSet characterSetWithCharactersInString: @"0123456789"]invertedSet];
    NSRange testRange = [(NSString*)(elements[2]) rangeOfCharacterFromSet:notNumbers];
    XCTAssertTrue((testRange.location == NSNotFound));

    // Ensure only hexadecimal chars in final element
    NSCharacterSet *notHexChars = [[NSCharacterSet characterSetWithCharactersInString: @"0123456789ABCDEFabcdef"]invertedSet];
    testRange = [(NSString*)(elements[3]) rangeOfCharacterFromSet:notHexChars];
    XCTAssertTrue((testRange.location == NSNotFound));
}

- (void)testSequenceNumbers {
    [self setupSwrveMigrated:true];
    [self.swrve shutdown];
    self.swrve = nil;

    // Start a new session
    SwrveConfig * config = [[SwrveConfig alloc]init];
    [self setSwrve:[[TestableSwrve alloc] initWithAppID:572 apiKey:@"SomeAPIKey" config:config]];
    [self.swrve appDidBecomeActive:nil];

    // Reset sequence numbers
    NSString *seqNumKey = [self.swrve.userID stringByAppendingString:@"swrve_event_seqnum"];
    [SwrveLocalStorage removeSeqNumWithCustomKey:seqNumKey];
    [[self swrve] resetEventCache];

    [self.swrve event:@"event1"];
    [self.swrve saveEventsToDisk];

    NSString* eventCacheContents = [SwrveTestHelper fileContentsFromURL:[[self swrve] eventFilename]];
    NSArray* cacheLines = [self makeArrayFromCacheFileContent:eventCacheContents];
    XCTAssertEqual(cacheLines.count, 1);

    int eventCount = 0;
    for (NSString* eventLine in cacheLines) {
        if (eventLine != nil && [eventLine length] > 0) {
            NSDictionary* event = [self makeDictionaryFromEventCacheLine:(NSString*)eventLine];
            eventCount += 1;
            XCTAssertNotNil([event objectForKey:@"seqnum"]);
            XCTAssertEqualObjects([event objectForKey:@"seqnum"], [NSNumber numberWithInteger:eventCount]);
        }
    }
}

- (void)testUserUpdateSequenceNumbers {
    [self setupSwrveMigrated:true];
    [self.swrve shutdown];
    self.swrve = nil;

    // Start a new session
    SwrveConfig * config = [[SwrveConfig alloc]init];
    [self setSwrve:[[TestableSwrve alloc] initWithAppID:572 apiKey:@"SomeAPIKey" config:config]];
    [self.swrve appDidBecomeActive:nil];

    // Reset sequence numbers
    NSString *seqNumKey = [self.swrve.userID stringByAppendingString:@"swrve_event_seqnum"];
    [SwrveLocalStorage removeSeqNumWithCustomKey:seqNumKey];
    [[self swrve] resetEventCache];

    //send in a single user update
    [self.swrve userUpdate:[NSDictionary dictionaryWithObjectsAndKeys:
                            @"SomeVal", @"TestParam",
                            @"456", @"OtherTestParam",
                            [NSNumber numberWithInt:17], @"SomeNumber",
                            nil]];
    [self.swrve saveEventsToDisk];

    NSString * eventCacheContents = [SwrveTestHelper fileContentsFromURL:[[self swrve] eventFilename]];
    NSArray* cacheLines = [self makeArrayFromCacheFileContent:eventCacheContents];
    XCTAssertEqual(cacheLines.count, 1);

    int eventCount = 0;
    for (NSString* eventLine in cacheLines) {
        if (eventLine != nil && [eventLine length] > 0) {
            NSDictionary* event = [self makeDictionaryFromEventCacheLine:(NSString*)eventLine];
            eventCount += 1;
            XCTAssertNotNil([event objectForKey:@"seqnum"]);
            XCTAssertEqualObjects([event objectForKey:@"seqnum"], [NSNumber numberWithInteger:eventCount]);
        }
    }
}

// SWRVE-6594 /SWRVE-14748 bug test
- (void)testEventsPutBackInTheQueueAndSavedToDisk {
    [self setupSwrveMigrated:true];
    // Clear event cache file
    TestableSwrveRESTClient *restClient = (TestableSwrveRESTClient *)[[self swrve] restClient];
    restClient.failPostRequests = TRUE;
    [self.swrve resetEventCache];

    for (int i = 0; i < 5; i++) {
        [self.swrve purchaseItem:@"thing" currency:@"gold" cost:32 quantity:4];
    }
    NSArray* eventsBuffer = [[self swrve] eventBuffer];
    XCTAssertEqual([eventsBuffer count], 5);

    // Queue should still have the individual events as they were rejected by the server
    [self.swrve sendQueuedEvents];
    //[NSThread sleepForTimeInterval:10.0f];

    // Emptied buffer on network error
    eventsBuffer = [[self swrve] eventBuffer];
    XCTAssertEqual([eventsBuffer count], 0);

    // Ensure the event_file has been written to
    NSURL* aka = [self.swrve eventFilename];
    NSMutableData* eventFileContents = [[NSMutableData alloc] initWithContentsOfURL:aka];
    assert([eventFileContents length] > 2);

    // Ensure the emptied events are put into the event_file
    NSArray *eventsInFile = [SwrveTestHelper makeArrayFromEventFileContents:eventFileContents];
    XCTAssertEqual(eventsInFile.count, 5);
}

- (void)testEventsAreSentOnAppPause {
    [self setupSwrveMigrated:true];
    [self.swrve purchaseItem:@"toy" currency:@"silver" cost:23 quantity:43];
    NSArray* eventsBuffer = [[self swrve] eventBuffer];
    XCTAssertEqual([eventsBuffer count], 1);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    // Events are sent when the app goes into the background
    [self.swrve performSelector:@selector(appWillResignActive:) withObject:nil];
#pragma clang diagostic pop
    eventsBuffer = [[self swrve] eventBuffer];
    XCTAssertEqual([eventsBuffer count], 0);
}

- (void)testDeviceUUID {
    [self setupSwrveMigrated:true];
    // Obtain last event in the
    TestableSwrveRESTClient *restClient = (TestableSwrveRESTClient *)[self.swrve restClient];
    NSString* lastEventRequestString = [[restClient eventRequests] lastObject];
    NSDictionary* eventRequest = [SwrveTestHelper makeDictionaryFromEventRequest:lastEventRequestString];

    // Get event data from request
    NSString* deviceUUID1 = [eventRequest objectForKey:@"unique_device_id"];

    // Restart SDK
    [self.swrve shutdown];
    self.swrve = nil;

    // Start a new session
    SwrveConfig * config = [[SwrveConfig alloc]init];
    [self setSwrve:[[TestableSwrve alloc] initWithAppID:572 apiKey:@"SomeAPIKey" config:config]];
    [self.swrve appDidBecomeActive:nil];

    // Last event in the queue of the second init
    restClient = (TestableSwrveRESTClient *)[self.swrve restClient];
    lastEventRequestString = [[restClient eventRequests] lastObject];
    eventRequest = [SwrveTestHelper makeDictionaryFromEventRequest:lastEventRequestString];
    NSString* deviceUUID2 = [eventRequest objectForKey:@"unique_device_id"];

    // Device_ids should be equal
    XCTAssertEqual([deviceUUID2 intValue], [deviceUUID1 intValue]);
}

@end
