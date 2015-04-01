#import "Swrve.h"

/*
 * A collection of attributes that can be overriden by Swrve.
 */
@interface DemoResource : NSObject
{
    NSMutableDictionary* attributes;
}

@property (strong, nonatomic) NSMutableDictionary *attributes;

/*
 * Creates a DemoResource with no attributes.
 */
- (id) init:(NSString *) withUniqueId;

/*
 * Creates a DemoResource with a dictionary of attributes.
 */
- (id) init:(NSString *) withUniqueId withAttributes:(NSDictionary *) attributes;

/*
 * Gets an attribute of the resource as a string.
 */
- (NSString *) getAttributeAsString:(NSString *) attributeId;

/*
 * Gets/sets an attribute of the resource as an int.
 */
- (int) getAttributeAsInt:(NSString *) attributeId;
- (void) setAttributeAsInt:(NSString *) attributeId withValue:(int) value;

/*
 * Gets/sets an attribute of the resource as a float.
 */
- (float) getAttributeAsFloat:(NSString *) attributeId;
- (void) setAttributeAsFloat:(NSString *) attributeId withValue:(float) value;

/*
 * Gets/sets an attribute of the resource as a boolean.
 */
- (BOOL) getAttributeAsBool:(NSString *) attributeId;
- (void) setAttributeAsBool:(NSString *) attributeId withValue:(bool) value;

/*
 * 
 */
- (NSArray *) getAttributeAsArrayOfString:(NSString *) attributeId;

@end

/*
 * Delegate used notify users when AB test differences have been downloaded.
 */
@protocol DemoResourceManagerDelegate <NSObject>

@optional

/*
 * Called when applyAbTestDifferencesAsync is complete.
 */
- (void) applyAbTestDifferencesAsyncIsComplete;

/*
 * Called when applyAllResourcesAsync is complete. 
 */
- (void) applyAllResourcesAsyncComplete;

@end


/*
 * Manages attributes that can be overriden by AB tests ran in Swrve.  Use this
 * manager only if you don't have an equivilant in your app.
 */
@interface DemoResourceManager : NSObject
{

    NSMutableDictionary *resources;
    NSString *currentDiff;
}

@property (nonatomic, retain) id <DemoResourceManagerDelegate> delegate;
@property (atomic, retain) NSString* userIdOverride;

/*
 * Creates an empty DemoResourceManager.
 */
- (id) init;

/*
 * Adds a resource to the manager.
 */
- (void) addResource:(DemoResource *)resource;

/*
 * Returns a resource identified by resourceUniqueId.  nil is returned if the
 * resource doesn't exist.
 */
- (DemoResource *) lookupResource:(NSString *) resourceUniqueId;

/*
 * Modifies local resources based on active A/B tests in the Swrve Dashboard. 
 * This is an async call and will return immediatly.  Use the 
 * DemoResourceManagerDelegate to be notified when changes have been applied.
 *
 * Changes to local resources are made if:
 *
 *    #1 - Your app can contact Swrve
 *    #2 - The user is a participant of a running A/B test
 *
 * If your app can't contact Swrve no changes are made.
 *
 * This method will download the minimal differences in data.  This makes it
 * efficient in terms of network bandwidth and data write cost.  It uses the 
 * user_resources_diff end point
 * internally.
 * 
 * See http://dashboard.swrve.com/help/docs/abtest_api#get-user-resources-diff
 * for more information.
 */
- (void) applyAbTestDifferencesAsync:(Swrve *) swrve;

/*
 * Modifies local resources based on active A/B tests in the Swrve Dashboard.
 * This is an async call and will return immediatly.  Use the
 * DemoResourceManagerDelegate to be notified when changes have been applied.
 *
 * Changes to local resources are made if:
 *
 *    #1 - Your app can contact Swrve
 *    #2 - The user is a participant of a running A/B test
 *
 * If your app can't contact Swrve no changes are made.
 *
 * This method will download all resources in the Swrve dashboard and is 
 * therefore less efficient than applyAbTestDifferencesAsync.  Use this method
 * if you want to use Swrve's dashboard to directly edit resources withou
 * running AB tests.
 *
 * See http://dashboard.swrve.com/help/docs/abtest_api#get-user-resources
 * for more information.
 */
- (void) applyAllResourcesAsync:(Swrve *) swrve;

/*
 * Pushes the resource to the Swrve dashboard to users can run AB tests on it.
 */
- (long) pushResourceToDashboard:(Swrve*) swrve withApiKey:(NSString* ) apiKey withPersonalKey:(NSString*) personalKey withResource:(DemoResource *) resource;

/*
 * Pushes all resources in the manager to the Swrve dashboard.
 */
- (long) pushAllResourcesToDashboard:(Swrve*) swrve withApiKey:(NSString* ) apiKey withPersonalKey:(NSString*) personalKey;

@end
