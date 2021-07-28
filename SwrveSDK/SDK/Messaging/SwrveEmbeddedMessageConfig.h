#import <Foundation/Foundation.h>
#import "SwrveEmbeddedMessage.h"

@interface SwrveEmbeddedMessageConfig : NSObject

/*! A block that will be called when an event triggers an embedded message.
 * WARNING: this callback is now deprecated and will be removed soon.
 * \param message the SwrveEmbeddedMessage object
 */
typedef void (^SwrveEmbeddedMessageCallback)(SwrveEmbeddedMessage *message);

/*! A block that will be called when an event triggers an embedded message.
 * \param message the SwrveEmbeddedMessage object
 * \param personalizationProperties custom properties which are used for personalization.
 */
typedef void (^SwrveEmbeddedMessageCallbackWithPersonalization)(SwrveEmbeddedMessage *message, NSDictionary *personalizationProperties);

@property(nonatomic, copy) SwrveEmbeddedMessageCallback embeddedMessageCallback;  /*!< Implement this delegate to implement embedded messages*/

@property(nonatomic, copy) SwrveEmbeddedMessageCallbackWithPersonalization embeddedMessageCallbackWithPersonalization;  /*!< Implement this delegate to implement embedded messages*/

@end

