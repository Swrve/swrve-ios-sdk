#import "UISwrveButton.h"
#import "SwrveMessage.h"

#if __has_include(<SwrveSDKCommon/SwrveQAImagePersonalizationInfo.h>)
#import <SwrveSDKCommon/SwrveQAImagePersonalizationInfo.h>
#else
#import "SwrveQAImagePersonalizationInfo.h"
#endif

/*! In-app message button. */
@interface SwrveButton : NSObject

@property (nonatomic, retain)            NSString* name;                        /*!< The name of the button. */
@property (nonatomic, retain)            NSString* image;                       /*!< The cached path of the button image on disk. */
@property (nonatomic, retain)            NSString* text;                        /*!< The text applied to the button (replaces image if populated) */
@property (nonatomic, retain)            NSString* dynamicImageUrl;             /*!< The URL to the button image provided from an external cdn */
@property (atomic)                       SwrveActionType actionType;            /*!< Type of action associated with this button. */
@property (nonatomic, retain)            NSString* actionString;                /*!< Custom action string for the button. */
@property (atomic)                       CGPoint center;                        /*!< Position of the button. */
@property (atomic)                       CGSize size;                           /*!< Suggested size of the image container */
@property (atomic)                       long messageID;                        /*!< Message identifier associated with this button. */
@property (atomic)                       long appID;                            /*!< ID of the target installation app. */
@property (nonatomic, retain)            SwrveMessage* message;                 /*!< Reference to parent message. */

/*! Create a button with the given orientation and position.
 *
 * \param delegate Event action delegate.
 * \param selector Button click selector.
 * \param scale Parent message scale.
 * \param cx Position in the x-axis.
 * \param cy Position in the y-axis.
 * \returns New button instance.
 */

- (UISwrveButton*)createButtonWithDelegate:(id)delegate
                               andSelector:(SEL)selector
                                  andScale:(float)scale
                                andCenterX:(float)cx
                                andCenterY:(float)cy
                     andPersonalizedAction:(NSString *)personalizedActionStr
                        andPersonalization:(NSString *)personalizedTextStr
               andPersonalizedUrlAssetSha1:(NSString *)personalizedUrlAssetSha1
                                withConfig:(SwrveInAppMessageConfig*)inAppConfig
                                    qaInfo:(SwrveQAImagePersonalizationInfo*)qaInfo;

@end
