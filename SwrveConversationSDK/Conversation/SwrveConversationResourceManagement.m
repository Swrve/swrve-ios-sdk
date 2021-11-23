#import "SwrveConversationResourceManagement.h"
#import "SwrveSetup.h"

@implementation SwrveConversationResourceManagement

+ (NSBundle *)conversationBundle {
#ifdef SWIFTPM_MODULE_BUNDLE
    return SWIFTPM_MODULE_BUNDLE;
#else
    NSBundle *mainBundle = [NSBundle bundleForClass:[SwrveConversationResourceManagement class]];
           
    // cocoapods uses SwrveConversationSDK.bundle , see resources_bundle in podspec
    NSURL *bundleURL = [[mainBundle resourceURL] URLByAppendingPathComponent:@"SwrveConversationSDK.bundle"];
    NSBundle *frameworkBundle = [NSBundle bundleWithURL:bundleURL];
           
    // if its nil, try standard bundle location for class
    if (frameworkBundle != nil) {
        return frameworkBundle;
    }
    return mainBundle;
#endif
}

+ (UIImage *) imageWithName:(NSString *)imageName API_AVAILABLE(ios(8.0)) {
    NSBundle *bundle = [SwrveConversationResourceManagement conversationBundle];
    return [UIImage imageNamed:imageName inBundle:bundle compatibleWithTraitCollection: nil];
}

@end
