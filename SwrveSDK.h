//
//  SwrveSDK.h
//  SwrveSDK
//
//  Created by Milen Halachev on 1/3/17.
//  Copyright © 2017 Swrve. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for SwrveSDK.
FOUNDATION_EXPORT double SwrveSDKVersionNumber;

//! Project version string for SwrveSDK.
FOUNDATION_EXPORT const unsigned char SwrveSDKVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <SwrveSDK/PublicHeader.h>

//SwrveSDK
#import <SwrveSDK/Swrve.h>
#import <SwrveSDK/SwrveBaseCampaign.h>
#import <SwrveSDK/SwrveButton.h>
#import <SwrveSDK/SwrveCampaign.h>
#import <SwrveSDK/SwrveCampaignStatus.h>
#import <SwrveSDK/SwrveConversation.h>
#import <SwrveSDK/SwrveConversationCampaign.h>
#import <SwrveSDK/SwrveFileManagement.h>
#import <SwrveSDK/SwrveImage.h>
#import <SwrveSDK/SwrveInterfaceOrientation.h>
#import <SwrveSDK/SwrveInternalAccess.h>
#import <SwrveSDK/SwrveMessage.h>
#import <SwrveSDK/SwrveMessageController.h>
#import <SwrveSDK/SwrveMessageFormat.h>
#import <SwrveSDK/SwrveMessageViewController.h>
#import <SwrveSDK/SwrveMigrationsManager.h>
#import <SwrveSDK/SwrvePrivateBaseCampaign.h>
#import <SwrveSDK/SwrveReceiptProvider.h>
#import <SwrveSDK/SwrveResourceManager.h>
#import <SwrveSDK/SwrveSwizzleHelper.h>
#import <SwrveSDK/SwrveTalkQA.h>
#import <SwrveSDK/SwrveTrigger.h>
#import <SwrveSDK/SwrveTriggerCondition.h>

//SwrveSDKCommon
#import <SwrveSDK/ISHPermissionCategory.h>
#import <SwrveSDK/ISHPermissionRequest+All.h>
#import <SwrveSDK/ISHPermissionRequest+Private.h>
#import <SwrveSDK/ISHPermissionRequest.h>
#import <SwrveSDK/ISHPermissionRequestAddressBook.h>
#import <SwrveSDK/ISHPermissionRequestLocation.h>
#import <SwrveSDK/ISHPermissionRequestNotificationsRemote.h>
#import <SwrveSDK/ISHPermissionRequestPhotoCamera.h>
#import <SwrveSDK/ISHPermissionRequestPhotoLibrary.h>
#import <SwrveSDK/SwrveCommon.h>
#import <SwrveSDK/SwrveCommonConnectionDelegate.h>
#import <SwrveSDK/SwrvePermissions.h>
#import <SwrveSDK/SwrveSignatureProtectedFile.h>

//SwrveConversationSDK
#import <SwrveSDK/SwrveBaseConversation.h>
#import <SwrveSDK/SwrveContentHTML.h>
#import <SwrveSDK/SwrveContentImage.h>
#import <SwrveSDK/SwrveContentItem.h>
#import <SwrveSDK/SwrveContentSpacer.h>
#import <SwrveSDK/SwrveContentStarRating.h>
#import <SwrveSDK/SwrveContentStarRatingView.h>
#import <SwrveSDK/SwrveContentVideo.h>
#import <SwrveSDK/SwrveConversationAtom.h>
#import <SwrveSDK/SwrveConversationAtomFactory.h>
#import <SwrveSDK/SwrveConversationButton.h>
#import <SwrveSDK/SwrveConversationContainerViewController.h>
#import <SwrveSDK/SwrveConversationEvents.h>
#import <SwrveSDK/SwrveConversationItemViewController.h>
#import <SwrveSDK/SwrveConversationPane.h>
#import <SwrveSDK/SwrveConversationResource.h>
#import <SwrveSDK/SwrveConversationResourceManagement.h>
#import <SwrveSDK/SwrveConversationStyler.h>
#import <SwrveSDK/SwrveConversationUIButton.h>
#import <SwrveSDK/SwrveConversationsNavigationController.h>
#import <SwrveSDK/SwrveInputItem.h>
#import <SwrveSDK/SwrveInputMultiValue.h>
#import <SwrveSDK/SwrveMessageEventHandler.h>
#import <SwrveSDK/SwrveSetup.h>
#import <SwrveSDK/UINavigationController+KeyboardResponderFix.h>
#import <SwrveSDK/UIWebView+YouTubeVimeo.h>
