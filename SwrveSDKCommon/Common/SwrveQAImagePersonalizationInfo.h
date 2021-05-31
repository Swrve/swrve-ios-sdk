#import <Foundation/Foundation.h>

@interface SwrveQAImagePersonalizationInfo : NSObject

@property (atomic)       NSUInteger             campaignID;
@property (atomic)       NSUInteger             variantID;
@property (atomic)       NSString*              assetName;
@property (nonatomic)    BOOL                   hasFallback;
@property (atomic)       NSString*              unresolvedUrl;
@property (atomic)       NSString*              resolvedUrl;
@property (atomic)       NSString               *reason;


- (id) initWithCampaign:(NSUInteger)campaignId
              variantID:(NSUInteger)variantId
              assetName:(NSString *)assetname
            hasFallback:(BOOL)hasfallback
          unresolvedUrl:(NSString *)unresolvedURL
            resolvedUrl:(NSString *)resolvedURL
                 reason:(NSString *)reason;

@end

