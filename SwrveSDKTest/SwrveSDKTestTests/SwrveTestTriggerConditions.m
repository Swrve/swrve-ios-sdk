#import <XCTest/XCTest.h>
#import "Swrve.h"
#import "SwrveTrigger.h"
#import "SwrveTriggerCondition.h"

@interface SwrveTestTriggerConditions : XCTestCase

@end

@implementation SwrveTestTriggerConditions

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


- (void) testSwrveInvalidTrigger {
    
    NSDictionary *triggerJSON = @{@"event_name": @"test.testTrigger",
                                  @"conditions" :
                                      @{@"args":
                                            @[@{@"key" : @"key1", @"value" : @"value1", @"op" : @"eq"},
                                              @{@"key" : @"key2", @"value" : @"value2", @"op" : @"eq"}],
                                        @"op" : @"random"
                                        }
                                  };
    
    SwrveTrigger *trigger = [[SwrveTrigger alloc] initWithDictionary:triggerJSON];
    XCTAssertFalse([trigger isValidTrigger], @"This should be an invalid Trigger");
}

@end
