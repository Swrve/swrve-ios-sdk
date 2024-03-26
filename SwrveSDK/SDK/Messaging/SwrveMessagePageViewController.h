#import "SwrveMessage.h"
#import "SwrveInAppMessageConfig.h"

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
