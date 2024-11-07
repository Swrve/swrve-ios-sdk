#import <Foundation/Foundation.h>

#if __has_include(<SwrveSDK/Swrve.h>)
#import <SwrveSDK/Swrve.h>
#else
#import "Swrve.h"
#endif

@interface SwrveMigrationsManager : NSObject

- (id)initWithConfig:(SwrveConfig *)swrveConfig;
- (void)checkMigrations;

@end
