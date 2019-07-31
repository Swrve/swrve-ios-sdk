#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SwrveSDK.h"
#import "SwrveTestHelper.h"
#import "SwrvePermissions.h"
#import "SwrveConversationEvents.h"

@interface Swrve ()
- (void)setCustomPayloadForSurvey:(NSMutableDictionary *)payload;
@end

@interface SwrveTestCustomPayloads : XCTestCase

@end

@implementation SwrveTestCustomPayloads

- (void)setUp {
    [super setUp];
    [SwrveTestHelper setUp];
    
    [SwrveConversationEvents setCustomPayload:[NSMutableDictionary new]];
    
#if TARGET_OS_IOS /** exclude tvOS **/
    id classMock = OCMClassMock([SwrvePermissions class]);
    OCMStub(ClassMethod([classMock pushAuthorizationWithSDK:OCMOCK_ANY])).andReturn(@"unittest");
#endif

 }

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [super tearDown];
}

- (void)testAddPayload_MoreThenMaxAllowed {
    
    Swrve *swrve = [Swrve alloc];
    id swrveMock = OCMPartialMock(swrve);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrve initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop
    
    // > 5 key pair values
    NSMutableDictionary *dic = [[NSMutableDictionary alloc]initWithDictionary:@{
                                                                                 @"key1":@"value1",
                                                                                 @"key2":@"value2",
                                                                                 @"key3":@"value3",
                                                                                 @"key4":@"value4",
                                                                                 @"key5":@"value5",
                                                                                 @"key6":@"value6"
                                                                               }];
    
    [swrveMock setCustomPayloadForConversationInput:dic];
    XCTAssertEqualObjects([SwrveConversationEvents customPayload],@{});
}

- (void)testAddPayload_RestrictedKeys {

    Swrve *swrve = [Swrve alloc];
    id swrveMock = OCMPartialMock(swrve);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrve initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop

    NSMutableDictionary *dic = [[NSMutableDictionary alloc]initWithDictionary:@{@"event":@"value"}];
    [swrveMock setCustomPayloadForConversationInput:dic];
    XCTAssertEqualObjects([SwrveConversationEvents customPayload],@{});

    dic = [[NSMutableDictionary alloc]initWithDictionary:@{@"to":@"value"}];
    [swrveMock setCustomPayloadForConversationInput:dic];
    XCTAssertEqualObjects([SwrveConversationEvents customPayload],@{});

    dic = [[NSMutableDictionary alloc]initWithDictionary:@{@"page":@"value"}];
    [swrveMock setCustomPayloadForConversationInput:dic];
    XCTAssertEqualObjects([SwrveConversationEvents customPayload],@{});

    dic = [[NSMutableDictionary alloc]initWithDictionary:@{@"conversation":@"value"}];
    [swrveMock setCustomPayloadForConversationInput:dic];
    XCTAssertEqualObjects([SwrveConversationEvents customPayload],@{});

    dic = [[NSMutableDictionary alloc]initWithDictionary:@{@"control":@"value"}];
    [swrveMock setCustomPayloadForConversationInput:dic];
    XCTAssertEqualObjects([SwrveConversationEvents customPayload],@{});

    dic = [[NSMutableDictionary alloc]initWithDictionary:@{@"fragment":@"value"}];
    [swrveMock setCustomPayloadForConversationInput:dic];
    XCTAssertEqualObjects([SwrveConversationEvents customPayload],@{});

    dic = [[NSMutableDictionary alloc]initWithDictionary:@{@"result":@"value"}];
    [swrveMock setCustomPayloadForConversationInput:dic];
    XCTAssertEqualObjects([SwrveConversationEvents customPayload],@{});

    dic = [[NSMutableDictionary alloc]initWithDictionary:@{@"name":@"value"}];
    [swrveMock setCustomPayloadForConversationInput:dic];
    XCTAssertEqualObjects([SwrveConversationEvents customPayload],@{});

    dic = [[NSMutableDictionary alloc]initWithDictionary:@{@"id":@"value"}];
    [swrveMock setCustomPayloadForConversationInput:dic];
    XCTAssertEqualObjects([SwrveConversationEvents customPayload],@{});
}

- (void)testAddPayload {

    Swrve *swrve = [Swrve alloc];
    id swrveMock = OCMPartialMock(swrve);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrve initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop

    XCTAssertTrue([[SwrveConversationEvents customPayload] count] == 0);

    NSMutableDictionary *customPayload = [[NSMutableDictionary alloc]initWithDictionary:@{
                                                                                @"key1":@"value1",
                                                                                @"key2":@"value2",
                                                                                @"key3":@"value3",
                                                                                @"key4":@"value4",
                                                                                @"key5":@"value5"
                                                                                }];

    [swrveMock setCustomPayloadForConversationInput:customPayload];
    XCTAssertTrue([[SwrveConversationEvents customPayload] count] == 5);
    XCTAssertEqualObjects([SwrveConversationEvents customPayload], customPayload);
}

@end
