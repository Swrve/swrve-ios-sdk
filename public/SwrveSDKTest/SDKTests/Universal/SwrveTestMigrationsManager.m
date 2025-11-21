
#import <XCTest/XCTest.h>
#import "SwrveTestHelper.h"
#import "SwrveMigrationsManager.h"
#include "TargetConditionals.h"

@interface SwrveMigrationsManager (SwrveInternalAccess)

- (void)migrateOldCacheFile:(NSString *)oldPath withNewPath:(NSString *)newPath;

@end

@interface SwrveTestMigrationsManager : XCTestCase

@end

@implementation SwrveTestMigrationsManager

- (void)setUp {
    [super setUp];
    [SwrveTestHelper setUp];
}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [super tearDown];
}



@end
