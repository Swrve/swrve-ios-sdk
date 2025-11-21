#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SwrveEventQueueItem : NSObject

@property(atomic) NSString *eventType;
@property(atomic) NSMutableDictionary *eventData;
@property(atomic) bool triggerCallback;
@property(atomic) bool notifyMessageController;

- (instancetype)initWithEventType:(NSString *)eventType
                        eventData:(NSMutableDictionary *)eventData
                  triggerCallback:(bool)triggerCallback
          notifyMessageController:(bool)notifyMessageController;

@end

NS_ASSUME_NONNULL_END
