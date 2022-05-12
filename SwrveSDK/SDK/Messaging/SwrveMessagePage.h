#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SwrveMessagePage : NSObject

@property(retain, nonatomic) NSArray *buttons;
@property(retain, nonatomic) NSArray *images;
@property(retain, nonatomic) NSString *pageName;
@property(atomic) long pageId;
@property(atomic) long swipeForward;
@property(atomic) long swipeBackward;

- (id)initFromJson:(NSDictionary *)json
        campaignId:(long)swrveCampaignId
         messageId:(long)swrveMessageId
      appStoreURLs:(NSMutableDictionary *)appStoreURLs;

@end

NS_ASSUME_NONNULL_END
