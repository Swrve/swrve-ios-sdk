#ifndef EmptyProject_SwrvePrivateAccess_h
#define EmptyProject_SwrvePrivateAccess_h

#if TARGET_OS_IOS /* exclude tvOS */
#import <CoreTelephony/CTCarrier.h>
#endif //TARGET_OS_IOS

#import "Swrve.h"
#import "SwrveSDK.h"
#import "SwrveMessageController.h"
#import "SwrveMessageViewController.h"
#import "SwrveConversationItemViewController.h"
#import "SwrveConversationPane.h"
#import "SwrveConversationButton.h"
#import "SwrveAssetsManager.h"

@class SwrveRESTClient;

@interface SwrveSDK(SwrveTestAPI)

+ (void) resetSwrveSharedInstance;
+ (void) addSharedInstance:(Swrve*)instance;
+ (Swrve*)createInstance;

@end

@interface Swrve(SwrveTestAPI)

@property SwrveSignatureProtectedFile* resourcesFile;
@property SwrveSignatureProtectedFile* resourcesDiffFile;
@property NSMutableArray* eventBuffer;
@property NSURL* eventFilename;
@property NSURL* batchURL;
@property NSURL* baseCampaignsAndResourcesURL;
@property (strong) NSMutableDictionary * userUpdates;
@property(atomic) SwrveRESTClient *restClient;
#if TARGET_OS_IOS
@property (atomic, readonly)         SwrvePush *push;
#endif
@property (nonatomic) SwrveReceiptProvider* receiptProvider;

- (int) sessionStart;
- (void) resetEventCache;
- (void) updateResources:(NSArray*)resourceJson writeToCache:(BOOL)writeToCache;
- (void) _deswizzlePushMethods;
- (NSDate*) getNow;
- (UInt64) getTime;
- (UInt64) secondsSinceEpoch;
- (void) suspend:(BOOL)terminating;
- (void)initSwrveRestClient:(NSTimeInterval)timeOut urlSssionDelegate:(id <NSURLSessionDelegate>)urlSssionDelegate;
- (void) appDidBecomeActive:(NSNotification*)notification;
- (UInt64)joinedDateMilliSeconds;
- (NSURL *)campaignsAndResourcesURL;
- (NSURL *)userResourcesDiffURL;

@end

@class SwrveAssetsManager;

@interface SwrveMessageController(SwrveTestAPI)

@property (nonatomic, retain) NSString*             user;
@property (nonatomic, retain) NSString*             token;
@property (nonatomic, retain) NSArray*              campaigns;
@property (nonatomic, retain) NSString*             apiKey;
@property (nonatomic, retain) NSString*         	server;
@property (nonatomic, retain) NSString*             language;
@property (nonatomic, retain) NSMutableDictionary*  appStoreURLs;
@property (nonatomic, retain) NSString*             campaignsStateFilePath;
@property (nonatomic, retain) NSDate*               initialisedTime;
@property (nonatomic, retain) NSDate*               showMessagesAfterLaunch;
@property (nonatomic, retain) NSDate*               showMessagesAfterDelay;
@property (nonatomic) SwrveInterfaceOrientation     orientation;
@property (nonatomic, retain) SwrveSignatureProtectedFile* campaignFile;
@property (nonatomic)         bool                  autoShowMessagesEnabled;
@property (nonatomic, retain) UIWindow*             inAppMessageWindow;
@property (nonatomic, retain) UIWindow*             conversationWindow;
@property (nonatomic, retain) SwrveAssetsManager*   assetsManager;

-(void) saveCampaignsState;

@end


@interface SwrveConversationItemViewController(SwrveTestAPI)

-(void) buttonTapped:(id)sender;
-(void) setConversationPane:(SwrveConversationPane *)conversationPane;
-(void) performActions:(SwrveConversationButton *)control;

@end

@interface SwrveReceiptProvider(SwrveTestAPI)

-(NSData*)readMainBundleAppStoreReceipt;

@end

#endif
