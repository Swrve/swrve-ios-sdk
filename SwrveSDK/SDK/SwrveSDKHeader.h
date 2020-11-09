#import <UIKit/UIKit.h>

//! Project version number for SwrveSDK.
FOUNDATION_EXPORT double SwrveSDKVersionNumber;

//! Project version string for SwrveSDK.
FOUNDATION_EXPORT const unsigned char SwrveSDKVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import "PublicHeader.h"

#if SWIFT_PACKAGE
    // Conversation
    #import "SwrveConversation.h"
    #import "SwrveConversationCampaign.h"

    // Messaging
    #import "SwrveButton.h"
    #import "SwrveCampaign+Private.h"
    #import "SwrveCampaign.h"
    #import "SwrveCampaignStatus.h"
    #import "SwrveImage.h"
    #import "SwrveInAppCampaign.h"
    #import "SwrveInterfaceOrientation.h"
    #import "SwrveMessage.h"
    #import "SwrveMessageController+Private.h"
    #import "SwrveMessageController.h"
    #import "SwrveMessageDelegate.h"
    #import "SwrveMessageFormat.h"
    #import "SwrveMessageViewController.h"
    #import "SwrveTrigger.h"
    #import "SwrveTriggerCondition.h"

    #import "Swrve.h"
    #import "Swrve+Private.h"
    #import "SwrveConfig.h"
    #import "SwrveDeviceProperties.h"
    #import "SwrveEmpty.h"
    #import "SwrveEventsManager.h"
    #import "SwrveIAPRewards.h"
    #import "SwrveMigrationsManager.h"
    #import "SwrveProtocol.h"
    #import "SwrveReceiptProvider.h"
    #import "SwrveResourceManager.h"
    #import "SwrveSDK.h"
    #import "SwrveDeeplinkManager.h"
    #import "SwrveProfileManager.h"
    #import "SwrveEventQueueItem.h"
#else
    // Conversation
    #import <SwrveSDK/SwrveConversation.h>
    #import <SwrveSDK/SwrveConversationCampaign.h>

    // Messaging
    #import <SwrveSDK/SwrveButton.h>
    #import <SwrveSDK/SwrveCampaign+Private.h>
    #import <SwrveSDK/SwrveCampaign.h>
    #import <SwrveSDK/SwrveCampaignStatus.h>
    #import <SwrveSDK/SwrveImage.h>
    #import <SwrveSDK/SwrveInAppCampaign.h>
    #import <SwrveSDK/SwrveInterfaceOrientation.h>
    #import <SwrveSDK/SwrveMessage.h>
    #import <SwrveSDK/SwrveMessageController+Private.h>
    #import <SwrveSDK/SwrveMessageController.h>
    #import <SwrveSDK/SwrveMessageDelegate.h>
    #import <SwrveSDK/SwrveMessageFormat.h>
    #import <SwrveSDK/SwrveMessageViewController.h>
    #import <SwrveSDK/SwrveTrigger.h>
    #import <SwrveSDK/SwrveTriggerCondition.h>

    #import <SwrveSDK/Swrve.h>
    #import <SwrveSDK/Swrve+Private.h>
    #import <SwrveSDK/SwrveConfig.h>
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
#endif
