#import "SwrveTestHelper.h"
#import "SwrvePush.h"
#import "SwrveLocalStorage.h"
#import "Swrve.h"
#import "SwrveSDK.h"

@interface SwrvePush (InternalAccess)

+ (void)resetSharedInstance;

@end

@interface SwrveSDK (InternalAccess)

+ (void)resetSwrveSharedInstance;

@end

@implementation SwrveTestHelper

+ (void)setUp {
    [SwrveTestHelper tearDown];
}

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

+ (NSMutableArray *)stringArrayFromCachedContent:(NSString *)content {
    NSMutableArray *cacheLines = [[NSMutableArray alloc] initWithArray:[content componentsSeparatedByString:@"\n"]];
    [cacheLines removeLastObject];
    
    return cacheLines;
}

+ (NSMutableArray *)dicArrayFromCachedFile:(NSURL *)file {
    
    NSString *content = [SwrveTestHelper fileContentsFromURL:file];
    NSMutableArray *cacheLines = [[NSMutableArray alloc] initWithArray:[content componentsSeparatedByString:@"\n"]];
    [cacheLines removeLastObject];
    
    NSMutableArray *formattedArray = [NSMutableArray new];
    for (NSString *s in cacheLines) {
        
        NSString *newString = [s substringToIndex:s.length-1];
        NSDictionary * dic = [NSJSONSerialization JSONObjectWithData:[newString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        
        [formattedArray addObject:dic];
    }
    return formattedArray;
}

+ (NSString *) fileContentsFromURL:(NSURL *)url {
    return [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
}

@end
