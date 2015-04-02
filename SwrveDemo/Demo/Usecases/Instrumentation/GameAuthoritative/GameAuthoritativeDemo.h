#import "DemoFramework.h"

@interface GameAuthoritativeDemo : Demo<DemoResourceManagerDelegate> {
    Swrve* swrve;
    DemoResourceManager* resourceManager;
}

@property (atomic, retain) IBOutlet UILabel* timeToLoadLabel;
@end
