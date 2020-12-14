#import <Foundation/Foundation.h>
#import "Swrve.h"

@interface SwrveMigrationsManager : NSObject

- (id)initWithConfig:(ImmutableSwrveConfig *)swrveConfig;
- (void)checkMigrations;

@end
