#import "SwrveFileManagement.h"

@implementation SwrveFileManagement

#pragma mark - Application data management

+ (NSString *) applicationSupportPath {
    
    NSString *appSupportDir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    if (![[NSFileManager defaultManager] fileExistsAtPath:appSupportDir isDirectory:NULL]) {
        NSError *error = nil;
        if (![[NSFileManager defaultManager] createDirectoryAtPath:appSupportDir withIntermediateDirectories:YES attributes:
              [NSDictionary dictionaryWithObject:NSFileProtectionNone forKey:NSFileProtectionKey] error:&error]) {
            DebugLog(@"Error Creating an Application Support Directory %@", error.localizedDescription);
        } else {
            DebugLog(@"Successfully Created Directory: %@", appSupportDir);
        }
    }
    return appSupportDir;
}

+ (NSString *)campaignsFilePath {
    NSString *applicationSupport = [SwrveFileManagement applicationSupportPath];
    NSString *campaignFilePath = [applicationSupport stringByAppendingPathComponent:SWRVE_CAMPAIGNS];
    return campaignFilePath;
}

+ (NSString *)campaignsSignatureFilePath {
    NSString *applicationSupport = [SwrveFileManagement applicationSupportPath];
    NSString *campaignSignatureFilePath = [applicationSupport stringByAppendingPathComponent:SWRVE_CAMPAIGNS_SGT];
    return campaignSignatureFilePath;
}

@end
