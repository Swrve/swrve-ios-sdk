#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SwrveMessageDetails : NSObject

@property(atomic) NSString *campaignSubject;          /*!< The campaign subject. */
@property(atomic) NSUInteger campaignId;              /*!< The campaign id. */
@property(atomic) NSUInteger variantId;               /*!< The message id. */
@property(atomic) NSString *messageName;              /*!< The message name. */
@property(atomic) NSMutableArray *buttons;            /*!< An array of all button details for the in-app message. */

- (id)initWith:(NSString *)subject campaignId:(NSUInteger)campId variantId:(NSUInteger)varId messageName:(NSString *)name buttons:(NSMutableArray *)buttonsArray;

@end

NS_ASSUME_NONNULL_END
