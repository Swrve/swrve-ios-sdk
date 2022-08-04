#import <UIKit/UIKit.h>
#import "SwrveMessageEventHandler.h"

@class SwrveConversationResource;
@class SwrveConversationPane;
@class SwrveConversationItemViewController;
@class SwrveBaseConversation;
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

@property (strong, nonatomic) UIImageView *fullScreenBackgroundImageView;
@property (strong, nonatomic) UITableView *contentTableView;
@property (strong, nonatomic) UIButton *cancelButtonView;
@property (strong, nonatomic) UIView *buttonsView;
@property (strong, nonatomic) SwrveBaseConversation *conversation;
@property (strong, nonatomic) SwrveConversationPane *conversationPane;
@property (readwrite, nonatomic) float contentHeight;

+ (SwrveConversationItemViewController*)initConversation;
// Unity Bridge function
+ (SwrveConversationItemViewController*)initFromStoryboard;

+ (bool)showConversation:(SwrveBaseConversation *)conversation
      withItemController:(SwrveConversationItemViewController *)conversationItemViewController
        withEventHandler:(id<SwrveMessageEventHandler>) eventHandler
                inWindow:(UIWindow *)conversationWindow
     withMessageDelegate:(id)messageDelegate;

+ (bool)showConversation:(SwrveBaseConversation *)conversation
      withItemController:(SwrveConversationItemViewController *)conversationItemViewController
        withEventHandler:(id<SwrveMessageEventHandler>) eventHandler
                inWindow:(UIWindow *)conversationWindow
     withStatusBarHidden:(BOOL)prefeerStatusBarHidden;

-(void)setConversation:(SwrveBaseConversation*)conversation andMessageController:(id<SwrveMessageEventHandler>)controller;
-(BOOL)transitionWithControl:(SwrveConversationButton *)control;

-(IBAction)cancelButtonTapped:(id)sender;
-(void)updateUI;
-(void)dismiss;
@end
