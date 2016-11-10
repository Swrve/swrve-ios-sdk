#import "SwrveFileManagement.h"

@implementation SwrveFileManagement

#pragma mark - Application data management

+ (NSError*) createApplicationSupportPath {
    NSString *appSupportDir = [SwrveFileManagement applicationSupportPath];
    NSError *error = nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:appSupportDir isDirectory:NULL]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:appSupportDir withIntermediateDirectories:YES attributes:nil error:&error]) {
            DebugLog(@"Error Creating an Application Support Directory %@", error.localizedDescription);
        } else {
            DebugLog(@"Successfully Created Directory: %@", appSupportDir);
        }
    }
    return error;
}

+ (NSString *) applicationSupportPath {
    return [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
}

@end
