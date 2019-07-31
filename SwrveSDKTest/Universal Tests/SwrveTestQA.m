#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SwrveCommon.h"
#import "SwrveQA.h"
#import "SwrveLocalStorage.h"

@interface SwrveTestQA : XCTestCase {
    
}

@end

@implementation SwrveTestQA

- (void)setUp {
    [super setUp];
    id mockSwrveCommon = OCMProtocolMock(@protocol(SwrveCommonDelegate));
    OCMStub([mockSwrveCommon apiKey]).andReturn(@"my_api_key");
    OCMStub([mockSwrveCommon eventsServer]).andReturn(@"https://myevents.server");
    OCMStub([mockSwrveCommon deviceUUID]).andReturn(@"my_device_id");
    OCMStub([mockSwrveCommon appID]).andReturn(123);
    OCMStub([mockSwrveCommon appVersion]).andReturn(@"myappversion");
    OCMStub([mockSwrveCommon userID]).andReturn(@"my_user_id");
    [SwrveCommon addSharedInstance:mockSwrveCommon];
}

- (void)tearDown {
    [SwrveLocalStorage saveQaUser:nil];
    [SwrveLocalStorage saveSwrveUserId:nil];
    [super tearDown];
}

- (void)testSwrveQADisabledByDefault {
    SwrveQA *qa = [SwrveQA sharedInstance];
    XCTAssertTrue(qa.restClient != nil);
    XCTAssertTrue(qa.isQALogging == false);
}

- (void)testSwrveQADisabledAfterEmptyUpdate {
    [SwrveQA updateQAUser:@{}];
    SwrveQA *qa = [SwrveQA sharedInstance];
    XCTAssertTrue(qa.restClient != nil);
    XCTAssertTrue(qa.isQALogging == false);
}

- (void)testInitSwrveQA {
    NSDictionary *jsonQa = @{
                             @"logging": @true,
                             @"logging_url": @"http://123.swrve.com",
                             @"campaigns": @{}
                             };
    [SwrveQA updateQAUser:jsonQa];
    SwrveQA *qa = [SwrveQA sharedInstance];
    XCTAssertTrue(qa.restClient != nil);
    XCTAssertTrue(qa.isQALogging);
}

- (void)testGeoCampaignTriggered {
    [self enableQaLogging];
    SwrveQA *qa = [SwrveQA sharedInstance];
    id mockRestClient = OCMPartialMock([[SwrveRESTClient alloc] initWithTimeoutInterval:60]);
    
    __block NSURL *capturedUrl;
    __block NSData *capturedJson;
    OCMExpect([mockRestClient sendHttpPOSTRequest:[OCMArg checkWithBlock:^BOOL(NSURL *urlValue) {
        capturedUrl = urlValue;
        return urlValue;
    }]
                                         jsonData:[OCMArg checkWithBlock:^BOOL(NSData *jsonValue) {
        capturedJson = jsonValue;
        return jsonValue;
    }]
                                completionHandler:OCMOCK_ANY]);
    [qa setRestClient:mockRestClient];
    
    NSMutableArray *qaLogs = [NSMutableArray new];
    NSDictionary *log = @{
                          @"variant_id": @123,
                          @"displayed": [NSNumber numberWithBool:false],
                          @"reason": @"some reason"
                          };
    [qaLogs addObject:log];
    
    [SwrveQA geoCampaignTriggered:qaLogs fromGeoPlaceId:@"123" andGeofenceId:@"456" andActionType:@"exit"];
    
    XCTAssertEqualObjects(@"myevents.server", [capturedUrl host]);
    XCTAssertEqualObjects(@"/1/batch", [capturedUrl path]);
    
    NSDictionary *logDetails = [self verifyQaLogEvent:capturedJson withLogType:@"geo-campaign-triggered"];
    [self verifyTriggeredLogDetail:logDetails withDisplayed:0 andReason:@"some reason" andVariantId:123];
}

- (void)testGeoCampaignsDownloaded {
    [self enableQaLogging];
    SwrveQA *qa = [SwrveQA sharedInstance];
    id mockRestClient = OCMPartialMock([[SwrveRESTClient alloc] initWithTimeoutInterval:60]);
    
    __block NSURL *capturedUrl;
    __block NSData *capturedJson;
    OCMExpect([mockRestClient sendHttpPOSTRequest:[OCMArg checkWithBlock:^BOOL(NSURL *urlValue) {
        capturedUrl = urlValue;
        return urlValue;
    }]
                                         jsonData:[OCMArg checkWithBlock:^BOOL(NSData *jsonValue) {
        capturedJson = jsonValue;
        return jsonValue;
    }]
                                completionHandler:OCMOCK_ANY]);
    [qa setRestClient:mockRestClient];
    
    NSMutableArray *qaLogs = [NSMutableArray new];
    NSDictionary *log = @{
                          @"variant_id": @123
                          };
    [qaLogs addObject:log];
    
    [SwrveQA geoCampaignsDownloaded:qaLogs fromGeoPlaceId:@"123" andGeofenceId:@"456" andActionType:@"exit"];
    
    XCTAssertEqualObjects(@"myevents.server", [capturedUrl host]);
    XCTAssertEqualObjects(@"/1/batch", [capturedUrl path]);
    
    NSDictionary *logDetails = [self verifyQaLogEvent:capturedJson withLogType:@"geo-campaigns-downloaded"];
    [self verifyDownloadedLogDetail:logDetails withVariantId:123];
}

- (void)enableQaLogging {
    NSDictionary *jsonQa = @{
                             @"logging": @true,
                             @"logging_url": @"http://123.swrve.com",
                             @"campaigns": @{}
                             };
    [SwrveQA updateQAUser:jsonQa];
}

- (NSDictionary* )verifyQaLogEvent:(NSData*) capturedJson withLogType:(NSString *) logType{
    
    NSError* error;
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:capturedJson options:kNilOptions error:&error];
    XCTAssertEqual(6, [json count]);
    XCTAssertTrue([json objectForKey:@"app_version"]);
    XCTAssertEqualObjects([json objectForKey:@"app_version"], @"myappversion");
    XCTAssertTrue([json objectForKey:@"session_token"]);
    XCTAssertTrue([json objectForKey:@"unique_device_id"]);
    XCTAssertEqualObjects([json objectForKey:@"unique_device_id"], @"my_device_id");
    XCTAssertTrue([json objectForKey:@"user"]);
    XCTAssertEqualObjects([json objectForKey:@"user"], @"my_user_id");
    XCTAssertTrue([json objectForKey:@"version"]);
    XCTAssertEqualObjects([json objectForKey:@"version"], [NSNumber numberWithInt:3]);
    
    XCTAssertTrue([json objectForKey:@"data"]);
    NSArray *dataArray = [json objectForKey:@"data"];
    XCTAssertEqual(1, [dataArray count]);
    
    NSDictionary *data = [dataArray objectAtIndex:0];
    XCTAssertEqual(6, [data count]);
    XCTAssertTrue([data objectForKey:@"log_source"]);
    XCTAssertEqualObjects([data objectForKey:@"log_source"], @"geo-sdk");
    XCTAssertTrue([data objectForKey:@"log_type"]);
    XCTAssertEqualObjects([data objectForKey:@"log_type"], logType);
    XCTAssertTrue([data objectForKey:@"seqnum"]);
    XCTAssertTrue([data objectForKey:@"time"]);
    XCTAssertTrue([data objectForKey:@"type"]);
    XCTAssertEqualObjects([data objectForKey:@"type"], @"qa_log_event");
    
    XCTAssertTrue([data objectForKey:@"log_details"]);
    NSDictionary *logDetails = [data objectForKey:@"log_details"];
    return logDetails;
}

- (void)verifyTriggeredLogDetail:(NSDictionary *)logDetails withDisplayed:(long)displayed andReason:(NSString *)reason andVariantId:(long)variantId {
    XCTAssertTrue([logDetails objectForKey:@"campaigns"]);
    NSArray *campaignsArray = [logDetails objectForKey:@"campaigns"];
    XCTAssertEqual(1, [campaignsArray count]);
    
    NSDictionary *campaigns = [campaignsArray objectAtIndex:0];
    XCTAssertEqual(3, [campaigns count]);
    XCTAssertTrue([campaigns objectForKey:@"displayed"]);
    XCTAssertEqualObjects([campaigns objectForKey:@"displayed"], [NSNumber numberWithLong:displayed]);
    XCTAssertTrue([campaigns objectForKey:@"reason"]);
    XCTAssertEqualObjects([campaigns objectForKey:@"reason"], reason);
    XCTAssertTrue([campaigns objectForKey:@"variant_id"]);
    XCTAssertEqualObjects([campaigns objectForKey:@"variant_id"], [NSNumber numberWithLong:variantId]);
}

- (void)verifyDownloadedLogDetail:(NSDictionary *)logDetails withVariantId:(long)variantId {
    XCTAssertTrue([logDetails objectForKey:@"campaigns"]);
    NSArray *campaignsArray = [logDetails objectForKey:@"campaigns"];
    XCTAssertEqual(1, [campaignsArray count]);
    
    NSDictionary *campaigns = [campaignsArray objectAtIndex:0];
    XCTAssertEqual(1, [campaigns count]);
    XCTAssertTrue([campaigns objectForKey:@"variant_id"]);
    XCTAssertEqualObjects([campaigns objectForKey:@"variant_id"], [NSNumber numberWithLong:variantId]);
}

@end

