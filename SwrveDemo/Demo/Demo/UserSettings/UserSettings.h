/*
 * Wrapper around NSUserDefaults.  Used to store per user values.
 */
@interface UserSettings : NSObject

/*
 * Initializes the app to reasonable defaults.
 */
+ (void) init;

/*
 * Returns true if it is the first time the user has ran the app, false otherwise.
 */
+ (BOOL) isFirstTimeRunningApp;

/*
 * Returns the API key used in various demos.  This key can be changed in the
 * settings and should point to the app you are integrating.
 */
+ (NSString *) getAppApiKey;
+ (void) setAppApiKey:(NSString*) apiKey;

/*
 * Returns the app ID for the active app in the app.  This ID can be changed
 * in the settings and should point to the app you are integrating.
 */
+ (NSString *) getAppId;
+ (void) setAppId:(NSString*) appId;

/*
 * Returns the API key used to track usage of the app itself.  This key should
 * remain constant and is used by swrve to track usage of this app.
 */
+ (NSString *) getSwrveAppApiKey;

/*
 * Returns the app ID for the active app in the app itself.  This id should
 * remain constant.
 */
+ (NSString *) getSwrveAppId;

/*
 * Returns the QA user id using for AB testing QA.
 */
+ (NSString *) getQAUserId;
+ (void) setQAUserId:(NSString*) userId;

/*
 * Returns true if QA is enabled.
 */
+ (BOOL) getQAUserEnabled;
+ (void) setQAUserEnabled:(BOOL) enabled;

/*
 * Returns the QA user id using for AB testing QA if it is enabled, otherwise 
 * null.
 */
+ (NSString *) getQAUserIdIfEnabled;

@end
