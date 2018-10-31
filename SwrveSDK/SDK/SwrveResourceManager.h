#include <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/*! Resource setup in the dashboard. A collection of attributes under a UID. */
@interface SwrveResource : NSObject

/*! Get an NSArray containing NSStrings that reprensent the attribute keys.
 *
 * \returns The attribute keys.
 */
- (NSArray*) attributeKeys;

/*! Get an attribute of the resource as a string.
 *
 * \param attributeId Attribute identifier.
 * \param defaultValue Default attribute value.
 * \returns The value of the attribute or the default value provided.
 */
- (NSString*) attributeAsString:(NSString*)attributeId withDefault:(NSString*)defaultValue;

/*! Get an attribute of the resource as an integer.
 *
 * \param attributeId Attribute identifier.
 * \param defaultValue Default attribute value.
 * \returns The value of the attribute or the default value provided.
 */
- (int) attributeAsInt:(NSString*)attributeId withDefault:(int)defaultValue;

/*! Get an attribute of the resource as a float.
 *
 * \param attributeId Attribute identifier.
 * \param defaultValue Default attribute value.
 * \returns The value of the attribute or the default value provided.
 */
- (float) attributeAsFloat:(NSString*)attributeId withDefault:(float)defaultValue;

/*! Get an attribute of the resource as a boolean.
 *
 * \param attributeId Attribute identifier.
 * \param defaultValue Default attribute value.
 * \returns The value of the attribute or the default value provided.
 */
- (BOOL) attributeAsBool:(NSString*)attributeId withDefault:(BOOL)defaultValue;

@end

/*! Information about an AB Test which the user is part of. */
@interface SwrveABTestDetails : NSObject

@property (atomic, retain) NSString* id;    /*!< Id of the test */
@property (atomic, retain) NSString* name;  /*!< Name of the test */
@property (atomic) int caseIndex;   /*!< Index of the variant this user is part of */

/*! Create an instance with the given attributes.
 *
 * \param abTestId Id of the test.
 * \param abTestName Name of the test.
 * \param abTestCaseIndex Case index assigned to the user.
 * \returns New AB Test information instance with the given attributes.
 */
- (id) initWithId:(NSString*)abTestId name:(NSString*)abTestName caseIndex:(int)abTestCaseIndex;

@end

/*! Offers access to the latest resources and values for this user */
@interface SwrveResourceManager : NSObject

@property (atomic, readonly) NSDictionary* resources;   /*!< List of available resources */

/*! Get a resource identified by the given uid.
 *
 * \param resourceId Unique resource identifier.
 * \returns The resource with the given uid or nil.
 */
- (nullable SwrveResource*) resourceWithId:(NSString*)resourceId;

/*! Get an attribute of the resource as a string.
 *
 * \param attributeId Attribute identifier.
 * \param resourceId Resource unique identifier.
 * \param defaultValue Default attribute value.
 * \returns The value of the attribute or the default value provided.
 */
- (NSString*) attributeAsString:(NSString*)attributeId fromResourceWithId:(NSString*)resourceId withDefault:(NSString*)defaultValue;

/*! Get an attribute of the resource as an integer.
 *
 * \param attributeId Attribute identifier.
 * \param resourceId Resource unique identifier.
 * \param defaultValue Default attribute value.
 * \returns The value of the attribute or the default value provided.
 */
- (int) attributeAsInt:(NSString*)attributeId fromResourceWithId:(NSString*)resourceId withDefault:(int)defaultValue;

/*! Get an attribute of the resource as a float.
 *
 * \param attributeId Attribute identifier.
 * \param resourceId Resource unique identifier.
 * \param defaultValue Default attribute value.
 * \returns The value of the attribute or the default value provided.
 */
- (float) attributeAsFloat:(NSString*)attributeId fromResourceWithId:(NSString*)resourceId withDefault:(float)defaultValue;

/*! Get an attribute of the resource as a boolean.
 *
 * \param attributeId Attribute identifier.
 * \param resourceId Resource unique identifier.
 * \param defaultValue Default attribute value.
 * \returns The value of the attribute or the default value provided.
 */
- (BOOL) attributeAsBool:(NSString*)attributeId fromResourceWithId:(NSString*)resourceId withDefault:(BOOL)defaultValue;

/*! Get information about the AB Tests a user is part of. To use this feature enable the flag abTestDetailsEnabled in your configuration.
 *
 * \returns Array of SwrveABTestDetails.
 */
- (NSArray*) abTestDetails;

@end
NS_ASSUME_NONNULL_END
