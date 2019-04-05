#import <XCTest/XCTest.h>
#import "SwrveTrigger.h"
#import "SwrveTriggerCondition.h"

@interface SwrveTestTriggersAndConditions : XCTestCase

@end

@implementation SwrveTestTriggersAndConditions

#pragma mark - test Trigger Objects

- (void) testSwrveTriggerConstruction {
    
    NSDictionary *triggerJSON = @{@"event_name": @"test.eventName",
                                  @"conditions" :
                                      @{@"args":
                                            @[@{@"key" : @"key1", @"value" : @"value1", @"op" : @"eq"},
                                              @{@"key" : @"key2", @"value" : @"value2", @"op" : @"eq"}],
                                        @"op" : @"and"
                                        }
                                  };
    
    SwrveTrigger *trigger = [[SwrveTrigger alloc] initWithDictionary:triggerJSON];
    XCTAssertNotNil(trigger.eventName);
    XCTAssertEqualObjects(trigger.eventName, [@"test.eventName" lowercaseString]);
    XCTAssertNotNil(trigger.conditions);
    
    //test first condition
    SwrveTriggerCondition *condition = [trigger.conditions firstObject];
    XCTAssertEqualObjects(condition.key, @"key1");
    XCTAssertEqualObjects(condition.value, @"value1");
    XCTAssertEqual(condition.triggerOperator, SwrveTriggerOperatorAND);
    XCTAssertEqual(condition.conditionOperator, SwrveTriggerOperatorEQUALS);
    
    XCTAssert(trigger.isValidTrigger);
    
    //test second condition
    condition = [trigger.conditions lastObject];
    XCTAssertEqualObjects(condition.key, @"key2");
    XCTAssertEqualObjects(condition.value, @"value2");
    XCTAssertEqual(condition.triggerOperator, SwrveTriggerOperatorAND);
    XCTAssertEqual(condition.conditionOperator, SwrveTriggerOperatorEQUALS);
    
    XCTAssert(trigger.isValidTrigger);
}

- (void) testCanTriggerWithPayload {
    
    NSDictionary *triggerJSON = @{@"event_name": @"test.eventName",
                                  @"conditions" :
                                      @{@"args":
                                            @[@{@"key" : @"key1", @"value" : @"value1", @"op" : @"eq"},
                                              @{@"key" : @"key2", @"value" : @"value2", @"op" : @"eq"}],
                                        @"op" : @"and"
                                        }
                                  };
    
    SwrveTrigger *trigger = [[SwrveTrigger alloc] initWithDictionary:triggerJSON];
    
    NSDictionary *payloadJSON =  @{@"key1" : @"value1",
                                   @"key2" : @"value2"
                                   };
    
    XCTAssert([trigger canTriggerWithPayload:payloadJSON], @"This payload should pass all conditions");
    
    payloadJSON = @{@"key1" : @"value1"};
    XCTAssertFalse([trigger canTriggerWithPayload:payloadJSON], @"This payload should not pass");
    
    payloadJSON =  @{};
    XCTAssertFalse([trigger canTriggerWithPayload:payloadJSON], @"This payload should not pass");
    
    payloadJSON = nil;
    XCTAssertFalse([trigger canTriggerWithPayload:payloadJSON], @"This payload should not pass");
    
    payloadJSON = @{@"key2" : @"value2"};
    XCTAssertFalse([trigger canTriggerWithPayload:payloadJSON], @"This payload should not pass");
    
}

- (void) testSwrveInvalidTrigger {
    
    NSDictionary *triggerJSON = @{@"event_name": @"test.eventName",
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

- (void) testSwrveMultipleConditonsNoOperator {
    
    NSDictionary *triggerJSON = @{@"event_name": @"test.eventName",
                                  @"conditions" :
                                      @{@"args":
                                            @[@{@"key" : @"key1", @"value" : @"value1", @"op" : @"eq"},
                                              @{@"key" : @"key2", @"value" : @"value2", @"op" : @"eq"}]
                                        }
                                  };
    
    SwrveTrigger *trigger = [[SwrveTrigger alloc] initWithDictionary:triggerJSON];
    XCTAssertFalse([trigger isValidTrigger], @"This should be an invalid Trigger");
}

- (void) testSwrveSingleConditionWithOperatorTrigger {
    
    NSDictionary *triggerJSON = @{@"event_name": @"test.eventName",
                                  @"conditions" :
                                      @{@"args":
                                            @[@{@"key" : @"key1", @"value" : @"value1", @"op" : @"eq"}],
                                        @"op" : @"and"
                                        }
                                  };
    
    SwrveTrigger *trigger = [[SwrveTrigger alloc] initWithDictionary:triggerJSON];
    XCTAssertFalse([trigger isValidTrigger], @"This should be an invalid Trigger");
}

- (void) testSwrveSingleConditionNoOperatorsForTrigger {
    
    NSDictionary *triggerJSON = @{@"event_name": @"test.eventName",
                                  @"conditions":@{@"key" : @"key1", @"value" : @"value1", @"op" : @"eq"}
                                  };
    
    SwrveTrigger *trigger = [[SwrveTrigger alloc] initWithDictionary:triggerJSON];
    XCTAssert([trigger isValidTrigger], @"This should be a valid Trigger");
}


@end
