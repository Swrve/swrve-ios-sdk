#import <Foundation/Foundation.h>
#import "Swrve.h"

@interface SwrveFileManagement : NSObject

+ (NSString *) applicationSupportPathWhichExcludesBackup:(BOOL)excludeBackup;

@end
