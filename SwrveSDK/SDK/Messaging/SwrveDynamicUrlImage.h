#import <Foundation/Foundation.h>

#if __has_include(<SwrveSDK/SwrveQAImagePersonalizationInfo.h>)
#import <SwrveSDK/SwrveQAImagePersonalizationInfo.h>
#else
#import "SwrveQAImagePersonalizationInfo.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface SwrveDynamicUrlImage : NSObject

+ (UIImage *)dynamicImageToContainer:(NSString *)sha1Asset cacheFolder:(NSString *)cacheFolder size:(CGSize)size qaInfo:(SwrveQAImagePersonalizationInfo *) qaInfo;

@end

NS_ASSUME_NONNULL_END
