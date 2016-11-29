#import "SwrveCommon.h"

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

@end
