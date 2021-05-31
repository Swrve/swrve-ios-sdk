#import "SwrveTestConversationsHelper.h"
#import "SwrveTestHelper.h"
#import "SwrveMessageController+Private.h"
#import "SwrveLocalStorage.h"
#import "SwrveMigrationsManager.h"

@interface SwrveMigrationsManager (SwrveInternalAccess)

+ (void)markAsMigrated;

@end

@interface SwrveMessageController(SwrveTestAPI)

- (SwrveConversation *)conversationForEvent:(NSString *)eventName withPayload:(NSDictionary *)payload;

@end

@implementation SwrveTestConversationsHelper

+(TestableSwrve*)initializeWithCampaignsFile:(NSString*)filename andConfig:(SwrveConfig*)config {
    return [SwrveTestConversationsHelper initializeWithCampaignsFile:filename andConfig:config andAssets:[self testJSONAssets] andDate:[NSDate dateWithTimeIntervalSince1970:1362873600]];
}

+ (TestableSwrve *)initializeWithCampaignsFile:(NSString *)filename andConfig:(SwrveConfig *)config andAssets:(NSArray *)assets andDate:(NSDate *)date {
    [SwrveTestHelper createDummyAssets:assets];
    NSString* apiKey = @"someAPIKey";
    NSString* userId = @"someUserID";
    UInt64 secondsSinceEpoch = (unsigned long long)([[NSDate date] timeIntervalSince1970]);
    NSString* signatureKey = [NSString stringWithFormat:@"%@%llu", apiKey, secondsSinceEpoch];
    
    // Start saving campaign cache (need specific user and install time to be set)
    [SwrveLocalStorage saveSwrveUserId:userId];
    [SwrveLocalStorage saveAppInstallTime:secondsSinceEpoch];
    [SwrveLocalStorage saveUserJoinedTime:secondsSinceEpoch forUserId:userId];
    // Set as migrated to avoid running migrations in this tests
    [SwrveMigrationsManager markAsMigrated];
    SwrveSignatureProtectedFile* campaignFile =  [[SwrveSignatureProtectedFile alloc] protectedFileType:SWRVE_CAMPAIGN_FILE
                                                                                                 userID:userId
                                                                                           signatureKey:signatureKey
                                                                                          errorDelegate:nil];
    [self overwriteCampaignFile:campaignFile withFile:filename];
    
    // Start real SDK instance we are going to use
    if (config == nil) {
        config = [[SwrveConfig alloc] init];
    }
    [config setAutoDownloadCampaignsAndResources:NO];
 
    [SwrveLogger debug:@"Finished setting up campaign data for unit tests...", nil];
    
    // March 10, 2013
    TestableSwrve* swrve = [TestableSwrve sharedInstanceWithAppID:123 apiKey:apiKey config:config customNow:date];
    [swrve appDidBecomeActive:nil];
    [SwrveSDK addSharedInstance:swrve];
    
    return swrve;
}

+ (SwrveConversation*)createConversationForCampaign:(NSString*)camSrc andEvent:(NSString*)eventName {
    return [SwrveTestConversationsHelper createConversationForCampaign:camSrc andEvent:eventName andPayload:nil withController:[SwrveMessageController alloc]];
}

+ (SwrveConversation*)createConversationForCampaign:(NSString*)camSrc andEvent:(NSString*)eventName andPayload:(NSDictionary*)payload {
    return [SwrveTestConversationsHelper createConversationForCampaign:camSrc andEvent:eventName andPayload:payload withController:[SwrveMessageController alloc]];
}

+ (SwrveConversation*)createConversationForCampaign:(NSString*)camSrc andEvent:(NSString*)eventName andPayload:(NSDictionary *)payload withController:(SwrveMessageController*)controller {
    // Load in the test JSON from the TestableSwrve group
    TestableSwrve *ts = [self initializeWithCampaignsFile:camSrc andConfig:nil];
    controller = [controller initWithSwrve:ts];
    [ts setCustomNowDate:[NSDate dateWithTimeInterval:280 sinceDate:[ts getNow]]];
    
    return [controller conversationForEvent:eventName withPayload:payload];
}

+(void) overwriteCampaignFile:(SwrveSignatureProtectedFile*)signatureFile withFile:(NSString*)filename {
    NSURL* path = [[NSBundle bundleForClass:[TestableSwrve class]] URLForResource:filename withExtension:@"json"];
    NSString* campaignData = [NSString stringWithContentsOfURL:path encoding:NSUTF8StringEncoding error:nil];
    if (campaignData == nil) {
        [NSException raise:@"No content in JSON test file" format:@"File %@ has no content", filename];
        
    }
    [SwrveTestHelper writeData:campaignData toProtectedFile:signatureFile];
}

+(NSArray*) testJSONAssets {
    static NSArray* assets = nil;
    if (!assets) {
        assets = @[
                   @"281af8272a42b2da21886fd36eef3829e6aadb80"
                   ];
    }
    return assets;
}

@end
