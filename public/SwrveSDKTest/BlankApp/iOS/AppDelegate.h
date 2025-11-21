#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) NSData *swizzleDeviceToken;
@property (strong, nonatomic) NSError *swizzleError;

@end

