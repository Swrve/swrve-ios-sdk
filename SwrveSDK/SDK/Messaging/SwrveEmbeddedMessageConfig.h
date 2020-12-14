#import <Foundation/Foundation.h>
#import "SwrveEmbeddedMessage.h"

@interface SwrveEmbeddedMessageConfig : NSObject

/*! A block that will be called when an event triggers an embedded message.
 * \param message the SwrveEmbeddedMessage object
 */
typedef void (^SwrveEmbeddedMessageCallback)(SwrveEmbeddedMessage *message);

@property(nonatomic, copy) SwrveEmbeddedMessageCallback embeddedMessageCallback;  /*!< Implement this delegate to implement embedded messages*/

@end

