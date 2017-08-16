#import <Foundation/Foundation.h>
#import "Swrve.h"

static NSString* SWRVE_CAMPAIGNS = @"cmcc2.json";
static NSString* SWRVE_CAMPAIGNS_SGT = @"cmccsgt2.txt";

@interface SwrveFileManagement : NSObject

+ (NSString *) applicationSupportPath;
+ (NSString *)campaignsFilePath;
+ (NSString *)campaignsSignatureFilePath;

@end
