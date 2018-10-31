#import "SwrveConversationResourceManagement.h"
#import "SwrveSetup.h"

@implementation SwrveConversationResourceManagement

+ (UIImage *) imageWithName:(NSString *)imageName {
    return [UIImage imageNamed:imageName inBundle:[NSBundle bundleForClass:[SwrveConversationResourceManagement class]] compatibleWithTraitCollection: nil];
}

@end
