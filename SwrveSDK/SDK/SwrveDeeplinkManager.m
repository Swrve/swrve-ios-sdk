#import "SwrveDeeplinkManager.h"
#import "Swrve.h"
#import "Swrve+Private.h"
#if __has_include(<SwrveSDKCommon/SwrveCommon.h>)
#import <SwrveSDKCommon/SwrveCommon.h>
#import <SwrveSDKCommon/SwrveRESTClient.h>
#import <SwrveSDKCommon/SwrveAssetsManager.h>
#import <SwrveSDKCommon/SwrveLocalStorage.h>
#import <SwrveSDKCommon/SwrveUtils.h>
#else
#import "SwrveCommon.h"
#import "SwrveRESTClient.h"
#import "SwrveAssetsManager.h"
#import "SwrveLocalStorage.h"
#import "SwrveUtils.h"
#endif
#import "SwrveConversationCampaign.h"
#import "SwrveInAppCampaign.h"
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
- (void)showMessage:(SwrveMessage *)message queue:(bool)isQueued withPersonalization:(NSDictionary *)personalization;
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
    [self fetchCampaign:adCampaignURL completion:^(NSURLResponse *response, NSDictionary *responseDic, NSError *error) {
        if (!error) {
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                long code = [(NSHTTPURLResponse*)response statusCode];
                if (code > 300) {
                    [SwrveLogger error:@"Show Campaign Error: %@", responseDic];
                }
            }
            [self writeCampaignDataToCache:responseDic fileType:SWRVE_NOTIFICATION_CAMPAIGN_FILE_DEBUG];
            [self campaignAssets:responseDic withCompletionHandler:^(SwrveCampaign *campaign) {
                if (campaign != nil) {
                    [self showCampaign:campaign];
                };
            }];
        } else {
            [self loadCampaignFromCache:campaignId];
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
        [self fetchCampaign:adCampaignURL completion:^(NSURLResponse *response, NSDictionary *responseDic, NSError *error) {
            if (!error) {
                if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                    long code = [(NSHTTPURLResponse*)response statusCode];
                    if (code > 300) {
                        [SwrveLogger error:@"Show Campaign Error: %@", responseDic];
                    }
                }
                [self writeCampaignDataToCache:responseDic fileType:SWRVE_AD_CAMPAIGN_FILE];
                [self campaignAssets:responseDic withCompletionHandler:^(SwrveCampaign *campaign) {
                    if (campaign != nil) {
                        [self showCampaign:campaign];
                    };
                }];
            }
        }];

        [self queueDeeplinkGenericEvent:[adSource lowercaseString] campaignID:campaignID campaignName:campaignName acitonType:actionType];
        [self.sdk sendQueuedEvents];

        //reset action type
        self.actionType = SWRVE_AD_REENGAGE;
    }
}

- (void)writeCampaignDataToCache:(NSDictionary *)response fileType:(int)fileType {
    if (response != nil) {
        NSData *campaignData = [NSJSONSerialization dataWithJSONObject:response options:0 error:nil];
        SwrveSignatureProtectedFile *campaignFile = [self signatureFileWithType:fileType errorDelegate:nil];

        [campaignFile writeToFile:campaignData];
    }
}

- (SwrveSignatureProtectedFile *)signatureFileWithType:(int)type errorDelegate:(id <SwrveSignatureErrorDelegate>)delegate {
    SwrveSignatureProtectedFile *file =[[SwrveSignatureProtectedFile alloc] protectedFileType:type
                                                                                       userID:self.sdk.userID
                                                                                 signatureKey:[self.sdk signatureKey]
                                                                                  errorDelegate:delegate];

    return file;
}

- (void)queueDeeplinkGenericEvent:(NSString *)adSource
                       campaignID:(NSString *)campaignID
                     campaignName:(NSString *)campaignName
                       acitonType:(NSString *)actionType {

    if (adSource == nil || [adSource isEqualToString:@""]) {
        [SwrveLogger error:@"DeeplinkCampaign adSource was nil or an empty string. Generic event not queued", nil];
        return;
    }
    adSource = [@"external_source_" stringByAppendingString:adSource];

    NSDictionary *eventData = @{@"campaignType" :NullableNSString(adSource),
                                @"actionType"   :NullableNSString(actionType),
                                @"campaignId"   :NullableNSString(campaignID),
                                @"contextId"    :NullableNSString(campaignName),
                                @"id"           :@-1
                                };

    [self.sdk queueEvent:@"generic_campaign_event" data:[eventData mutableCopy] triggerCallback:NO];
}

- (void)fetchCampaign:(NSURL *)url
           completion:(void (^)(NSURLResponse *response,NSDictionary *responseDic, NSError *error))completion {
    [SwrveLogger debug:@"DeeplinkCampaign URL %@", url];

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

- (void)campaignAssets:(NSDictionary *)campaignJson withCompletionHandler:(void (^)(SwrveCampaign * campaign))completionHandler {

    if (campaignJson == nil) {
        [SwrveLogger error:@"Error parsing campaign JSON", nil];
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
        [SwrveLogger debug:@"CDN URL images: %@ fonts:%@", cdnImages, cdnFonts];
    } else {
        NSString *cdnRoot = [campaignJson objectForKey:@"cdn_root"];
        [self.assetsManager setCdnImages:cdnRoot];
        [SwrveLogger debug:@"CDN URL: %@", cdnRoot];
    }

    // Version check
    NSNumber *version = [additionalInfoDic objectForKey:@"version"];
    if ([version integerValue] != CAMPAIGN_RESPONSE_VERSION){
        [SwrveLogger error:@"Campaign JSON has the wrong version. No campaigns loaded.", nil];
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
                [SwrveLogger error:@"Conversation version %@ cannot be loaded with this SDK.", conversationVersion];
            }
        }
    } else if ([campaignDic objectForKey:@"message"] != nil)  {
        
        // retrieve personalization
        NSDictionary *personalization = [[_sdk messaging] retrievePersonalizationProperties:nil];
        
        campaign = [[SwrveInAppCampaign alloc] initAtTime:self.sdk.messaging.initialisedTime fromDictionary:campaignDic withAssetsQueue:assetsQueue forController:self.sdk.messaging withPersonalization:personalization];
    } else if ([campaignDic objectForKey:@"embedded_message"] != nil) {
        campaign = [[SwrveEmbeddedCampaign alloc] initAtTime:self.sdk.messaging.initialisedTime fromDictionary:campaignDic forController:self.sdk.messaging];
    } else {
        [SwrveLogger error:@"Unknown campaign type", nil];
        return;
    }

    if (campaign == nil) {
        if (completionHandler != nil) {
            completionHandler(nil);
        }
        return;
    }

    // Obtain assets we don't have yet
    [self.assetsManager downloadAssets:assetsQueue withCompletionHandler:^ {
        if (completionHandler != nil) {
            completionHandler(campaign);
        }
    }];
}

- (void)showCampaign:(SwrveCampaign *)campaign {
    if ([campaign isKindOfClass:[SwrveConversationCampaign class]]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            SwrveConversation *conversation = ((SwrveConversationCampaign *)campaign).conversation;
            [self.sdk.messaging showConversation:conversation queue:true];
        });
    } else if ([campaign isKindOfClass:[SwrveInAppCampaign class]]) {
        SwrveInAppCampaign *swrveCampaign = (SwrveInAppCampaign *)campaign;
        SwrveMessage *message = swrveCampaign.message;

        // Show the message if it exists and personalization can be resolved
        if (message != nil) {
            NSDictionary *personalization = [[self.sdk messaging] retrievePersonalizationProperties:nil];
            if ([message canResolvePersonalization:personalization]) {
                dispatch_block_t showMessageBlock = ^{
                    [self.sdk.messaging showMessage:message queue:true withPersonalization:personalization];
                };
                if ([NSThread isMainThread]) {
                    showMessageBlock();
                } else {
                    // Run in the main thread as we have been called from other thread
                    dispatch_async(dispatch_get_main_queue(), showMessageBlock);
                }
            } else {
                [SwrveLogger warning:@"Personalizaton options are not available for this message.", nil];
            }
        }
    } else if ([campaign isKindOfClass:[SwrveEmbeddedCampaign class]]) {
        NSDictionary *personalization = [[self.sdk messaging] retrievePersonalizationProperties:nil];
        SwrveEmbeddedMessage *message = ((SwrveEmbeddedCampaign *)campaign).message;
        if(message != nil) {
            if(self.sdk.config.embeddedMessageConfig.embeddedMessageCallbackWithPersonalization != nil) {
                self.sdk.config.embeddedMessageConfig.embeddedMessageCallbackWithPersonalization(message, personalization);
            } else if (self.sdk.config.embeddedMessageConfig.embeddedMessageCallback != nil) {
                self.sdk.config.embeddedMessageConfig.embeddedMessageCallback(message);
            }
        }
    }
    
    self.alreadySeenCampaignID = [NSString stringWithFormat:@"%lu",(unsigned long)campaign.ID];
}


- (void)loadCampaignFromCache:(NSString *)campaignId  {
    NSDictionary *cachedCampaigs = [self campaignsInCache:SWRVE_NOTIFICATION_CAMPAIGNS_FILE];
    NSDictionary *cachedCampaign = [cachedCampaigs objectForKey:campaignId];
    if (cachedCampaign != nil) {
        [self campaignAssets:cachedCampaign withCompletionHandler:^(SwrveCampaign *campaign) {
            if (campaign != nil) {
                [self showCampaign:campaign];
            };
        }];
    } else {
        [SwrveLogger debug:@"SwrveDeeplinkManager: unable to load campaignId:%@ from cache", campaignId];
    }
}

- (void)fetchNotificationCampaigns:(NSMutableSet *)campaignIds {

    //write to cache once all campaigns have finished downloading
    dispatch_group_t campaignGroup = dispatch_group_create();

    __block NSMutableDictionary *offlineCampaigns = [NSMutableDictionary new];

    for (NSString *campaignId in campaignIds) {
        dispatch_group_enter(campaignGroup);
        NSURL *campaignUrl = [self campaignURL:campaignId];
        [self fetchCampaign:campaignUrl completion:^(NSURLResponse *response, NSDictionary *responseDic, NSError *error) {
            if (!error) {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                NSInteger statusCode = [httpResponse statusCode];
                if (statusCode == 200) {
                    NSDictionary *campaignDic = [responseDic objectForKey:@"campaign"];
                    NSString *linkedCampaignId = [SwrveUtils getStringFromDic:campaignDic withKey:@"id"];
                    if (linkedCampaignId != nil) {
                        [offlineCampaigns setObject:responseDic forKey:linkedCampaignId];
                        [self campaignAssets:responseDic withCompletionHandler:nil];
                    }
                }
            }
           dispatch_group_leave(campaignGroup);
        }];
    }

    dispatch_group_notify(campaignGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self writeCampaignDataToCache:offlineCampaigns fileType:SWRVE_NOTIFICATION_CAMPAIGNS_FILE];
    });
}

- (NSDictionary *)campaignsInCache:(int)fileType {
    SwrveSignatureProtectedFile *campaignFile = [self signatureFileWithType:fileType errorDelegate:nil];

    NSData *campaignData = [campaignFile readFromFile];
    NSDictionary *campaignDic = nil;
    if (campaignData != nil) {
        campaignDic = [NSJSONSerialization JSONObjectWithData:campaignData options:0 error:nil];
    }
    return campaignDic;
}

@end
