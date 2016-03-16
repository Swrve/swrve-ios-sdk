#import <UIKit/UIKit.h>
#import "SwrveCommonMessageController.h"

@class SwrveConversationResource;
@class SwrveConversationPane;
@class SwrveConversationItemViewController;
@class SwrveCommonConversation;
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
@property (strong, nonatomic) IBOutlet UITableView *contentTableView;
@property (strong, nonatomic) IBOutlet UIButton *cancelButtonView;
@property (unsafe_unretained, nonatomic) IBOutlet UIView *buttonsView;
@property (strong, nonatomic) SwrveCommonConversation *conversation;
@property (strong, nonatomic) SwrveConversationPane *conversationPane;

-(void)setConversation:(SwrveCommonConversation*)conversation andMessageController:(id<SwrveCommonMessageController>)controller andWindow:(UIWindow*)window;
-(BOOL)transitionWithControl:(SwrveConversationButton *)control;

-(IBAction)cancelButtonTapped:(id)sender;
-(void)updateUI;

@end
