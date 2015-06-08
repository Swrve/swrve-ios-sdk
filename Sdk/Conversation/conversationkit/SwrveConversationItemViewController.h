#import <UIKit/UIKit.h>

@class SwrveConversationResource;
@class SwrveConversationPane;
@class SwrveConversationItemViewController;
@class SwrveConversation;
@class SwrveConversationButton;

typedef enum {
    SwrveCallNumberActionType,
    SwrveVisitURLActionType,
    SwrveDeeplinkActionType,
    SwrvePermissionRequestActionType
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
@property (strong, nonatomic) SwrveConversationPane *conversationPane;

-(id)initWithConversation:(SwrveConversation*)conversation withMessageController:(SwrveMessageController*)controller;
-(BOOL)transitionWithControl:(SwrveConversationButton *)control;

-(IBAction)cancelButtonTapped:(id)sender;
-(void)updateUI;

@end
