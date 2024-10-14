#import <Foundation/Foundation.h>
#import "Swrve.h"

@interface SwrveMigrationsManager : NSObject

- (id)initWithConfig:(SwrveConfig *)swrveConfig;
- (void)checkMigrations;

@end
