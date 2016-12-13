#import <Foundation/Foundation.h>
#import "Swrve.h"

@interface SwrveMigrationsManager : NSObject

/** Migration introduced to move a cache file into another **/
+ (void) migrateOldCacheFile:(NSString*)oldPath withNewPath:(NSString*)newPath;

+ (void) migrateFileProtectionAtPath:(NSString*)path;

@end
