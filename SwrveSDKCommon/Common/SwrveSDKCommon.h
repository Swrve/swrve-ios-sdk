#import <UIKit/UIKit.h>

//! Project version number for SwrveSDKCommon.
FOUNDATION_EXPORT double SwrveSDKCommonVersionNumber;

//! Project version string for SwrveSDKCommon.
FOUNDATION_EXPORT const unsigned char SwrveSDKCommonVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import "PublicHeader.h"

#if SWIFT_PACKAGE
    // Common - Permissions
    #import "SwrvePermissionState.h"
    #import "SwrvePermissionsDelegate.h"

    // Common - Push
    #import "SwrvePush.h"
    #import "SwrveSwizzleHelper.h"

    // Common
    #import "SwrveAssetsManager.h"
    #import "SwrveCommon.h"
    #import "SwrvePermissions.h"
    #import "SwrveRESTClient.h"
    #import "SwrveSignatureProtectedFile.h"
    #import "SwrveLocalStorage.h"
    #import "SwrveQA.h"
    #import "SwrveQACampaignInfo.h"
    #import "SwrveQAEventsQueueManager.h"
    #import "SwrveCampaignInfluence.h"
    #import "SwrveCampaignDelivery.h"
    #import "SwrveUser.h"
    #import "SwrveNotificationManager.h"
    #import "SwrveNotificationOptions.h"
    #import "SwrveNotificationConstants.h"
    #import "SwrveSessionDelegate.h"
    #import "SwrveUtils.h"
    #import "SwrveEvents.h"
#else
    // Common - Permissions
    #import <SwrveSDKCommon/SwrvePermissionState.h>
    #import <SwrveSDKCommon/SwrvePermissionsDelegate.h>

    // Common - Push
    #import <SwrveSDKCommon/SwrvePush.h>
    #import <SwrveSDKCommon/SwrveSwizzleHelper.h>

    // Common
    #import <SwrveSDKCommon/SwrveAssetsManager.h>
    #import <SwrveSDKCommon/SwrveCommon.h>
    #import <SwrveSDKCommon/SwrvePermissions.h>
    #import <SwrveSDKCommon/SwrveRESTClient.h>
    #import <SwrveSDKCommon/SwrveSignatureProtectedFile.h>
    #import <SwrveSDKCommon/SwrveLocalStorage.h>
    #import <SwrveSDKCommon/SwrveQA.h>
    #import <SwrveSDKCommon/SwrveQACampaignInfo.h>
    #import <SwrveSDKCommon/SwrveQAEventsQueueManager.h>
    #import <SwrveSDKCommon/SwrveCampaignInfluence.h>
    #import <SwrveSDKCommon/SwrveCampaignDelivery.h>
    #import <SwrveSDKCommon/SwrveUser.h>
    #import <SwrveSDKCommon/SwrveNotificationManager.h>
    #import <SwrveSDKCommon/SwrveNotificationOptions.h>
    #import <SwrveSDKCommon/SwrveNotificationConstants.h>
    #import <SwrveSDKCommon/SwrveSessionDelegate.h>
    #import <SwrveSDKCommon/SwrveUtils.h>
    #import <SwrveSDKCommon/SwrveEvents.h>
#endif
