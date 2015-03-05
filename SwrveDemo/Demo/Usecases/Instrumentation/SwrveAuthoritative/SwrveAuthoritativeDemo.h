#import "DemoFramework.h"

@interface SwrveAuthoritativeDemo : Demo<DemoResourceManagerDelegate> {
    Swrve* swrve;
    DemoResourceManager* resourceManager;
}

@property (atomic, retain) IBOutlet UILabel* timeToLoadLabel;
@end
