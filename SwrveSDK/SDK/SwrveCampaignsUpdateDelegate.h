#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SwrveCampaignsUpdateDelegate <NSObject>

/*! Invoked once after the initial content load attempt, whether or not it succeeded or anything changed, and again whenever content the SDK has fetched may have changed the campaigns. Invocations are independent and arrive in no guaranteed order.
 *
 * Campaigns are a snapshot, so re-read them on every invocation rather than holding the previous result. The SDK does not compare against what you last read, so let your own comparison decide whether to redraw. It covers every campaign surface, including Message Center and embedded.
 *
 * Register where the SDK is created: the initial notification is sent once and never replayed, so a delegate installed later may miss it.
 *
 * SDK-driven changes only. markMessageCenterCampaignAsSeen and removeMessageCenterCampaign change what the getters return without invoking this, so re-read after your own calls.
 *
 * One of the invocations follows the SDK's attempt to download campaign assets, which is when new campaigns normally become readable — a campaign is not listable until its assets are on disk, and individual downloads can fail, so this is not a promise that everything is present.
 *
 * The SDK holds the listener weakly, so keep a reference to it yourself.
 */
- (void)campaignsUpdated;

@end
NS_ASSUME_NONNULL_END
