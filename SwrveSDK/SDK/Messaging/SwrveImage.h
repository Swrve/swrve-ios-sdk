#include <UIKit/UIKit.h>
#include "SwrveInAppMessageConfig.h"
#import "SwrveMessage.h"

#if __has_include(<SwrveSDKCommon/SwrveQAImagePersonalizationInfo.h>)

#import <SwrveSDKCommon/SwrveQAImagePersonalizationInfo.h>

#else
#import "SwrveQAImagePersonalizationInfo.h"
#endif

/*! In-app message background image. */
@interface SwrveImage : NSObject

@property(nonatomic, retain) NSString *file;               /*!< Cached path of the image file on disk */
@property(nonatomic, retain) NSString *dynamicImageUrl;    /*!< The URL to the button image provided from an external cdn */
@property(nonatomic, retain) NSString *text;               /*!< populated if text is present */
@property(atomic) CGPoint center;                          /*!< Center of the image */
@property(atomic) CGSize size;                             /*!< Suggested size of the image container */
@property(atomic) long campaignId;                         /*!< Campaign identifier associated with this button. */
@property(atomic) long messageId;                          /*!< Message identifier associated with this button. */
@property(nonatomic, retain) NSDictionary *multilineText;
@property(nonatomic, retain) NSString *accessibilityText;  /*!< Alternative text for use with accessibility voice over */

- (id)initWithDictionary:(NSDictionary *)imageData
              campaignId:(long)swrveCampaignId
               messageId:(long)swrveMessageId;

- (UIImage *)createImage:(NSString *)cacheFolder
         personalization:(NSString *)personalizedTextStr
personalizedUrlAssetSha1:(NSString *)personalizedUrlAssetSha1
             inAppConfig:(SwrveInAppMessageConfig *)inAppConfig
                  qaInfo:(SwrveQAImagePersonalizationInfo *)qaInfo;

@end
