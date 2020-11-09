#import <UIKit/UIKit.h>

//! Project version number for SwrveConversationSDK.
FOUNDATION_EXPORT double SwrveConversationSDKVersionNumber;

//! Project version string for SwrveConversationSDK.
FOUNDATION_EXPORT const unsigned char SwrveConversationSDKVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import "PublicHeader.h"

#if SWIFT_PACKAGE
    // Conversations - Categories
    #import "UINavigationController+KeyboardResponderFix.h"

    // Conversations
    #import "SwrveBaseConversation.h"
    #import "SwrveContentHTML.h"
    #import "SwrveContentImage.h"
    #import "SwrveContentItem.h"
    #import "SwrveContentSpacer.h"
    #import "SwrveContentStarRating.h"
    #import "SwrveContentStarRatingView.h"
    #import "SwrveContentVideo.h"
    #import "SwrveConversationAtom.h"
    #import "SwrveConversationAtomFactory.h"
    #import "SwrveConversationButton.h"
    #import "SwrveConversationContainerViewController.h"
    #import "SwrveConversationEvents.h"
    #import "SwrveConversationItemViewController.h"
    #import "SwrveConversationPane.h"
    #import "SwrveConversationResource.h"
    #import "SwrveConversationResourceManagement.h"
    #import "SwrveConversationsNavigationController.h"
    #import "SwrveConversationStyler.h"
    #import "SwrveConversationUIButton.h"
    #import "SwrveInputItem.h"
    #import "SwrveInputMultiValue.h"
    #import "SwrveMessageEventHandler.h"
    #import "SwrveSetup.h"
    #import "SwrveUITableViewCell.h"
#else
    // Conversations - Categories
    #import <SwrveConversationSDK/UINavigationController+KeyboardResponderFix.h>

    // Conversations
    #import <SwrveConversationSDK/SwrveBaseConversation.h>
    #import <SwrveConversationSDK/SwrveContentHTML.h>
    #import <SwrveConversationSDK/SwrveContentImage.h>
    #import <SwrveConversationSDK/SwrveContentItem.h>
    #import <SwrveConversationSDK/SwrveContentSpacer.h>
    #import <SwrveConversationSDK/SwrveContentStarRating.h>
    #import <SwrveConversationSDK/SwrveContentStarRatingView.h>
    #import <SwrveConversationSDK/SwrveContentVideo.h>
    #import <SwrveConversationSDK/SwrveConversationAtom.h>
    #import <SwrveConversationSDK/SwrveConversationAtomFactory.h>
    #import <SwrveConversationSDK/SwrveConversationButton.h>
    #import <SwrveConversationSDK/SwrveConversationContainerViewController.h>
    #import <SwrveConversationSDK/SwrveConversationEvents.h>
    #import <SwrveConversationSDK/SwrveConversationItemViewController.h>
    #import <SwrveConversationSDK/SwrveConversationPane.h>
    #import <SwrveConversationSDK/SwrveConversationResource.h>
    #import <SwrveConversationSDK/SwrveConversationResourceManagement.h>
    #import <SwrveConversationSDK/SwrveConversationsNavigationController.h>
    #import <SwrveConversationSDK/SwrveConversationStyler.h>
    #import <SwrveConversationSDK/SwrveConversationUIButton.h>
    #import <SwrveConversationSDK/SwrveInputItem.h>
    #import <SwrveConversationSDK/SwrveInputMultiValue.h>
    #import <SwrveConversationSDK/SwrveMessageEventHandler.h>
    #import <SwrveConversationSDK/SwrveSetup.h>
    #import <SwrveConversationSDK/SwrveUITableViewCell.h>
#endif
