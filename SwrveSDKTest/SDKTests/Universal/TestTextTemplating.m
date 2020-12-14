#import <XCTest/XCTest.h>
#import "TextTemplating.h"

@interface TestTextTemplating : XCTestCase

@end

@implementation TestTextTemplating

- (void)testTemplatingWithMissingProperties {
    NSError *error = nil;
    NSDictionary *properties = @{
            @"itemLabel": @"swrve"
    };
    NSString *string = @"Welcome to ${item.label}. And another ${key1}/${key2}";
    NSString *templatedText = [TextTemplating templatedTextFromString:string withProperties:properties andError:&error];
    XCTAssertNil(templatedText, "Should be nil because property was missing and there is no fallback.");
    XCTAssertNotNil(error, "Should be an error because property was missing and there is no fallback.");
}

- (void)testTemplatingWithValidProperties {
    NSError *error = nil;
    NSDictionary *properties = @{
            @"campaignId": @"1",
            @"item.label": @"swrve",
            @"key1": @"value1",
            @"key2": @"value2",
            @"key_not_used": @"value_not_used"
    };
    NSString *string = @"Welcome to ${item.label}. And another ${key1}/${key2} And another ${key1}/${key2}";
    NSString *templatedText = [TextTemplating templatedTextFromString:string withProperties:properties andError:&error];
    XCTAssertEqualObjects(templatedText, @"Welcome to swrve. And another value1/value2 And another value1/value2");
}

- (void)testTemplatingDeeplink {
    NSError *error = nil;
    NSDictionary *properties = @{
            @"campaignId": @"1",
            @"item.label": @"swrve",
            @"key1": @"value1",
            @"key2": @"value2",
            @"key_not_used": @"value_not_used"
    };
    NSString *string = @"http://someurl.com/${item.label}/key1=${key1}&blah=${key2}&key1=${key1}";
    NSString *templatedText = [TextTemplating templatedTextFromString:string withProperties:properties andError:&error];
    XCTAssertEqualObjects(templatedText, @"http://someurl.com/swrve/key1=value1&blah=value2&key1=value1");
}

- (void)testTemplatingWithFallback {
    NSError *error = nil;
    NSDictionary *properties = @{
            @"campaignId": @"1",
            @"item.label": @"some_label",
            @"key1": @"value1",
            @"key2": @"value2",
            @"key_not_used": @"value_not_used"
    };
    NSString *string = @"Welcome to ${item.label}. And another ${key1}/${key2} ${item.label|fallback=\"fallback property\"}";
    NSString *templatedText = [TextTemplating templatedTextFromString:string withProperties:properties andError:&error];
    XCTAssertEqualObjects(templatedText, @"Welcome to some_label. And another value1/value2 some_label");
}

- (void)testTemplatingWithFallback2 {
    NSError *error = nil;
    NSDictionary *properties = @{
            @"campaignId": @"1",
            @"key1": @"value1",
            @"key2": @"value2",
            @"key_not_used": @"value_not_used"
    };
    NSString *string = @"Welcome to ${item.label|fallback=\"the Jungle\"}! And another ${key1}/${key2}/${key3|fallback=\"value3\"} ${item.label|fallback=\"bye\"}";
    NSString *templatedText = [TextTemplating templatedTextFromString:string withProperties:properties andError:&error];
    XCTAssertEqualObjects(templatedText, @"Welcome to the Jungle! And another value1/value2/value3 bye");
}

- (void)testTemplatingWithFallback3 {
    NSError *error = nil;
    NSDictionary *properties = @{
            @"campaignId": @"1",
            @"key1": @"value1"
    };
    NSString *string = @"http://www.deeplink.com/param1=${param1|fallback=\"1\"}&param2=${param2|fallback=\"2\"}";
    NSString *templatedText = [TextTemplating templatedTextFromString:string withProperties:properties andError:&error];
    XCTAssertEqualObjects(templatedText, @"http://www.deeplink.com/param1=1&param2=2");
}

@end
