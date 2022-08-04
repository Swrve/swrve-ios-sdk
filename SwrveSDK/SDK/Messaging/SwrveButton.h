#import "UISwrveButton.h"
#import "SwrveMessage.h"

/*! In-app message button. */
@interface SwrveButton : NSObject

@property(nonatomic, retain) NSString *name;                        /*!< The name of the button. */
@property(atomic) NSNumber *buttonId;                               /*!< The button id of the button. */
@property(nonatomic, retain) NSString *image;                       /*!< The cached path of the button image on disk. */
@property(nonatomic, retain) NSString *text;                        /*!< The text applied to the button (replaces image if populated) */
@property(nonatomic, retain) NSString *dynamicImageUrl;             /*!< The URL to the button image provided from an external cdn */
@property(atomic) SwrveActionType actionType;                       /*!< Type of action associated with this button. */
@property(nonatomic, retain) NSString *actionString;                /*!< Custom action string for the button. */
@property(atomic) CGPoint center;                                   /*!< Position of the button. */
@property(atomic) CGSize size;                                      /*!< Suggested size of the image container */
@property(atomic) long campaignId;                                  /*!< Campaign identifier associated with this button. */
@property(atomic) long messageId;                                   /*!< Message identifier associated with this button. */
@property(atomic) long appID;                                       /*!< ID of the target installation app. */
@property(nonatomic, retain) NSString *accessibilityText;           /*!< Alternative text for use with accessibility voice over */

- (id)initWithDictionary:(NSDictionary *)buttonData
              campaignId:(long)swrveCampaignId
               messageId:(long)swrveMessageId
            appStoreURLs:(NSMutableDictionary *)appStoreURLs;

@end
