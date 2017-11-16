#import "SwrveTestHelper.h"
#import "SwrvePush.h"
#import "SwrveLocalStorage.h"
#import "Swrve.h"
#import "SwrveSDK.h"

@interface SwrveSDK (InternalAccess)

+ (void)resetSwrveSharedInstance;

@end

@implementation SwrveTestHelper

+ (void)tearDown {
    [SwrveTestHelper deleteUserDefaults];
    [SwrveTestHelper deleteFilesInDirectory:[SwrveTestHelper rootCacheDirectory]];
    [SwrveTestHelper deleteFilesInDirectory:[SwrveTestHelper rootApplicationSupportDirectory]];
    [SwrveTestHelper deleteFilesInDirectory:[SwrveLocalStorage documentPath]];
    [SwrveTestHelper destroySharedInstance];
}

+ (void)destroySharedInstance {
    [SwrveSDK resetSwrveSharedInstance];
    [SwrvePush resetSharedInstance];
}

+ (NSString *)rootCacheDirectory {
    static NSString *_dir = nil;
    if (!_dir) {
        _dir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    }
    return _dir;
}

+ (NSString *)rootApplicationSupportDirectory {
    static NSString *_dir = nil;
    if (!_dir) {
        _dir = [SwrveLocalStorage applicationSupportPath];
    }
    return _dir;
}

+ (void)deleteFilesInDirectory:(NSString *)directory {
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSArray *fileArray = [fileMgr contentsOfDirectoryAtPath:directory error:nil];
    for (NSString *filename in fileArray) {
        [fileMgr removeItemAtPath:[directory stringByAppendingPathComponent:filename] error:NULL];
    }
}

+ (void)deleteUserDefaults {
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
