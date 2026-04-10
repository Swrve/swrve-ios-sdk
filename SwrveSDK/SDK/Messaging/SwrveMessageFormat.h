#include <UIKit/UIKit.h>

#if __has_include(<SwrveSDK/SwrveInterfaceOrientation.h>)
#import <SwrveSDK/SwrveInterfaceOrientation.h>
#import <SwrveSDK/SwrveStorySettings.h>
#else
#import "SwrveInterfaceOrientation.h"
#import "SwrveStorySettings.h"
#endif

#if __has_include(<SwrveSDKCommon/SwrveInAppCapabilitiesDelegate.h>)
#import <SwrveSDKCommon/SwrveInAppCapabilitiesDelegate.h>
#else
#import "SwrveInAppCapabilitiesDelegate.h"
#endif


@class SwrveMessage;
@class SwrveMessageController;
@class SwrveCalibration;

/*! In-app message format */
@interface SwrveMessageFormat : NSObject

@property(retain, nonatomic) NSDictionary *pages;                          /*!< A dictionary of SwrveMessagePage objects keyed on pageId */
@property(nonatomic) NSArray *pagesOrdered;                                /*!< An array of pageId's which is the order for story page progression */
@property(retain, nonatomic) NSString *name;                               /*!< The name of the format */
@property(retain, nonatomic) NSString *language;                           /*!< The language of the format */
@property(nonatomic, retain) UIColor *backgroundColor;                     /*!< Background color of the format */
@property(nonatomic) SwrveInterfaceOrientation orientation;                /*!< The orientation of the format */
@property(nonatomic) float scale;                                          /*!< The scale that the format should render */
@property(atomic) CGSize size;                                             /*!< The size of the format */
@property(nonatomic) SwrveCalibration *calibration;                        /*!< Calibration values used for font scaling*/
@property(nonatomic) SwrveStorySettings *storySettings;                    /*!< In-App Story settings */

- (id)initFromJson:(NSDictionary *)json
        campaignId:(long)swrveCampaignId
         messageId:(long)swrveMessageId;

@end
