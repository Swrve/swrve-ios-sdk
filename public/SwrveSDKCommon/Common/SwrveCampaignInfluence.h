#import <Foundation/Foundation.h>

extern NSString *const SwrveInfluencedWindowMinsKey;
extern NSString *const SwrveInfluenceDataKey;

@interface SwrveCampaignInfluence : NSObject

+ (void)saveInfluencedData:(NSDictionary *)userInfo withId:(NSString *)id withAppGroupID:(NSString *)appGroupId atDate:(NSDate *)date;

+ (void)removeInfluenceDataForId:(NSString *)pushId fromAppGroupId:(NSString *)appGroupId;

+ (void)processInfluenceDataWithDate:(NSDate *)now;

@end
