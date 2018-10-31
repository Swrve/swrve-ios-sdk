#import "SwrveDeeplinkManager.h"
#import "Swrve.h"
#import "SwrveRESTClient.h"
#import "SwrveUtils.h"
#import "SwrveAssetsManager.h"
#import "SwrveLocalStorage.h"
#import "SwrveConversationCampaign.h"
#import "SwrveInAppCampaign.h"
#import "SwrveCommon.h"
#import "SwrveMessageController+Private.h"

@interface Swrve()
- (NSString *) appVersion;
- (UInt64)joinedDateMilliSeconds;
- (int)queueEvent:(NSString *)eventType data:(NSMutableDictionary *)eventData triggerCallback:(bool)triggerCallback;
- (NSString *)signatureKey;
- (NSString *)userID;
@property(atomic) SwrveRESTClient *restClient;
@end

@interface SwrveMessageController()
- (NSString *)campaignQueryString;
- (BOOL)filtersOk:(NSArray *)filters;
- (void)showMessage:(SwrveMessage *)message queue:(bool)isQueued;
- (void)showConversation:(SwrveConversation *)conversation queue:(bool)isQueued;
@property (nonatomic, retain) NSDate *initialisedTime; // SDK init time
@end

@interface SwrveDeeplinkManager ()
@property (atomic) Swrve *sdk;
@property (atomic) SwrveAssetsManager *assetsManager;
@property (atomic) NSString *alreadySeenCampaignID;

@end

@implementation SwrveDeeplinkManager

@synthesize sdk = _sdk;
@synthesize assetsManager = _assetsManager;
@synthesize actionType = _actionType;
@synthesize alreadySeenCampaignID;

- (instancetype)initWithSwrve:(Swrve *)sdk {
    
    self = [super init];
    if (self) {
        _sdk = sdk;
        _actionType = SWRVE_AD_REENGAGE;
         NSString *cacheFolder = [SwrveLocalStorage swrveCacheFolder];
         _assetsManager = [[SwrveAssetsManager alloc] initWithRestClient:_sdk.restClient andCacheFolder:cacheFolder];
    }
    return self;
}

+ (BOOL)isSwrveDeeplink:(NSURL *)url {
    NSDictionary *queryParam = [SwrveUtils parseURLQueryParams:[url query]];
    if (queryParam != nil) {
        NSString *campaignID = [queryParam objectForKey:SWRVE_AD_CONTENT];
        if (campaignID == nil) {
            return false;
        }
    }
    return true;
    
}

-(void)handleNotificationToCampaign:(NSString *)campaignId {
    NSURL *adCampaignURL = [self campaignURL:campaignId];
    [self loadCampaign:adCampaignURL :^(NSURLResponse *response, NSDictionary *responseDic, NSError *error) {
        if (!error) {
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                long code = [(NSHTTPURLResponse*)response statusCode];
                if (code > 300) {
                    DebugLog(@"Show Campaign Error: %@",responseDic);
                }
            }
            [self writeCampaignDataToCache:responseDic fileType:SWRVE_NOTIFICATION_CAMPAIGN_FILE_DEBUG];
            [self showCampaign:responseDic];
        }
    }];
}

- (void)handleDeferredDeeplink:(NSURL *)url {
    [self handleDeeplink:url actionType:SWRVE_AD_INSTALL];
}

- (void)handleDeeplink:(NSURL *)url {
    [self handleDeeplink:url actionType:nil];
}

- (void)handleDeeplink:(NSURL *)url actionType:(NSString *)actionType {
    if (actionType == nil) {
        // Default is 'reengage', but developer can set this property to 'install' in a deferred action callback from FB
        // using [SwrveSDK installAction:url] or they can just call handleDeferredDeeplink:url  Gives them the option to do either.
        actionType = self.actionType;
    }
    
    NSDictionary *queryParam = [SwrveUtils parseURLQueryParams:[url query]];
    if (queryParam != nil) {
        NSString *adSource = [queryParam objectForKey:SWRVE_AD_SOURCE];
        NSString *campaignName = [queryParam objectForKey:SWRVE_AD_CAMPAIGN];
        NSString *campaignID = [queryParam objectForKey:SWRVE_AD_CONTENT];
        
        if (campaignID == nil) { return; }
        if ([campaignID isEqualToString:self.alreadySeenCampaignID]) {  return; }
        
        NSURL *adCampaignURL = [self campaignURL:campaignID];
        [self loadCampaign:adCampaignURL :^(NSURLResponse *response, NSDictionary *responseDic, NSError *error) {
            if (!error) {
                if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                    long code = [(NSHTTPURLResponse*)response statusCode];
                    if (code > 300) {
                        DebugLog(@"Show Campaign Error: %@",responseDic);
                    }
                }
                [self writeCampaignDataToCache:responseDic fileType:SWRVE_AD_CAMPAIGN_FILE];
                [self showCampaign:responseDic];
            }
        }];
        
        [self queueDeeplinkGenericEvent:[adSource lowercaseString] campaignID:campaignID campaignName:campaignName acitonType:actionType];
        [self.sdk sendQueuedEvents];
        
        //reset action type
        self.actionType = SWRVE_AD_REENGAGE;
    }
}

-(void)writeCampaignDataToCache:(NSDictionary *)responseDic fileType:(int)fileType {
    if (responseDic != nil) {
        NSData *campaignData = [NSJSONSerialization dataWithJSONObject:responseDic options:0 error:nil];
        SwrveSignatureProtectedFile *campaignFile =  [[SwrveSignatureProtectedFile alloc] protectedFileType:fileType
                                                                                                     userID:self.sdk.userID
                                                                                               signatureKey:[self.sdk signatureKey]
                                                                                              errorDelegate:nil];
        
        [campaignFile writeToFile:campaignData];
    }
}

- (void)queueDeeplinkGenericEvent:(NSString *)adSource
                       campaignID:(NSString *)campaignID
                     campaignName:(NSString *)campaignName
                       acitonType:(NSString *)actionType {
    
    if (adSource == nil || [adSource isEqualToString:@""]) {
        DebugLog(@"DeeplinkCampaign adSource was nil or an empty string. Generic event not queued", nil);
        return;
    }
    adSource = [@"external_source_" stringByAppendingString:adSource];
    
    NSDictionary *eventData = @{@"campaignType" :NullableNSString(adSource),
                                @"actionType"   :NullableNSString(actionType),
                                @"campaignId"   :NullableNSString(campaignID),
                                @"contextId"    :NullableNSString(campaignName),
                                @"id"           :@-1
                                };
    
    (void)[self.sdk queueEvent:@"generic_campaign_event" data:[eventData mutableCopy] triggerCallback:NO];
}
- (void)loadCampaign:(NSURL *)url
                    :(void (^)(NSURLResponse *response,NSDictionary *responseDic, NSError *error))completion {
    DebugLog(@"DeeplinkCampaign URL %@", url);
    
    [self.sdk.restClient sendHttpGETRequest:url completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
#pragma unused(response)
        NSDictionary *responseDict = nil;
        if (data != nil) {
           responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        }
        completion(response,responseDict,error);
    }];
}

- (NSURL *)campaignURL:(NSString *)campaignID {
    NSMutableString *queryString = [NSMutableString stringWithFormat:@"?in_app_campaign_id=%@&user=%@&api_key=%@&app_version=%@&joined=%llu",
                                    campaignID,[self.sdk userID], self.sdk.apiKey, self.sdk.appVersion, self.sdk.joinedDateMilliSeconds];
    
    if (self.sdk.messaging) {
        NSString *campaignQueryString = [self.sdk.messaging campaignQueryString];
        [queryString appendFormat:@"&%@", campaignQueryString];
    }
    
    NSURL *base_content_url = [NSURL URLWithString:self.sdk.config.contentServer];
    NSURL *adCampaignURL = [NSURL URLWithString:SWRVE_AD_CAMPAIGN_URL relativeToURL:base_content_url];
    
    return [NSURL URLWithString:queryString relativeToURL:adCampaignURL];
}

-(void)showCampaign:(NSDictionary *)campaignJson {
    
    if (campaignJson == nil) {
        DebugLog(@"Error parsing campaign JSON", nil);
        return;
    }
    
    //Top level dictionaries
    NSDictionary *campaignDic = [campaignJson objectForKey:@"campaign"];
    NSDictionary *additionalInfoDic = [campaignJson objectForKey:@"additional_info"];
    
    //Update CDN paths
    NSDictionary *cdnPaths = [additionalInfoDic objectForKey:@"cdn_paths"];
    if (cdnPaths) {
        NSString *cdnImages = [cdnPaths objectForKey:@"message_images"];
        [self.assetsManager setCdnImages:cdnImages];
        NSString *cdnFonts = [cdnPaths objectForKey:@"message_fonts"];
        [self.assetsManager setCdnFonts:cdnFonts];
        DebugLog(@"CDN URL images:%@ fonts:%@", cdnImages, cdnFonts);
    } else {
        NSString *cdnRoot = [campaignJson objectForKey:@"cdn_root"];
        [self.assetsManager setCdnImages:cdnRoot];
        DebugLog(@"CDN URL %@", cdnRoot);
    }
    
    // Version check
    NSNumber *version = [additionalInfoDic objectForKey:@"version"];
    if ([version integerValue] != CAMPAIGN_RESPONSE_VERSION){
        DebugLog(@"Campaign JSON has the wrong version. No campaigns loaded.", nil);
        return;
    }
    
    NSMutableSet *assetsQueue = [[NSMutableSet alloc] init];
    SwrveCampaign *campaign = nil;
    if ([campaignDic objectForKey:@"conversation"] != nil) {
        if ([self.sdk.messaging filtersOk:[campaignJson objectForKey:@"filters"]]) {
            // Conversation version check
            NSNumber *conversationVersion = [campaignJson objectForKey:@"conversation_version"];
            if (conversationVersion == nil || [conversationVersion integerValue] <= CONVERSATION_VERSION) {
                campaign = [[SwrveConversationCampaign alloc] initAtTime:self.sdk.messaging.initialisedTime fromDictionary:campaignDic withAssetsQueue:assetsQueue forController:self.sdk.messaging];
            } else {
                DebugLog(@"Conversation version %@ cannot be loaded with this SDK.", conversationVersion);
            }
        }
    } else if ([campaignDic objectForKey:@"messages"] != nil)  {
        campaign = [[SwrveInAppCampaign alloc] initAtTime:self.sdk.messaging.initialisedTime fromDictionary:campaignDic withAssetsQueue:assetsQueue forController:self.sdk.messaging];
    } else {
        DebugLog(@"Unknown campaign type",nil);
        return;
    }
    
    if (campaign == nil) { return; }
    
    // Obtain assets we don't have yet
    [self.assetsManager downloadAssets:assetsQueue withCompletionHandler:^ {
        
        self.alreadySeenCampaignID =  [NSString stringWithFormat:@"%lu",(unsigned long)campaign.ID];
        if ([campaign isKindOfClass:[SwrveConversationCampaign class]]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                SwrveConversation *conversation = ((SwrveConversationCampaign *)campaign).conversation;
                if( [self.sdk.messaging.showMessageDelegate respondsToSelector:@selector(showConversation:)]) {
                    [self.sdk.messaging.showMessageDelegate showConversation:conversation];
                } else {
                    [self.sdk.messaging showConversation:conversation queue:true];
                }
            });
        } else if ([campaign isKindOfClass:[SwrveInAppCampaign class]]) {
            SwrveMessage *message = [((SwrveInAppCampaign *)campaign).messages objectAtIndex:0];

            // Show the message if it exists
            if( message != nil ) {
                dispatch_block_t showMessageBlock = ^{
                    if( [self.sdk.messaging.showMessageDelegate respondsToSelector:@selector(showMessage:)]) {
                        [self.sdk.messaging.showMessageDelegate showMessage:message];
                    }
                    else {
                        [self.sdk.messaging showMessage:message queue:true];
                    }
                };
                
                if ([NSThread isMainThread]) {
                    showMessageBlock();
                } else {
                    // Run in the main thread as we have been called from other thread
                    dispatch_async(dispatch_get_main_queue(), showMessageBlock);
                }
            }
        }
    }];
}

@end
