#import "DemoFramework.h"

@interface TutorialDemo : Demo {
    
    int currentStep;
}

@property (nonatomic, retain) IBOutlet UIImageView *image;
@property (nonatomic, retain) IBOutlet UILabel *label;

@end
