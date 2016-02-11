#import "UnitySwrveCommon.h"
#import "UnitySwrveHelper.h"
#import "SwrveSignatureProtectedFile.h"

static UnitySwrveCommon *_swrveSharedUnity = NULL;
static dispatch_once_t sharedInstanceToken = 0;

@interface UnitySwrveCommon()

@property(atomic, strong) NSDictionary* configDict;

@end

@implementation UnitySwrveCommon

@synthesize configDict;

+(UnitySwrveCommon*) sharedInstance
{
    dispatch_once(&sharedInstanceToken, ^{
        _swrveSharedUnity = [UnitySwrveCommon alloc];
        [SwrveCommon setSwrveCommon:_swrveSharedUnity];
    });
    return _swrveSharedUnity;
}

+(void) init:(char*)jsonConfig {
    UnitySwrveCommon* swrve = [UnitySwrveCommon sharedInstance];
    
    NSError* error = nil;
    swrve.configDict =
        [NSJSONSerialization JSONObjectWithData:[[UnitySwrveHelper CStringToNSString:jsonConfig] dataUsingEncoding:NSUTF8StringEncoding]
                                        options:NSJSONReadingMutableContainers error:&error];
}

-(NSString*) stringFromConfig:(NSString*)key {
    return [self.configDict valueForKey:key];
}

-(NSString*) applicationPath {
    return [self stringFromConfig:@"swrvePath"];
}

-(NSString*) locTag {
    return [self stringFromConfig:@"locTag"];
}

-(NSString*) sigSuffix {
    return [self stringFromConfig:@"sigSuffix"];
}

-(NSString*) userId {
    return [self stringFromConfig:@"userId"];
}

-(NSString*) uniqueKey {
    return [self stringFromConfig:@"uniqueKey"];
}

-(NSString*) getLocationPath {
    return [NSString stringWithFormat:@"%@/%@%@", [self applicationPath], [self locTag], [self userId]];
}

-(NSData*) getCampaignData:(int)category {
    if(SWRVE_CAMPAIGN_LOCATION == category) {
        NSURL *fileURL = [NSURL fileURLWithPath:[self getLocationPath]];
        NSURL *signatureURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", [self getLocationPath], [self sigSuffix]]];
        NSString *signatureKey = [self uniqueKey];
        SwrveSignatureProtectedFile *locationCampaignFile = [[SwrveSignatureProtectedFile alloc] initFile:fileURL signatureFilename:signatureURL usingKey:signatureKey];
        return [locationCampaignFile readFromFile];
    }
    return nil;
}

-(BOOL) processPermissionRequest:(NSString*)action { return TRUE; }
-(void) sendQueuedEvents { }
-(int) eventInternal:(NSString*)eventName payload:(NSDictionary*)eventPayload triggerCallback:(bool)triggerCallback { return SWRVE_SUCCESS; }
-(int) userUpdate:(NSDictionary*)attributes { return SWRVE_SUCCESS; }
-(void) setLocationVersion:(NSString *)version { }

@end
