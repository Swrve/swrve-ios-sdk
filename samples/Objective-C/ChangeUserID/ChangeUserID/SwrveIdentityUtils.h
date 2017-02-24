#import "swrve.h"

@interface SwrveIdentityUtils : NSObject

- (void) createSDKInstance:(int) appID apiKey:(NSString*)apiKey config:(SwrveConfig*)config userID:(NSString*) userID launchOptions:(NSDictionary*) launchOptions;
- (void) changeUserID:(NSString*) userID;

@end
