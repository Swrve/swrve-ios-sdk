#import <UIKit/UIKit.h>

@interface SwrveConversationsNavigationController : UINavigationController

@property (nonatomic, assign) BOOL landscapeEnabled;
@property (nonatomic, strong) id<UINavigationControllerDelegate> movieRotationHandling;

@end
