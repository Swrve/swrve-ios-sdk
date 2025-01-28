#import <XCTest/XCTest.h>
#import "SwrveTestHelper.h"

#if TARGET_OS_TV
#import "SwrveSDK_tvOSTests-Swift.h"
#else
#import "SwrveSDK_iOSTests-Swift.h"
#endif

@interface Swrve (Internal)
@property(atomic) SwrveSignatureProtectedFile *realTimeUserPropertiesFile;
- (void)appDidBecomeActive:(NSNotification *)notification;
- (void)updateResources:(NSArray *)resourceJson writeToCache:(BOOL)writeToCache;
@end

@interface SwrveTestRealTimeUserProperties : XCTestCase

@end


@implementation SwrveTestRealTimeUserProperties

 - (void)testRealTimeUserProperties {
     NSString *testCacheFileContents = @"{\"test_property1\": \"test_value1\"}";

     // Initialise Swrve and write to resources cache file
     Swrve *swrveMock = [SwrveTestHelper swrveBasicMockResponse];
     swrveMock = [swrveMock initWithAppID:572 apiKey:@"SomeAPIKey"];
     [swrveMock appDidBecomeActive:nil];
     [[swrveMock realTimeUserPropertiesFile] writeWithRespectToPlatform:[testCacheFileContents dataUsingEncoding:NSUTF8StringEncoding]];
     
     // Restart swrve, getting real time user properties from API will fail, so real time user properties are initialised by cache
     [swrveMock shutdown];
     swrveMock = [SwrveTestHelper swrveBasicMockResponse];
     swrveMock = [swrveMock initWithAppID:572 apiKey:@"SomeAPIKey"];
     [swrveMock appDidBecomeActive:nil];

     [swrveMock realTimeUserProperties:^(NSDictionary *properties) {
        NSArray *keys = [properties allKeys];
        XCTAssertEqual(1, [keys count]);
        XCTAssertEqualObjects([properties objectForKey:@"test_property1"], @"test_value1");
     }];
 }

- (void)testRealTimeUserPropertiesFromFile {
    SwrveConfig* config = [[SwrveConfig alloc] init];
    Swrve *swrve = [SwrveTestHelper initializeSwrveWithRealTimeUserPropertiesFile:@"realTimeUserProperties" andConfig:config];
    [swrve realTimeUserProperties:^(NSDictionary *properties) {
        NSArray *keys = [properties allKeys];
        XCTAssertEqual(2, [keys count]);
        XCTAssertEqualObjects([properties objectForKey:@"test1"], @"rtup_value1");
        XCTAssertEqualObjects([properties objectForKey:@"test2"], @"rtup_value2");
    }];
    
}

@end
