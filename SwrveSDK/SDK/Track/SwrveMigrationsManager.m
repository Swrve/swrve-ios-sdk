#import "SwrveMigrationsManager.h"

@implementation SwrveMigrationsManager

#pragma mark >4.5 migrations

+ (void) migrateOldCacheFile:(NSString*)oldPath withNewPath:(NSString*)newPath {
    // Old file defaults to cache directory, should be moved to new location
    if ([[NSFileManager defaultManager] isReadableFileAtPath:oldPath]) {
        
        NSError *error;
        [[NSFileManager defaultManager] moveItemAtPath:oldPath toPath:newPath error:&error];
        if(error){
            DebugLog(@"File migration failed with the following error: %@", error);
        }
    }
}

#pragma mark >4.7 migrations

+ (void) migrateFileProtectionAtPath:(NSString*)path {
    
    if([self isProtectedItemAtPath:path]){
        // part of a bug with 4.7, if the device is locked and we trigger a location campaign.
        [[NSFileManager defaultManager] setAttributes:@{NSFileProtectionKey:NSFileProtectionNone} ofItemAtPath:path error:NULL];
    }
}

#pragma mark private methods

+ (BOOL) isProtectedItemAtPath:(NSString *)path {
    BOOL            result                      = YES;
    NSDictionary    *attributes                 = nil;
    NSString        *protectionAttributeValue   = nil;
    NSError         *error                      = nil;

    attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
    if (attributes != nil){
        protectionAttributeValue = [attributes valueForKey:NSFileProtectionKey];
        if ((protectionAttributeValue == nil) || [protectionAttributeValue isEqualToString:NSFileProtectionNone]){
            result = NO;
        }
    } else {
        DebugLog(@"There was an issue finding the level of file protection for : %@  \nError: %@" , path , error);
    }
    return result;
}

@end
