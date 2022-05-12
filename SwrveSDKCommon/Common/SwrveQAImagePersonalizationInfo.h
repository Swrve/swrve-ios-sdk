#import <Foundation/Foundation.h>

@interface SwrveQAImagePersonalizationInfo : NSObject

@property(atomic) NSUInteger campaignID;
@property(atomic) NSUInteger variantID;
@property(atomic) NSString *assetName;
@property(nonatomic) BOOL hasFallback;
@property(atomic) NSString *unresolvedUrl;
@property(atomic) NSString *resolvedUrl;
@property(atomic) NSString *reason;

- (id)initWithCampaign:(NSUInteger)campaignId
             variantID:(NSUInteger)variantId
           hasFallback:(BOOL)hasfallback
         unresolvedUrl:(NSString *)unresolvedURL;

@end

