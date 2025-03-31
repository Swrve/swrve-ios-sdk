import Foundation
import UIKit

#if canImport(SwrveSDK)
import SwrveSDK
#endif

#if canImport(SwrveSDKCommon)
import SwrveSDKCommon
#endif

@objc public class SwrveMessage: SwrveBaseMessage {

    @objc public var formats: [SwrveMessageFormat] = []

    /// Create an in-app message from the JSON content.
    ///
    /// - Parameters:
    ///   - json: In-app message JSON content.
    ///   - campaign: Parent in-app campaign.
    ///   - controller: Message controller.
    /// - Returns: Parsed in-app message.
    @objc public init(dictionary json: [String: Any], campaign: SwrveInAppCampaign, controller: SwrveMessageController) {
        super.init()

        if json.isEmpty {
            return
        }

        if let messageCenterDetailsJson = json["message_center_details"] as? [String: Any] {
            self.messageCenterDetails = SwrveMessageCenterDetails(withJSON: messageCenterDetailsJson)
        }
        self.campaign = campaign
        self.messageID = json["id"] as? NSNumber
        self.name = json["name"] as? String
        self.priority = json["priority"] as? NSNumber ?? 9999

        if let messageTemplate = json["template"] as? [String: Any],
            let jsonFormats = messageTemplate["formats"] as? [[String: Any]]
        {

            let messageID = self.messageID?.intValue ?? 0
            self.formats = jsonFormats.map { jsonFormat in
                SwrveMessageFormat(
                    fromJson: jsonFormat,
                    campaignId: Int(self.campaign?.ID ?? 0),
                    messageId: messageID
                )
            }
        }
        self.control = json["control"] as? Bool ?? false
    }

    #if os(iOS)

    /// Obtain the best format for the given orientation.
    ///
    /// - Parameter orientation: Wanted orientation for the message.
    /// - Returns: In-app message format for the given orientation.
    @objc public func bestFormat(for orientation: UIInterfaceOrientation) -> SwrveMessageFormat? {
        for format in formats {
            let formatIsLandscape = format.orientation == SWRVE_ORIENTATION_LANDSCAPE
            if orientation.isLandscape {
                if formatIsLandscape {
                    return format
                }
            } else {
                if !formatIsLandscape {
                    return format
                }
            }
        }
        return nil
    }

    /// Check if the message has any format for the given device orientation.
    ///
    /// - Parameter orientation: Device orientation.
    /// - Returns: TRUE if the message has any format with the given orientation.
    @objc public func supportsOrientation(_ orientation: UIInterfaceOrientation) -> Bool {
        bestFormat(for: orientation) != nil
    }

    #endif

    /// Check if assets are downloaded.
    ///
    /// - Parameters:
    ///   - assets: The set of assets.
    ///   - personalization: The personalization dictionary.
    /// - Returns: TRUE if all assets have been downloaded.
    @objc public func assetsReady(_ assets: Set<String>, withPersonalization personalization: [String: Any]) -> Bool {

        for format in formats {
            let pages = format.pages as? [AnyHashable: SwrveMessagePage] ?? [:]
            for (_, page) in pages {

                if let buttons = page.buttons as? [SwrveButton] {
                    for button in buttons {
                        if let theme = button.theme {
                            if !buttonThemeAssetsReady(theme: theme, assets: assets) {
                                return false
                            }
                        } else {
                            var hasButtonImage = true
                            if let buttonImage = button.image, !assets.contains(buttonImage) {
                                hasButtonImage = false
                            }
                            if let dynamicImageUrl = button.dynamicImageUrl,
                                canResolvePersonalizedImageAsset(assetUrl: dynamicImageUrl, withPersonalization: personalization, withAssets: assets)
                            {
                                hasButtonImage = true
                            }
                            if !hasButtonImage {
                                SwrveLogger.logDebug("Button Asset not yet downloaded: \(button.image ?? "") / \(button.dynamicImageUrl ?? "")")
                                return false
                            }
                        }
                    }
                }

                if let images = page.images as? [SwrveImage] {
                    for image in images {
                        if let multilineText = image.multilineText,
                            let fontFile = multilineText["font_file"] as? String,
                            !SwrveSDKUtils.isSystemFont(fontFile)
                        {
                            if !assets.contains(fontFile) {
                                SwrveLogger.logDebug("Font Asset not yet downloaded: \(fontFile)")
                                return false
                            }
                        } else {

                            var hasImage = true
                            if let file = image.file {
                                hasImage = assets.contains(file)
                            }
                            if let dynamicImageUrl = image.dynamicImageUrl,
                                canResolvePersonalizedImageAsset(assetUrl: dynamicImageUrl, withPersonalization: personalization, withAssets: assets)
                            {
                                hasImage = true
                            }
                            if !hasImage {
                                SwrveLogger.logDebug("Image Asset not yet downloaded: \(image.file ?? "") / \(image.dynamicImageUrl ?? "")")
                                return false
                            }
                        }
                    }
                }
            }
        }
        return true
    }

    private func buttonThemeAssetsReady(theme: SwrveButtonTheme, assets: Set<String>) -> Bool {

        if let bgImage = theme.bgImage, !assets.contains(bgImage) {
            SwrveLogger.logDebug("Button theme bgImage asset not yet downloaded: \(bgImage)")
            return false
        }
        if !SwrveSDKUtils.isSystemFont(theme.fontFile), !assets.contains(theme.fontFile) {
            SwrveLogger.logDebug("Button theme font asset not yet downloaded: \(theme.fontFile)")
            return false
        }
        if let bgImage = theme.pressedState?.bgImage, !assets.contains(bgImage) {
            SwrveLogger.logDebug("Button pressed theme bgImage asset not yet downloaded: \(bgImage)")
            return false
        }
        if let bgImage = theme.focusedState?.bgImage, !assets.contains(bgImage) {
            SwrveLogger.logDebug("Button focused theme bgImage asset not yet downloaded: \(bgImage)")
            return false
        }
        return true
    }

    private func canResolvePersonalizedImageAsset(
        assetUrl: String, withPersonalization personalization: [String: Any], withAssets assets: Set<String>
    ) -> Bool {
        do {
            let resolvedUrl = try TextTemplating.templatedText(from: assetUrl, withProperties: personalization)
            let data = resolvedUrl.data(using: .utf8)!
            if let assetSha1 = SwrveUtils.sha1(data) {
                return assets.contains(assetSha1)
            } else {
                return false
            }
        } catch {
            SwrveLogger.logDebug("Could not resolve personalization: \(assetUrl)")
            return false
        }

    }

    /// Check if all personalized text in this message has been accounted for and can be set
    ///
    /// - Parameter personalization: The personalization dictionary.
    /// - Returns: TRUE if all personalized text parts have either fallbacks or values available to them.
    @objc public func canResolvePersonalization(_ personalization: [String: Any]) -> Bool {

        if let details = messageCenterDetails {
            let props = [details.subject, details.description, details.imageUrl, details.imageAccessibilityText].compactMap({ $0 })
            for textToPersonalize in props {
                let personalizedText = try? TextTemplating.templatedText(from: textToPersonalize, withProperties: personalization)
                if personalizedText == nil {
                    SwrveLogger.logWarning("Message Center Details has no personalization for text: \(textToPersonalize)")
                    return false
                }
            }
        }
        for format in formats {
            if let pages = format.pages as? [AnyHashable: SwrveMessagePage] {
                for (_, page) in pages {
                    if let buttons = page.buttons as? [SwrveButton] {
                        for button in buttons {
                            if let buttonText = button.text {
                                let personalizedText = try? TextTemplating.templatedText(from: buttonText, withProperties: personalization)
                                if personalizedText == nil {
                                    SwrveLogger.logWarning("Button Asset has no personalization for text: \(buttonText)")
                                    return false
                                }
                            }

                            if button.actionType == .clipboard
                                || button.actionType == .custom
                            {
                                let personalizedText = try? TextTemplating.templatedText(from: button.actionString, withProperties: personalization)
                                if personalizedText == nil {
                                    SwrveLogger.logWarning("Button Asset has no personalization for action: \(button.actionString ?? "")")
                                    return false
                                }
                            }
                        }
                    }

                    if let images = page.images as? [SwrveImage] {
                        for image in images {
                            if let currentImageText = image.text ?? image.multilineText?["value"] as? String {
                                let personalizedText = try? TextTemplating.templatedText(from: currentImageText, withProperties: personalization)
                                if personalizedText == nil {
                                    SwrveLogger.logWarning("Button Asset has no personalization for text: \(currentImageText)")
                                    return false
                                }
                            }
                        }
                    }
                }
            }
        }
        return true

    }

}
