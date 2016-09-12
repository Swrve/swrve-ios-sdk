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

@property (strong, nonatomic) SwrveBaseConversation *conversation;

-(void)setConversation:(SwrveBaseConversation*)conversation andMessageController:(id<SwrveMessageEventHandler>)controller;

-(IBAction)cancelButtonTapped:(id)sender;

-(void)dismiss;
@end
