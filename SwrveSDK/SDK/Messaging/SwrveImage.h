#include <UIKit/UIKit.h>
#include "SwrveInAppMessageConfig.h"

/*! In-app message background image. */
@interface SwrveImage : NSObject

@property (nonatomic, retain) NSString* file;   /*!< Cached path of the image file on disk */
@property (nonatomic, retain) NSString* text;   /*!< populated if text is present */
@property (atomic)            CGPoint center;   /*!< Center of the image */

- (UIImage*)createImage:(NSString *)cacheFolder personalisation:(NSString*)personalisedTextStr inAppConfig:(SwrveInAppMessageConfig*)inAppConfig;

@end
