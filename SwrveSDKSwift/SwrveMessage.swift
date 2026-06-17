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
        self.campaignID = self.campaign?.ID ?? 0
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
            let formatIsLandscape = format.orientation == .SWRVE_ORIENTATION_LANDSCAPE
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

    @objc public func supportsSwrveOrientation(_ swrveOrientation: SwrveInterfaceOrientation) -> Bool {
        for format in formats {
            if format.orientation == swrveOrientation {
                return true
            }
        }
        return false
    }

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
                            if let buttonImage = button.image {
                                hasButtonImage = assets.contains(buttonImage)
                            }
                            if let dynamicImageUrl = button.dynamicImageUrl {
                                hasButtonImage = canResolvePersonalizedImageAsset(
                                    assetUrl: dynamicImageUrl, withPersonalization: personalization, withAssets: assets)
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
                            if let dynamicImageUrl = image.dynamicImageUrl {
                                hasImage = canResolvePersonalizedImageAsset(
                                    assetUrl: dynamicImageUrl, withPersonalization: personalization, withAssets: assets)
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
        if !SwrveSDKUtils.isSystemFont(theme.fontFile ?? ""), !assets.contains(theme.fontFile ?? "") {
            SwrveLogger.logDebug("Button theme font asset not yet downloaded: \(String(describing: theme.fontFile))")
            return false
        }
        if let bgImage = theme.pressedState.bgImage, !assets.contains(bgImage) {
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
            let resolvedUrl: String
            if campaign?.freemarkerEnabled ?? false {
                resolvedUrl = try SwrveFreemarkerEvaluator.evaluate(
                    assetUrl, properties: personalization, useLocalTimezone: campaign?.useLocalTimezone ?? false)
            } else {
                resolvedUrl = try TextTemplating.templatedText(from: assetUrl, withProperties: personalization)
            }
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
        personalizationFailureReason(personalization) == nil
    }

    /// Returns the first personalization failure reason, or nil if all properties resolve successfully.
    func personalizationFailureReason(_ personalization: [String: Any]) -> String? {
        let isFreemarker = campaign?.freemarkerEnabled ?? false
        if let details = messageCenterDetails {
            for text in [details.subject, details.description, details.imageUrl, details.imageAccessibilityText].compactMap({ $0 }) {
                if let reason = textResolutionFailure(text, personalization: personalization, freemarkerEnabled: isFreemarker) {
                    return reason
                }
            }
        }
        for format in formats {
            guard let pages = format.pages as? [AnyHashable: SwrveMessagePage] else { continue }
            for (_, page) in pages {
                if let reason = personalizationFailureReasonForPage(page, personalization: personalization, freemarkerEnabled: isFreemarker) {
                    return reason
                }
            }
        }
        return validateVisibleIfExpressions(personalization)
    }

    private func personalizationFailureReasonForPage(_ page: SwrveMessagePage, personalization: [String: Any], freemarkerEnabled: Bool) -> String? {
        if let buttons = page.buttons as? [SwrveButton] {
            for button in buttons {
                if let buttonText = button.text,
                    let reason = textResolutionFailure(buttonText, personalization: personalization, freemarkerEnabled: freemarkerEnabled)
                {
                    return reason
                }
                if button.actionType == .clipboard || button.actionType == .custom,
                    let reason = textResolutionFailure(
                        button.actionString, personalization: personalization, freemarkerEnabled: freemarkerEnabled,
                        nilMessage: "Button action template could not be resolved: \(button.actionString)")
                {
                    return reason
                }
            }
        }
        if let images = page.images as? [SwrveImage] {
            for image in images {
                if let text = image.text ?? image.multilineText?["value"] as? String,
                    let reason = textResolutionFailure(text, personalization: personalization, freemarkerEnabled: freemarkerEnabled)
                {
                    return reason
                }
            }
        }
        return nil
    }

    func validateVisibleIfExpressions(_ personalization: [String: Any]) -> String? {
        for format in formats {
            guard let pages = format.pages as? [AnyHashable: SwrveMessagePage] else { continue }
            for (_, page) in pages {
                var visibleIfExpressions: [String] = []
                if let images = page.images as? [SwrveImage] {
                    visibleIfExpressions.append(contentsOf: images.map(\.visibleIf))
                }
                if let buttons = page.buttons as? [SwrveButton] {
                    visibleIfExpressions.append(contentsOf: buttons.map(\.visibleIf))
                }
                for visibleIf in visibleIfExpressions {
                    guard !visibleIf.isEmpty else { continue }
                    let template = "<#if \(visibleIf)>true<#else>false</#if>"
                    do {
                        // Validate syntax/resolvability only — result discarded; render-time evaluation in shouldRenderElement determines actual visibility.
                        _ = try SwrveFreemarkerEvaluator.evaluate(
                            template, properties: personalization, useLocalTimezone: campaign?.useLocalTimezone ?? false)
                    } catch {
                        return "visible_if condition could not be evaluated"
                    }
                }
            }
        }
        return nil
    }

    private func textResolutionFailure(_ text: String, personalization: [String: Any], freemarkerEnabled: Bool, nilMessage: String? = nil) -> String?
    {
        do {
            let result: String?
            if freemarkerEnabled {
                result = try SwrveFreemarkerEvaluator.evaluate(
                    text, properties: personalization, useLocalTimezone: campaign?.useLocalTimezone ?? false)
            } else {
                result = try TextTemplating.templatedText(from: text, withProperties: personalization)
            }
            if result == nil {
                return nilMessage ?? "Text template could not be resolved: \(text)"
            }
            return nil
        } catch {
            return (error as NSError).userInfo["Error reason"] as? String ?? error.localizedDescription
        }
    }

}
