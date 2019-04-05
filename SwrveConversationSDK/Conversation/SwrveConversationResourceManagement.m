#import "SwrveConversationResourceManagement.h"
#import "SwrveSetup.h"

@implementation SwrveConversationResourceManagement

+ (UIImage *) imageWithName:(NSString *)imageName API_AVAILABLE(ios(8.0)) {
    return [UIImage imageNamed:imageName inBundle:[NSBundle bundleForClass:[SwrveConversationResourceManagement class]] compatibleWithTraitCollection: nil];
}

@end
