#import <UIKit/UIKit.h>

//! Project version number for SwrveSDK.
FOUNDATION_EXPORT double SwrveSDKVersionNumber;

//! Project version string for SwrveSDK.
FOUNDATION_EXPORT const unsigned char SwrveSDKVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <SwrveSDK/PublicHeader.h>

// Common - Permissions
#import <SwrveSDK/SwrvePermissionState.h>
#import <SwrveSDK/SwrvePermissionsDelegate.h>
#import <SwrveSDK/SwrveInAppCapabilitiesDelegate.h>

// Common - Push
#import <SwrveSDK/SwrvePush.h>
#import <SwrveSDK/SwrveSwizzleHelper.h>

// Common
#import <SwrveSDK/SwrveAssetsManager.h>
#import <SwrveSDK/SwrveCommon.h>
#import <SwrveSDK/SwrvePermissions.h>
#import <SwrveSDK/SwrveRESTClient.h>
#import <SwrveSDK/SwrveSignatureProtectedFile.h>
#import <SwrveSDK/SwrveLocalStorage.h>
#import <SwrveSDK/SwrveQA.h>
#import <SwrveSDK/SwrveQACampaignInfo.h>
#import <SwrveSDK/SwrveQAEventsQueueManager.h>
#import <SwrveSDK/SwrveQAImagePersonalizationInfo.h>
#import <SwrveSDK/SwrveCampaignInfluence.h>
#import <SwrveSDK/SwrveCampaignDelivery.h>
#import <SwrveSDK/SwrveUser.h>
#import <SwrveSDK/SwrveNotificationManager.h>
#import <SwrveSDK/SwrveNotificationOptions.h>
#import <SwrveSDK/SwrveNotificationConstants.h>
#import <SwrveSDK/SwrveSessionDelegate.h>
#import <SwrveSDK/SwrveUtils.h>
#import <SwrveSDK/SwrveEvents.h>
#import <SwrveSDK/TextTemplating.h>

// ConversationsSDK
#import <SwrveSDK/UINavigationController+KeyboardResponderFix.h>
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
#import <SwrveSDK/SwrveConversationsNavigationController.h>
#import <SwrveSDK/SwrveConversationStyler.h>
#import <SwrveSDK/SwrveConversationUIButton.h>
#import <SwrveSDK/SwrveInputItem.h>
#import <SwrveSDK/SwrveInputMultiValue.h>
#import <SwrveSDK/SwrveMessageEventHandler.h>
#import <SwrveSDK/SwrveSetup.h>
#import <SwrveSDK/SwrveUITableViewCell.h>

// Conversation
#import <SwrveSDK/SwrveConversation.h>
#import <SwrveSDK/SwrveConversationCampaign.h>

// Messaging
#import <SwrveSDK/SwrveButton.h>
#import <SwrveSDK/SwrveCampaign.h>
#import <SwrveSDK/SwrveCampaignStatus.h>
#import <SwrveSDK/SwrveImage.h>
#import <SwrveSDK/SwrveInAppCampaign.h>
#import <SwrveSDK/SwrveInterfaceOrientation.h>
#import <SwrveSDK/SwrveMessage.h>
#import <SwrveSDK/SwrveMessageDelegate.h>
#import <SwrveSDK/SwrveMessageFormat.h>
#import <SwrveSDK/SwrveMessageViewController.h>
#import <SwrveSDK/SwrveMessageController.h>
#import <SwrveSDK/SwrveTrigger.h>
#import <SwrveSDK/SwrveTriggerCondition.h>

#import <SwrveSDK/Swrve.h>
#import <SwrveSDK/SwrveConfig.h>
#import <SwrveSDK/SwrveInAppMessageConfig.h>
#import <SwrveSDK/SwrveDeviceProperties.h>
#import <SwrveSDK/SwrveEmpty.h>
#import <SwrveSDK/SwrveEventsManager.h>
#import <SwrveSDK/SwrveIAPRewards.h>
#import <SwrveSDK/SwrveMigrationsManager.h>
#import <SwrveSDK/SwrveProtocol.h>
#import <SwrveSDK/SwrveReceiptProvider.h>
#import <SwrveSDK/SwrveResourceManager.h>
#import <SwrveSDK/SwrveSDK.h>
#import <SwrveSDK/SwrveDeeplinkManager.h>
#import <SwrveSDK/SwrveProfileManager.h>
#import <SwrveSDK/SwrveEventQueueItem.h>
#import <SwrveSDK/SwrveDynamicUrlImage.h>
#import <SwrveSDK/SwrvePersonalizedTextImage.h>
#import <SwrveSDK/SwrveDeeplinkDelegate.h>
