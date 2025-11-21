#import <Foundation/Foundation.h>

typedef enum {
    SWRVE_CAMPAIGN_IAM = 0,
    SWRVE_CAMPAIGN_EMBEDDED = 1
} SwrveCampaignType;

// Macro to convert SwrveCampaignType to NSString
#define swrveCampaignTypeToString(enum) [@[@"iam", @"embedded"] objectAtIndex:enum]

@interface SwrveQACampaignInfo : NSObject
@property (atomic)       NSUInteger             campaignID;
@property (atomic)       NSUInteger             variantID;
@property (nonatomic, getter=isDisplayed) BOOL  displayed;
@property (nonatomic)    SwrveCampaignType      type;
@property (atomic)       NSString               *reason;

- (id) initWithCampaignID:(NSUInteger)campaignID
                variantID:(NSUInteger)variantID
                     type:(SwrveCampaignType)type
                displayed:(BOOL)displayed
                   reason:(NSString *)reason;
@end
