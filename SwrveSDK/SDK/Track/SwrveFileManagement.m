#import "SwrveFileManagement.h"

@implementation SwrveFileManagement

#pragma mark - Application data management

+ (NSString *) applicationSupportPathWhichExcludesBackup:(BOOL)excludeBackup {
    
    NSString *appSupportDir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    if (![[NSFileManager defaultManager] fileExistsAtPath:appSupportDir isDirectory:NULL]) {
        NSError *error = nil;
        if (![[NSFileManager defaultManager] createDirectoryAtPath:appSupportDir withIntermediateDirectories:YES attributes:nil error:&error]) {
            DebugLog(@"Error Creating an Application Support Directory %@", error.localizedDescription);
        } else {
            if(!excludeBackup) {
                NSURL *url = [NSURL fileURLWithPath:appSupportDir];
                if (![url setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:&error]) {
                    DebugLog(@"Error excluding %@ from backup %@", url.lastPathComponent, error.localizedDescription);
                }
                else {
                    DebugLog(@"Excluded %@ from backup", url.lastPathComponent);
                }
            }
            DebugLog(@"Successfully Created Directory: %@", appSupportDir);
        }
    }
    return appSupportDir;
}

@end
