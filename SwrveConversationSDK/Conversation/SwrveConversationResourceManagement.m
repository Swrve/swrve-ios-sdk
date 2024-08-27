#import "SwrveConversationResourceManagement.h"
#import "SwrveSetup.h"

@implementation SwrveConversationResourceManagement

+ (NSBundle *)conversationBundle {
    NSBundle *mainBundle = [NSBundle bundleForClass:[SwrveConversationResourceManagement class]];
           
    // cocoapods uses SwrveConversationSDK.bundle , see resources_bundle in podspec
    NSURL *bundleURL = [[mainBundle resourceURL] URLByAppendingPathComponent:@"SwrveConversationSDK.bundle"];
    NSBundle *frameworkBundle = [NSBundle bundleWithURL:bundleURL];
           
    if (frameworkBundle != nil) {
        return frameworkBundle;
    }
    
    // SPM references static framework, converastion code/assets is added to  SwrveSDK, location is: Frameworks/SwrveSDK.framework.
    bundleURL = [[mainBundle resourceURL] URLByAppendingPathComponent:@"Frameworks/SwrveSDK.framework"];
    frameworkBundle = [NSBundle bundleWithURL:bundleURL];
           
    if (frameworkBundle != nil) {
        return frameworkBundle;
    }
    
#ifdef SWIFTPM_MODULE_BUNDLE
    mainBundle = SWIFTPM_MODULE_BUNDLE;
#endif
    
    // if its nil, try standard bundle location for class
    return mainBundle;
}

+ (UIImage *) imageWithName:(NSString *)imageName API_AVAILABLE(ios(12.0)) {
    NSBundle *bundle = [SwrveConversationResourceManagement conversationBundle];
    return [UIImage imageNamed:imageName inBundle:bundle compatibleWithTraitCollection: nil];
}

@end
