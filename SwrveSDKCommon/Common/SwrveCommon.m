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

+ (NSString *)swrveCacheFolder {
    NSString *cacheRoot = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *swrve_folder = @"com.ngt.msgs";
    NSString *cacheFolder = [cacheRoot stringByAppendingPathComponent:swrve_folder];
    return cacheFolder;
}

+(BOOL)supportedOS {
  // Detect if the SDK can run on this OS
  return SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0");
}

+ (UIApplication *) sharedUIApplication {
/** Since Apple Extensions do not support shared Application, we have to dummy them when running just on an extension **/    
#if !(defined(__has_feature) && __has_feature(attribute_availability_app_extension))
    return [UIApplication sharedApplication];
#else
    // WARNING: this should never be called from an extension
    return [UIApplication performSelector:@selector(sharedApplication)];
#endif
}

@end
