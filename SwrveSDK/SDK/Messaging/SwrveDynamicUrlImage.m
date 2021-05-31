#include <UIKit/UIKit.h>
#import "SwrveDynamicUrlImage.h"

#if __has_include(<SwrveSDK/SwrveQA.h>)
#import <SwrveSDK/SwrveQA.h>
#else
#import "SwrveQA.h"
#endif

#define SWRVEMIN(a,b)    ((a) < (b) ? (a) : (b))

@implementation SwrveDynamicUrlImage

+ (UIImage *)dynamicImageToContainer:(NSString *)sha1Asset cacheFolder:(NSString *)cacheFolder size:(CGSize)size qaInfo:(SwrveQAImagePersonalizationInfo *) qaInfo {
    UIImage *result = nil;
    NSURL *canditateImageUrl = [NSURL fileURLWithPathComponents:[NSArray arrayWithObjects:cacheFolder, sha1Asset, nil]];
    UIImage *dynamicImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:canditateImageUrl]];
    if (dynamicImage != nil) {
        dynamicImage = [SwrveDynamicUrlImage resizeImage:dynamicImage toSize:size];
        result = dynamicImage;
    } else {
        [qaInfo setReason: @"Asset not found in cache"];
        [SwrveQA assetFailedToDisplay:qaInfo];
    }
    
    return result;
}

/** resize the image (with respect to the aspect ratio) */
+ (UIImage *)resizeImage:(UIImage*)image toSize:(CGSize)size {
    if (CGSizeEqualToSize(image.size, size)) {
        return image;
    }
    
    CGFloat widthRatio = size.width / image.size.width;
    CGFloat heightRatio = size.height / image.size.height;
    
    CGFloat scale = SWRVEMIN(widthRatio, heightRatio);
    CGSize scaledImageSize = CGSizeMake((image.size.width * scale), (image.size.height * scale));
    
    UIGraphicsBeginImageContextWithOptions(scaledImageSize, NO, 0.0f);
    [image drawInRect:CGRectMake(0.0f, 0.0f, scaledImageSize.width, scaledImageSize.height)];
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

@end
