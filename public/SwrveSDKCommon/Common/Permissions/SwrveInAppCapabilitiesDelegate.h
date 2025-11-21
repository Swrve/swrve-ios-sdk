#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SwrveInAppCapabilitiesDelegate <NSObject>

@optional

- (BOOL)canRequestCapability:(NSString *)capabilityName;
- (void)requestCapability:(NSString *)capabilityName completionHandler:(void (^)(BOOL success))completion;

@end

NS_ASSUME_NONNULL_END
