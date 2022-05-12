#include <UIKit/UIKit.h>
#import "SwrveInterfaceOrientation.h"
#import "SwrveInAppMessageConfig.h"
#import "SwrveCalibration.h"

@class SwrveMessage;
@class SwrveMessageController;

/*! In-app message format */
@interface SwrveMessageFormat : NSObject

@property(retain, nonatomic) NSDictionary *pages;                          /*!< A dictionary of SwrveMessagePage objects keyed on pageId */
@property(atomic) long firstPageId;                                        /*!< The first pageId to be displayed */
@property(retain, nonatomic) NSString *name;                               /*!< The name of the format */
@property(retain, nonatomic) NSString *language;                           /*!< The language of the format */
@property(nonatomic, retain) UIColor *backgroundColor;                     /*!< Background color of the format */
@property(nonatomic) SwrveInterfaceOrientation orientation;                /*!< The orientation of the format */
@property(nonatomic) float scale;                                          /*!< The scale that the format should render */
@property(atomic) CGSize size;                                             /*!< The size of the format */
@property(nonatomic) SwrveCalibration *calibration;                        /*!< Calibration values used for font scaling*/

- (id)initFromJson:(NSDictionary *)json
        campaignId:(long)swrveCampaignId
         messageId:(long)swrveMessageId
      appStoreURLs:(NSMutableDictionary *)appStoreURLs;

@end
