#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SwrveEvents : NSObject

#pragma mark QA SDK Events

+ (NSMutableDictionary *)qalogWrappedEvent:(NSDictionary *) dic;
+ (NSMutableDictionary *)qalogCampaignsDownloaded:(NSArray *) array;
+ (NSMutableDictionary *)qalogCampaignButtonClicked:(NSDictionary *) campaign;
+ (NSMutableDictionary *)qaLogEvent:(NSDictionary *) logDetails logType:(NSString *) logType;

@end

NS_ASSUME_NONNULL_END


