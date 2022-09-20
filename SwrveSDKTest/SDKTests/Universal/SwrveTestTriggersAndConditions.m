#import <XCTest/XCTest.h>
#import "SwrveTrigger.h"
#import "SwrveTriggerCondition.h"

@interface SwrveTestTriggersAndConditions : XCTestCase

@end

@implementation SwrveTestTriggersAndConditions

#pragma mark - test Trigger Objects

- (void) testSwrveTriggerConstructionAND {
    
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

- (void) testSwrveTriggerConstructionOR {
    
    NSDictionary *triggerJSON = @{@"event_name": @"test.eventName",
                                  @"conditions" :
                                      @{@"args":
                                            @[@{@"key" : @"key1", @"value" : @"value1", @"op" : @"eq"},
                                              @{@"key" : @"key2", @"value" : @"value2", @"op" : @"eq"}],
                                        @"op" : @"or"
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
    XCTAssertEqual(condition.triggerOperator, SwrveTriggerOperatorOR);
    XCTAssertEqual(condition.conditionOperator, SwrveTriggerOperatorEQUALS);
    
    XCTAssert(trigger.isValidTrigger);
    
    //test second condition
    condition = [trigger.conditions lastObject];
    XCTAssertEqualObjects(condition.key, @"key2");
    XCTAssertEqualObjects(condition.value, @"value2");
    XCTAssertEqual(condition.triggerOperator, SwrveTriggerOperatorOR);
    XCTAssertEqual(condition.conditionOperator, SwrveTriggerOperatorEQUALS);
    
    XCTAssert(trigger.isValidTrigger);
}

- (void) testCanTriggerWithPayloadAND {
    
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

- (void) testCanTriggerWithPayloadOR {
    
    NSDictionary *triggerJSON = @{@"event_name": @"test.eventName",
                                  @"conditions" :
                                      @{@"args":
                                            @[@{@"key" : @"key1", @"value" : @"value1", @"op" : @"eq"},
                                              @{@"key" : @"key2", @"value" : @"value2", @"op" : @"eq"}],
                                        @"op" : @"or"
                                        }
                                  };
    
    SwrveTrigger *trigger = [[SwrveTrigger alloc] initWithDictionary:triggerJSON];
    
    NSDictionary *payloadJSON =  @{@"key1" : @"value1",
                                   @"key2" : @"value2"
                                   };
    
    XCTAssert([trigger canTriggerWithPayload:payloadJSON], @"This payload should pass all conditions");
    
    payloadJSON = @{@"key1" : @"value1"};
    XCTAssertTrue([trigger canTriggerWithPayload:payloadJSON], @"This payload should pass");
    
    payloadJSON = @{@"key2" : @"value2"};
    XCTAssertTrue([trigger canTriggerWithPayload:payloadJSON], @"This payload should pass");
    
    payloadJSON =  @{};
    XCTAssertFalse([trigger canTriggerWithPayload:payloadJSON], @"This payload should not pass");

    payloadJSON = nil;
    XCTAssertFalse([trigger canTriggerWithPayload:payloadJSON], @"This payload should not pass");

}

- (void) testCanTriggerWithPayloadCONTAINS {
    
    NSDictionary *triggerJSON = @{@"event_name": @"music.condition1",
                                  @"conditions":@{@"key" : @"artist", @"value" : @"david", @"op" : @"contains"}
                                  };
    
    SwrveTrigger *trigger = [[SwrveTrigger alloc] initWithDictionary:triggerJSON];
    
    NSDictionary *payloadJSON =  @{@"artist" : @"david bowie"};
    
    XCTAssertTrue([trigger canTriggerWithPayload:payloadJSON], @"This payload should pass");
    
    payloadJSON = @{@"artist" : @"Gray David"};
    XCTAssertTrue([trigger canTriggerWithPayload:payloadJSON], @"This payload should pass");
    
    payloadJSON = @{@"artist" : @"Dave Ghrol"};
    XCTAssertFalse([trigger canTriggerWithPayload:payloadJSON], @"This payload should not pass");
}

- (void) testCanTriggerWithPayloadCONTAINSwithOR {
    
    NSDictionary *triggerJSON = @{@"event_name": @"test.eventName",
                                  @"conditions" :
                                      @{@"args":
                                            @[@{@"key" : @"artist", @"value" : @"david", @"op" : @"contains"},
                                              @{@"key" : @"artist", @"value" : @"Bob", @"op" : @"contains"},
                                              @{@"key" : @"artist", @"value" : @"Paul", @"op" : @"contains"}],
                                        @"op" : @"or"
                                        }
                                  };
    
    SwrveTrigger *trigger = [[SwrveTrigger alloc] initWithDictionary:triggerJSON];
    
    NSDictionary *payloadJSON =  @{@"artist" : @"David.Bowie"};
    
    XCTAssertTrue([trigger canTriggerWithPayload:payloadJSON], @"This payload should pass");

    payloadJSON =  @{@"artist" : @"Bobby.Brown"};
    XCTAssertTrue([trigger canTriggerWithPayload:payloadJSON], @"This payload should pass");

    payloadJSON =  @{@"artist" : @"Paul.mcCartney"};
    XCTAssertTrue([trigger canTriggerWithPayload:payloadJSON], @"This payload should pass");
    
    triggerJSON = @{@"event_name": @"test.eventName",
                                  @"conditions" :
                                      @{@"args":
                                            @[@{@"key" : @"genre", @"value" : @"rock", @"op" : @"contains"},
                                              @{@"key" : @"genre", @"value" : @"metal", @"op" : @"contains"},
                                              @{@"key" : @"artist", @"value" : @"ac/dc", @"op" : @"contains"}],
                                        @"op" : @"or"
                                        }
                                  };
    
    trigger = [[SwrveTrigger alloc] initWithDictionary:triggerJSON];
    
    payloadJSON =  @{@"artist" : @"Axl.Rose",
                                   @"genre" : @"RocknRoll"
                                   };
    XCTAssertTrue([trigger canTriggerWithPayload:payloadJSON], @"This payload should pass");

    payloadJSON =  @{@"artist" : @"AC/DC"};
    XCTAssertTrue([trigger canTriggerWithPayload:payloadJSON], @"This payload should pass");

}

- (void) testCanTriggerWithPayloadCONTAINSwithAND {
    
    NSDictionary *triggerJSON = @{@"event_name": @"test.eventName",
                                  @"conditions" :
                                      @{@"args":
                                            @[@{@"key" : @"genre", @"value" : @"rock", @"op" : @"contains"},
                                              @{@"key" : @"artist", @"value" : @"ac/dc", @"op" : @"contains"}],
                                        @"op" : @"and"
                                        }
                                  };
    
    SwrveTrigger *trigger = [[SwrveTrigger alloc] initWithDictionary:triggerJSON];
    
    NSDictionary *payloadJSON =  @{@"artist" : @"AC/DC",
                                   @"genre" : @"Rock"
                                   };
    
    XCTAssertTrue([trigger canTriggerWithPayload:payloadJSON], @"This payload should pass");

    payloadJSON =  @{@"artist" : @"AC/DC"};
    XCTAssertFalse([trigger canTriggerWithPayload:payloadJSON], @"This payload should not pass");
    
    triggerJSON = @{@"event_name": @"test.eventName",
                                  @"conditions" :
                                      @{@"args":
                                            @[@{@"key" : @"genre", @"value" : @"pop", @"op" : @"eq"},
                                              @{@"key" : @"artist", @"value" : @"beatle", @"op" : @"contains"}],
                                        @"op" : @"and"
                                        }
                                  };
    
    trigger = [[SwrveTrigger alloc] initWithDictionary:triggerJSON];
    
    payloadJSON =  @{@"artist" : @"Taylor Swift",
                                   @"genre" : @"pop"
                                   };
    
    XCTAssertFalse([trigger canTriggerWithPayload:payloadJSON], @"This payload should not pass");

    payloadJSON =  @{@"artist" : @"Beatles",
                                   @"genre" : @"pop"
                                   };
    
    XCTAssertTrue([trigger canTriggerWithPayload:payloadJSON], @"This payload should pass");
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
                                              @{@"key" : @"key2", @"value" : @"value2", @"op" : @"contains"}]
                                        }
                                  };
    
    SwrveTrigger *trigger = [[SwrveTrigger alloc] initWithDictionary:triggerJSON];
    XCTAssertFalse([trigger isValidTrigger], @"This should be an invalid Trigger");
}

- (void) testSwrveSingleConditionWithOperatorTriggerAND {
    
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

- (void) testSwrveSingleConditionWithOperatorTriggerOR {
    
    NSDictionary *triggerJSON = @{@"event_name": @"test.eventName",
                                  @"conditions" :
                                      @{@"args":
                                            @[@{@"key" : @"key1", @"value" : @"value1", @"op" : @"eq"}],
                                        @"op" : @"or"
                                        }
                                  };
    
    SwrveTrigger *trigger = [[SwrveTrigger alloc] initWithDictionary:triggerJSON];
    XCTAssertTrue([trigger isValidTrigger], @"This should be valid Trigger");
}

- (void) testSwrveSingleConditionNoOperatorsForTrigger {
    
    NSDictionary *triggerJSON = @{@"event_name": @"test.eventName",
                                  @"conditions":@{@"key" : @"key1", @"value" : @"value1", @"op" : @"eq"}
                                  };
    
    SwrveTrigger *trigger = [[SwrveTrigger alloc] initWithDictionary:triggerJSON];
    XCTAssert([trigger isValidTrigger], @"This should be a valid Trigger");
}

- (void)testSwrveNoConditionsForTrigger {
    
    NSDictionary *triggerJSON = @{@"event_name": @"test.eventName",
                                  @"conditions":@{}
                                  };
    
    SwrveTrigger *trigger = [[SwrveTrigger alloc] initWithDictionary:triggerJSON];
    XCTAssert([trigger isValidTrigger], @"This should be a valid Trigger");
}

@end
