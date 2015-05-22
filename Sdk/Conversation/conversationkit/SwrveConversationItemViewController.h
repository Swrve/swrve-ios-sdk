#import <UIKit/UIKit.h>

@class SwrveConversationResource;
@class SwrveConversationPane;
@class SwrveConversationItemViewController;
@class SwrveFeedbackViewController;
@class SwrveConversation;

typedef enum {
    SwrveConversationResultCancelled,
    SwrveConversationResultSent,
    SwrveConversationResultFailed,
} SwrveConversationResultType;

typedef enum {
    SwrveCallNumberActionType,
    SwrveVisitURLActionType
} SwrveConversationActionType;

@interface SwrveConversationItemViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    SwrveConversationPane *_conversationPane;
    SwrveConversationResource *_engine;
}

@property (strong, nonatomic) IBOutlet UIImageView *fullScreenBackgroundImageView;
@property (strong, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (strong, nonatomic) IBOutlet UIImageView *buttonsBackgroundImageView;
@property (strong, nonatomic) IBOutlet UITableView *contentTableView;
@property (unsafe_unretained, nonatomic) IBOutlet UIView *buttonsView;

-(id)initWithConversation:(SwrveConversation*)conversation;

-(IBAction)cancelButtonTapped:(id)sender;
-(void)updateUI;

@end
