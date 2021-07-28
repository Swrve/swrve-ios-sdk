#import "SwrveCommon.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

static id <SwrveCommonDelegate> _sharedInstance = NULL;

@implementation SwrveCommon

+ (void)addSharedInstance:(id <SwrveCommonDelegate>)sharedInstance {
    _sharedInstance = sharedInstance;
}

+ (id <SwrveCommonDelegate>)sharedInstance {
    return _sharedInstance;
}

+ (BOOL)supportedOS {
  // Detect if the SDK can run on this OS
  return SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0");
}

+ (UIApplication *)sharedUIApplication {
    UIApplication *sharedApplication = nil;
    BOOL respondsToApplication = [UIApplication respondsToSelector:@selector(sharedApplication)];
    if (respondsToApplication) {
        sharedApplication = [UIApplication performSelector:@selector(sharedApplication)];
        if (!sharedApplication) {
            [SwrveLogger error:@"ApplicationNotAvailable - Service Extensions can't access a shared application"];
        }
    }
    return sharedApplication;
}

@end
