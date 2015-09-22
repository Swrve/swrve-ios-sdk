#import <Foundation/Foundation.h>

@interface SwrveLocationPayload : NSObject

@property(readonly, atomic, strong) NSString *geofenceId;
@property(readonly, atomic, strong) NSString *campaignId;

- (id)initWithPayload:(NSString *)payload;
@end
