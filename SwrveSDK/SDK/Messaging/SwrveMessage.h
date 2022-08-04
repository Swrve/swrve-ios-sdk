#import "SwrveMessageFormat.h"
#import "SwrveBaseMessage.h"

/*! Enumerates the possible types of action that can be associated with tapping a message button. */
typedef enum {
    kSwrveActionDismiss,    /*!< Cancel the message display */
    kSwrveActionCustom,     /*!< Handle the custom action string associated with the button */
    kSwrveActionInstall,    /*!< Go to the url specified in the button’s action string */
    kSwrveActionClipboard,  /*!< Add Dynamic Text in place of the image */
    kSwrveActionCapability, /*!< Request IAM capability*/
    kSwrveActionPageLink    /*!< Link to another page in the message */
} SwrveActionType;

@class SwrveMessageController;
@class SwrveInAppCampaign;

/*! In-app message. */
@interface SwrveMessage : SwrveBaseMessage

@property(nonatomic, retain) NSArray *formats;       /*!< Array of multiple formats for this message */

/*! Create an in-app message from the JSON content.
 *
 * \param json In-app message JSON content.
 * \param _campaign Parent in-app campaign.
 * \param controller Message controller.
 * \returns Parsed in-app message.
 */
- (id)initWithDictionary:(NSDictionary *)json forCampaign:(SwrveInAppCampaign *)_campaign forController:(SwrveMessageController *)controller;

#if TARGET_OS_IOS /** exclude tvOS **/

/*! Obtain the best format for the given orientation.
 *
 * \param orientation Wanted orientation for the message.
 * \returns In-app message format for the given orientation.
 */
- (SwrveMessageFormat *)bestFormatForOrientation:(UIInterfaceOrientation)orientation;

/*! Check if the message has any format for the given device orientation.
 *
 * \param orientation Device orientation.
 * \returns TRUE if the message has any format with the given orientation.
 */
- (BOOL)supportsOrientation:(UIInterfaceOrientation)orientation;

#endif

/*! Check if assets are downloaded.
 *
 * \returns TRUE if all assets have been downloaded.
 */
- (BOOL)assetsReady:(NSSet *)assets withPersonalization:(NSDictionary *)personalization;

/*! Check if all personalized text in this message has been accounted for and can be set
*
* \returns TRUE if all personalized text parts have either fallbacks or values available to them
*/
- (BOOL)canResolvePersonalization:(NSDictionary *)personalization;

@end
