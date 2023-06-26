#import <Foundation/Foundation.h>
#import "SwrveButtonActions.h"

NS_ASSUME_NONNULL_BEGIN

@interface SwrveMessageButtonDetails : NSObject

@property(nonatomic, retain) NSString *buttonName;    /*!< The name of the button. */
@property(nonatomic, retain) NSString *buttonText;    /*!< The text applied to the button  */
@property(atomic) SwrveActionType actionType;      /*!< Type of action associated with this button. */
@property(nonatomic, retain) NSString *actionString;  /*!< Custom action string for the button. */

- (id)initWith:(NSString *)name buttonText:(NSString *)text actionType:(SwrveActionType)type
  actionString:(NSString *)action;

@end

NS_ASSUME_NONNULL_END
