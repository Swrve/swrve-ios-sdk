#import <UIKit/UIKit.h>

@interface SwrveNonRotatingNavController : UINavigationController

@property (nonatomic, assign) BOOL landscapeEnabled;
@property (nonatomic, strong) id<UINavigationControllerDelegate> movieRotationHandling;
@end
