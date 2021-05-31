#import "TestCapabilitiesDelegate.h"

@implementation TestCapabilitiesDelegate

- (BOOL)canRequestCapability:(NSString *)capabilityName {
    //Test implemenation
    if ([capabilityName isEqualToString:@"swrve.contacts"]) return true;
    if ([capabilityName isEqualToString:@"swrve.photo"]) return false;
    return false;
}

- (void)requestCapability:(NSString *)capabilityName completionHandler:(void (^)(BOOL success))completion {
    //Test implemenation
    if ([capabilityName isEqualToString:@"swrve.contacts"]) completion(true);
    else if ([capabilityName isEqualToString:@"swrve.photo"]) completion(false);
    else completion(false);
}

@end
