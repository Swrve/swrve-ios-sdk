#import <XCTest/XCTest.h>

#include "SwrveSwizzleHelper.h"
#import "SwrveTestHelper.h"

typedef void (*increaseSignature)(__strong id,SEL);

// Simple test class
@interface TestClassImplemented : NSObject
@property (nonatomic) int counter;
@property (nonatomic, retain) NSString* name;
- (void)increase;
@end
@implementation TestClassImplemented
@synthesize counter;
@synthesize name;
- (void)increase {
    self.counter = self.counter + 20;
}
@end

// Hierarchy test class
@interface TestClassSuper : NSObject {
    int privateCounter;
}
@property (nonatomic) int counter;
@property (nonatomic, retain) NSString* name;
- (void)increase;
- (int)privateCounter;
@end
@implementation TestClassSuper
@synthesize counter;
@synthesize name;
- (void)increase {
    self.counter = self.counter + 20;
    // Private member
    privateCounter = privateCounter + 1;
    // Private method
    [self increasePrivateCounter];
}
- (void)increasePrivateCounter {
    // Access private member
    privateCounter = privateCounter + 10;
}
- (int)privateCounter {
    return privateCounter;
}
@end

@interface TestClass : TestClassSuper
@end
@implementation TestClass
@end

// Non-implementation class
@interface TestClassNoImplementation : NSObject
@property (nonatomic) int counter;
@property (nonatomic, retain) NSString* name;
@end
@implementation TestClassNoImplementation
@synthesize counter;
@synthesize name;
@end

// Class used to replace the implementation
@interface ReplaceClass : NSObject
- (void)increase;
+ (increaseSignature)originalMethod;
+ (void)setOriginalMethod:(increaseSignature) m;
@property (nonatomic) int counter;
@property (nonatomic, retain) NSString* name;
@end

@implementation ReplaceClass
@synthesize counter;
@synthesize name;
static increaseSignature originalMethod;
// This function will be used to replace the classe's method
- (void)increase {
    self.name = @"swizzled";
    self.counter = self.counter + 100;

    // Call the original method, just like the SDK will do with AppDelegate
    if( originalMethod != NULL ) {
        originalMethod(self, @selector(increase));
    }
}

+ (increaseSignature)originalMethod {
    return originalMethod;
}

+ (void)setOriginalMethod:(increaseSignature) m {
    originalMethod = m;
}
@end


// Tests
@interface SwrveTestSwizzleHelper : XCTestCase
@end

@implementation SwrveTestSwizzleHelper
- (void)setUp {
    [super setUp];
    [ReplaceClass setOriginalMethod:nil];
    [SwrveTestHelper setUp];
}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [ReplaceClass setOriginalMethod:nil];
    [super tearDown];
}

- (void)testNormalBehaviour
{
    // Normal behaviour
    TestClass* c = [TestClass new];
    [c increase];
    XCTAssertEqual(c.counter, 20);
}

- (void)testSwizzleHasImplementation
{
    TestClassImplemented* c = [TestClassImplemented new];
    ReplaceClass* r = [ReplaceClass new];

    // Swizzle the increase method
    SEL selector = @selector(increase);
    increaseSignature originalMethod = (increaseSignature)[SwrveSwizzleHelper swizzleMethod:selector inClass:[c class] withImplementationIn:r];
    // Save instance to the original method like the SDK would do
    [ReplaceClass setOriginalMethod:originalMethod];

    // Will execute the TestClassImplemented with the ReplaceClass method
    // that will call the parent one too
    [c increase];
    XCTAssertEqual(r.counter, 0);
    XCTAssertNil(r.name);

    XCTAssertEqualObjects(c.name, @"swizzled");
    XCTAssertEqual(c.counter, 120);

    // Deswizzle to leave the state as the beginning of the test
    [SwrveSwizzleHelper deswizzleMethod:selector inClass:[c class] originalImplementation:(IMP)originalMethod];
}

- (void)testSwizzleParentHasImplementation
{
    TestClass* c = [TestClass new];
    ReplaceClass* r = [ReplaceClass new];

    // Swizzle the increase method
    SEL selector = @selector(increase);
    increaseSignature originalMethod = (increaseSignature)[SwrveSwizzleHelper swizzleMethod:selector inClass:[c class] withImplementationIn:r];
    // Save instance to the original method like the SDK would do
    [ReplaceClass setOriginalMethod:originalMethod];

    // Will execute the TestClass with the ReplaceClass method
    // that will call the parent one too
    [c increase];
    XCTAssertEqual(r.counter, 0);
    XCTAssertNil(r.name);

    XCTAssertEqualObjects(c.name, @"swizzled");
    XCTAssertEqual(c.counter, 120);
    XCTAssertEqual([c privateCounter], 11);

    // Deswizzle to leave the state as the beginning of the test
    [SwrveSwizzleHelper deswizzleMethod:selector inClass:[c class] originalImplementation:(IMP)originalMethod];

}

- (void)testSwizzleNoImplementation
{
    TestClassNoImplementation* c = [TestClassNoImplementation new];
    ReplaceClass* r = [ReplaceClass new];

    // Swizzle the increase method
    SEL selector = @selector(increase);
    increaseSignature originalMethod = (increaseSignature)[SwrveSwizzleHelper swizzleMethod:selector inClass:[c class] withImplementationIn:r];
    XCTAssertFalse((originalMethod != NULL));

    // Will execute the TestClassNoImplementation with the ReplaceClass method
    // that will call the parent one too
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [c  performSelector:selector];
#pragma clang diagnostic pop
    XCTAssertEqual(r.counter, 0);
    XCTAssertNil(r.name);

    XCTAssertEqualObjects(c.name, @"swizzled");
    XCTAssertEqual(c.counter, 100);

    // Deswizzle to leave the state as the beginning of the test
    [SwrveSwizzleHelper deswizzleMethod:selector inClass:[c class] originalImplementation:(IMP)originalMethod];
}

@end
