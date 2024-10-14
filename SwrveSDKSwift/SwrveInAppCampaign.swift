import Foundation
import UIKit

#if canImport(SwrveSDK)
    import SwrveSDK
#endif

#if canImport(SwrveSDKCommon)
    import SwrveSDKCommon
#endif

@objc public class SwrveInAppCampaign: SwrveCampaign {

    /// Message attached to this campaign.
    @objc public var message: SwrveMessage?

    @objc public init(
        atTime time: Date, fromDictionary json: [String: Any], withAssetsQueue assetsQueue: NSMutableSet,
        forController controller: SwrveMessageController, withPersonalization personalization: [String: Any]
    ) {
        super.init(at: time, from: json, campaignType: SWRVE_CAMPAIGN_IAM)
        if let messageDict = json["message"] as? [String: Any] {
            self.message = SwrveMessage(dictionary: messageDict, campaign: self, controller: controller)
            self.addAssetsToQueue(assetsQueue, withPersonalization: personalization)
            self.name = self.message?.name ?? ""
        }
    }

    func addAssetToQueue(assetsQueue: NSMutableSet, withUrl url: String?, withPersonalization personalization: [String: Any]) {
        guard let url = url else { return }
        do {

            let resolvedUrl = try TextTemplating.templatedText(from: url, withProperties: personalization)
            let data = resolvedUrl.data(using: .utf8, allowLossyConversion: true)
            let sha1Url = SwrveUtils.sha1(data)
            if let assetQueueItem = SwrveAssetsManager.assetQItem(with: sha1Url, andDigest: resolvedUrl, andIsExternal: true, andIsImage: true) {
                assetsQueue.add(assetQueueItem)
            }
        } catch {
            SwrveLogger.logDebug("Could not resolve personalization: \(url)")
        }
    }

    @objc public func addAssetsToQueue(_ assetsQueue: NSMutableSet, withPersonalization personalization: [String: Any]) {
        if let imageURL = message?.messageCenterDetails?.imageUrl {
            addAssetToQueue(assetsQueue: assetsQueue, withUrl: imageURL, withPersonalization: personalization)
        }

        if let imageSha = message?.messageCenterDetails?.imageSha {
            if let assetQueueItem = SwrveAssetsManager.assetQItem(with: imageSha, andDigest: imageSha, andIsExternal: false, andIsImage: true) {
                assetsQueue.add(assetQueueItem)
            }
        }

        message?.formats.forEach { format in
            format.pages.forEach { (_, page) in

                if let page = page as? SwrveMessagePage {
                    page.buttons.forEach { button in

                        if let button = button as? SwrveButton {
                            addAssetToQueue(assetsQueue: assetsQueue, withUrl: button.dynamicImageUrl, withPersonalization: personalization)

                            if let image = button.image,
                                let assetQueueItem = SwrveAssetsManager.assetQItem(
                                    with: image, andDigest: image, andIsExternal: false, andIsImage: true)
                            {
                                assetsQueue.add(assetQueueItem)
                            }

                            if let theme = button.theme {
                                addButtonThemeAssets(theme: theme, assetsQueue: assetsQueue)
                            }
                        }
                    }

                    page.images.forEach { image in

                        if let image = image as? SwrveImage {
                            addAssetToQueue(assetsQueue: assetsQueue, withUrl: image.dynamicImageUrl, withPersonalization: personalization)

                            if let file = image.file,
                                let assetQueueItem = SwrveAssetsManager.assetQItem(
                                    with: file, andDigest: file, andIsExternal: false, andIsImage: true)
                            {
                                assetsQueue.add(assetQueueItem)
                            }

                            if let multilineText = image.multilineText as? [String: Any] {
                                addFontToQueue(assetQueue: assetsQueue, withAsset: multilineText)
                            }
                        }
                    }
                }
            }
        }
    }

    func addButtonThemeAssets(theme: SwrveButtonTheme, assetsQueue: NSMutableSet) {
        if let bgImage = theme.bgImage,
            let assetQueueItem = SwrveAssetsManager.assetQItem(with: bgImage, andDigest: bgImage, andIsExternal: false, andIsImage: true)
        {
            assetsQueue.add(assetQueueItem)
        }

        let fontFile = theme.fontFile

        if !SwrveSDKUtils.isSystemFont(fontFile),
            let assetQueueItem = SwrveAssetsManager.assetQItem(with: fontFile, andDigest: theme.fontDigest, andIsExternal: false, andIsImage: false)
        {
            assetsQueue.add(assetQueueItem)
        }

        if let pressedState = theme.pressedState,
            let bgImage = pressedState.bgImage,
            let assetQueueItem = SwrveAssetsManager.assetQItem(with: bgImage, andDigest: bgImage, andIsExternal: false, andIsImage: true)
        {
            assetsQueue.add(assetQueueItem)
        }

        if let focusedState = theme.focusedState,
            let bgImage = focusedState.bgImage,
            let assetQueueItem = SwrveAssetsManager.assetQItem(with: bgImage, andDigest: bgImage, andIsExternal: false, andIsImage: true)
        {
            assetsQueue.add(assetQueueItem)
        }
    }

    func addFontToQueue(assetQueue: NSMutableSet, withAsset style: [String: Any]) {
        if let name = style["font_file"] as? String,
            let digest = style["font_digest"] as? String,
            let assetQueueItem = SwrveAssetsManager.assetQItem(with: name, andDigest: digest, andIsExternal: false, andIsImage: false)
        {
            assetQueue.add(assetQueueItem)
        }
    }

    func messageWasShownToUser(_ messageShown: SwrveMessage) {
        super.wasShownToUser(at: Date())
    }

    @objc public func messageDismissed(_ timeDismissed: Date) {
        super.setMessageMinDelayThrottle(at: timeDismissed)
    }

    /**
     Quick check to see if this campaign might have messages matching this event trigger.
     This is used to decide if the campaign is a valid candidate for automatically showing at session start.

     - Parameter event: Trigger event.
     - Returns: `true` if the campaign contains a message for the given trigger.
     */
    func hasMessage(forEvent event: String) -> Bool {
        hasMessage(forEvent: event, withPayload: nil)
    }

    @objc public func hasMessage(forEvent event: String, withPayload payload: [AnyHashable: Any]?) -> Bool {
        super.canTrigger(withEvent: event, andPayload: payload)
    }

    func message(
        forEvent event: String, withAssets assets: Set<AnyHashable>, withPersonalization personalization: [String: Any], atTime time: Date
    ) -> SwrveMessage? {
        message(
            forEvent: event, withPayload: nil, withAssets: assets, withPersonalization: personalization, atTime: time,
            withReasons: NSMutableDictionary())
    }

    @objc public func message(
        forEvent event: String, withPayload payload: [AnyHashable: Any]?, withAssets assets: Set<AnyHashable>,
        withPersonalization personalization: [String: Any], atTime time: Date, withReasons campaignReasons: NSMutableDictionary
    ) -> SwrveMessage? {

        guard hasMessage(forEvent: event, withPayload: payload) else {
            SwrveLogger.logDebug("There is no trigger in \(self.ID) that matches \(event)")
            logAndAdd(
                reason:
                    "There is no trigger in \(self.ID) that matches \(event) with conditions \(String(describing: payload))",
                withReasons: campaignReasons
            )
            return nil
        }

        guard let message = self.message else {
            logAndAdd(reason: "No messages in campaign \(self.ID)", withReasons: campaignReasons)
            return nil
        }
        guard checkCampaignRules(forEvent: event, atTime: time, withReasons: campaignReasons) else {
            return nil
        }

        let assetsAsSet = (assets as? Set<String>) ?? Set<String>()
        if message.assetsReady(assetsAsSet, withPersonalization: personalization) {
            SwrveLogger.logDebug("\(event) matches a trigger in \(self.ID)")
            return message
        }

        logAndAdd(reason: "Campaign \(self.ID) hasn't finished downloading", withReasons: campaignReasons)
        return nil
    }

    #if os(iOS)
        @objc public override func supportsOrientation(_ orientation: UIInterfaceOrientation) -> Bool {
            if orientation == .unknown {
                return true
            }

            if message!.supportsOrientation(orientation) {
                return true
            }

            return message?.supportsOrientation(orientation) ?? false
        }
    #endif

    @objc override public func assetsReady(_ assets: Set<String>, withPersonalization personalization: [String: Any]) -> Bool {
        guard let message = message else {
            return true
        }
        if !message.assetsReady(assets, withPersonalization: personalization) {
            return false
        }
        return true
    }
}
