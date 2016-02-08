#import "PlotPayload.h"
//#import "Swrve.h"
#import "SwrveCommon.h"

@implementation PlotPayload

@synthesize campaignId;
@synthesize geofenceLabel;

- (id)initWithPayload:(NSString *)payload {
    if (self = [super init]) {
        NSError *error = nil;
        NSData *objectData = [payload dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *jsonPayLoad = [NSJSONSerialization JSONObjectWithData:objectData options:NSJSONReadingMutableContainers error:&error];
        if (error) {
            DebugLog(@"Error parsing location campaign payload.\nError: %@\npayload: %@", error, payload);
        } else {
            campaignId = [jsonPayLoad objectForKey:@"campaignId"];
            geofenceLabel = [jsonPayLoad objectForKey:@"geofenceLabel"];
        }
    }
    
    return self;
}

@end
