#import <Foundation/Foundation.h>

@interface PlotPayload : NSObject

@property(readonly, atomic, strong) NSString *campaignId;

@property(readonly, atomic, strong) NSString *geofenceLabel;

- (id)initWithPayload:(NSString *)payload;

@end
