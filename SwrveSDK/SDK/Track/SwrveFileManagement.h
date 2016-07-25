#import <Foundation/Foundation.h>
#import "Swrve.h"

@interface SwrveFileManagement : NSObject

+ (NSString *) applicationSupportPathWithBackupExclusion:(BOOL)backupExclusion;

@end
