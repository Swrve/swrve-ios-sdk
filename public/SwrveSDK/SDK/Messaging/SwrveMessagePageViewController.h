#if __has_include(<SwrveSDK/SwrveMessageController.h>)
#import <SwrveSDK/SwrveMessageController.h>
#import <SwrveSDK/SwrveMessageFormat.h>
#else
#import "SwrveMessageController.h"
#import "SwrveMessageFormat.h"
#endif

/*! An in-app message page */
@interface SwrveMessagePageViewController : UIViewController

@property(nonatomic, weak) SwrveMessageController *messageController;
@property(nonatomic, retain) SwrveMessageFormat *messageFormat;
@property(nonatomic, retain) NSDictionary *personalization;
@property(nonatomic, retain) NSNumber *pageId;
@property(nonatomic) CGSize size;


- (id)initWithMessageController:(SwrveMessageController *)messageController
                         format:(SwrveMessageFormat *)swrveMessageFormat
                personalization:(NSDictionary *)personalization
                         pageId:(NSNumber *)pageId
                           size:(CGSize)size;

@end
