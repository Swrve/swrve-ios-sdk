#import "SwrveLocationPayload.h"
#import "Swrve.h"

@implementation SwrveLocationPayload

@synthesize geofenceId;
@synthesize campaignId;

- (id)initWithPayload:(NSString *)payload {

    if (self = [super init]) {
        NSError *error = nil;
        NSData *objectData = [payload dataUsingEncoding:NSUTF8StringEncoding];
        NSMutableDictionary *jsonPayLoad = [NSJSONSerialization JSONObjectWithData:objectData options:NSJSONReadingMutableContainers error:&error];
        if (error) {
            DebugLog(@"Error parsing location campaign payload.\nError: %@\npayload: %@", error, payload);
        }
        geofenceId = [jsonPayLoad objectForKey:@"geofenceId"];
        campaignId = [jsonPayLoad objectForKey:@"campaignId"];
    }

    return self;
}

@end
