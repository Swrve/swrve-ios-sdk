
/*******************************************************
 * Copyright (C) 2011-2012 Converser contact@converser.io
 *
 * This file is part of the Converser iOS SDK.
 *
 * This code may not be copied and/or distributed without the express
 * permission of Converser. Please email contact@converser.io for
 * all redistribution and reuse enquiries.
 *******************************************************/

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

@protocol SwrveConversationItemViewControllerDelegate <NSObject>

@optional
-(void) conversationController:(SwrveConversationItemViewController *)controller
         didFinishWithResult:(SwrveConversationResultType)result
                       error:(NSError *)error;

-(BOOL) conversationController:(SwrveConversationItemViewController *)controller
                willTakeAction:(SwrveConversationActionType)action
                     withParam:(NSString*)param;
@end


@interface SwrveConversationItemViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    SwrveConversationPane *_conversationPane;
    SwrveConversationResource *_engine;
}

@property (strong, nonatomic) IBOutlet UIImageView *fullScreenBackgroundImageView;
@property (strong, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (strong, nonatomic) IBOutlet UIImageView *buttonsBackgroundImageView;
@property (strong, nonatomic) IBOutlet UITableView *contentTableView;
@property (unsafe_unretained, nonatomic) IBOutlet UIView *buttonsView;
@property (nonatomic, assign) id<SwrveConversationItemViewControllerDelegate> delegate;
@property (readonly, nonatomic) NSString *conversationTrackerId;
@property (nonatomic, strong) SwrveConversationResource *engine;

-(id)initWithConversation:(SwrveConversation*)conversation;

-(IBAction)cancelButtonTapped:(id)sender;
-(void)updateUI;

@end
