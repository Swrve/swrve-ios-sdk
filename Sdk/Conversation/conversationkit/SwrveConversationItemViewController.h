#import <UIKit/UIKit.h>

@class SwrveConversationResource;
@class SwrveConversationPane;
@class SwrveConversationItemViewController;
@class SwrveConversation;

typedef enum {
    SwrveCallNumberActionType,
    SwrveVisitURLActionType,
    SwrveDeeplinkActionType
} SwrveConversationActionType;

@interface SwrveConversationItemViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    SwrveConversationPane *_conversationPane;
    SwrveConversationResource *_engine;
}

@property (strong, nonatomic) IBOutlet UIImageView *fullScreenBackgroundImageView;
@property (strong, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (strong, nonatomic) IBOutlet UIImageView *buttonsBackgroundImageView;
@property (strong, nonatomic) IBOutlet UITableView *contentTableView;
@property (strong, nonatomic) IBOutlet UIButton *cancelButtonView;
@property (unsafe_unretained, nonatomic) IBOutlet UIView *buttonsView;
@property (strong, nonatomic) SwrveConversation *conversation;

-(id)initWithConversation:(SwrveConversation*)conversation;

-(IBAction)cancelButtonTapped:(id)sender;
-(void)updateUI;

@end
