#import "TestableSwrve.h"
#import "SwrveConversation.h"
#import "SwrveCampaign.h"
#import "SwrveConversationCampaign.h"

@interface SwrveTestConversationsHelper : NSObject

+ (TestableSwrve*)initializeWithCampaignsFile:(NSString*)filename andConfig:(SwrveConfig*)config;

+ (TestableSwrve *)initializeWithCampaignsFile:(NSString *)filename andConfig:(SwrveConfig *)config andAssets:(NSArray *)assets andDate:(NSDate *)date;

+ (SwrveConversation*)createConversationForCampaign:(NSString*)camSrc andEvent:(NSString*)eventName;
+ (SwrveConversation*)createConversationForCampaign:(NSString*)camSrc andEvent:(NSString*)eventName andPayload:(NSDictionary*)payload;
+ (SwrveConversation*)createConversationForCampaign:(NSString*)camSrc andEvent:(NSString*)eventName andPayload:(NSDictionary *)payload withController:(SwrveMessageController*)controller;

@end

