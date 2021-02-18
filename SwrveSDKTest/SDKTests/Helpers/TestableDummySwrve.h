#import <Foundation/Foundation.h>
#import "SwrveEmpty.h"

@interface TestableDummySwrve : SwrveEmpty

+(TestableDummySwrve*) sharedInstanceWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey config:(SwrveConfig*)swrveConfig;

@end
