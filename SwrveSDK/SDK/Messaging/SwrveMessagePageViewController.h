#import "SwrveMessage.h"
#import "SwrveInAppMessageConfig.h"

/*! An in-app message page */
@interface SwrveMessagePageViewController : UIViewController

@property(nonatomic, weak) SwrveMessageController *messageController;
@property(nonatomic, retain) SwrveMessageFormat *messageFormat;
@property(nonatomic, retain) NSDictionary *personalization;
@property(nonatomic, retain) NSNumber *pageId;
@property(nonatomic) CGSize size;

/*! Called by the view when a button is pressed */
- (IBAction)onButtonPressed:(id)sender;

- (id)initWithMessageController:(SwrveMessageController *)messageController
                         format:(SwrveMessageFormat *)swrveMessageFormat
                personalization:(NSDictionary *)personalization
                         pageId:(NSNumber *)pageId
                           size:(CGSize)size;

@end
