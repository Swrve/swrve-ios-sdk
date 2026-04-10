import UIKit

#if canImport(SwrveSDK)
import SwrveSDK
#endif

@objc public class SwrveButton: NSObject {
    @objc public var name: String?
    @objc public var buttonId: NSNumber?
    @objc public var image: String?
    @objc public var dynamicImageUrl: String?
    @objc public var text: String?
    @objc public var actionString: String = ""
    @objc public var center: CGPoint = .zero
    @objc public var size: CGSize = .zero
    @objc public var campaignId: Int64 = 0
    @objc public var messageId: Int64 = 0
    @objc public var appID: Int64 = 0
    @objc public var actionType: SwrveActionType = .dismiss
    @objc public var accessibilityText: String?
    @objc public var events: [Any]?
    @objc public var userUpdates: [[String: Any]]?
    @objc public var theme: SwrveButtonTheme?
    @objc public var iamZIndex: Int64 = 0

    // MARK: - Initializer

    @objc(initWithDictionary:campaignId:messageId:)
    public init(buttonData: [String: Any], campaignId swrveCampaignId: Int64, messageId swrveMessageId: Int64) {
        self.campaignId = swrveCampaignId
        self.messageId = swrveMessageId
        super.init()
        parseBasicFields(from: buttonData)
        parseDimensions(from: buttonData)
        parseImages(from: buttonData)
        parseText(from: buttonData)
        parseAction(from: buttonData)
        parseOptionalFields(from: buttonData)
    }

    // MARK: - Parsing helpers

    private func parseBasicFields(from data: [String: Any]) {
        name = data["name"] as? String
        buttonId = data["button_id"] as? NSNumber
    }

    private func parseDimensions(from data: [String: Any]) {
        if let xDict = data["x"] as? [String: Any],
            let yDict = data["y"] as? [String: Any],
            let xVal = xDict["value"] as? NSNumber,
            let yVal = yDict["value"] as? NSNumber
        {
            center = CGPoint(x: CGFloat(truncating: xVal), y: CGFloat(truncating: yVal))
        }

        if let wDict = data["w"] as? [String: Any],
            let hDict = data["h"] as? [String: Any],
            let wVal = wDict["value"] as? NSNumber,
            let hVal = hDict["value"] as? NSNumber
        {
            size = CGSize(width: CGFloat(truncating: wVal), height: CGFloat(truncating: hVal))
        }
    }

    private func parseImages(from data: [String: Any]) {
        if let imageUp = data["image_up"] as? [String: Any],
            let imageValue = imageUp["value"] as? String
        {
            image = imageValue
        } else {
            image = "buttonup.png"
        }

        dynamicImageUrl = data["dynamic_image_url"] as? String
    }

    private func parseText(from data: [String: Any]) {
        if let textDict = data["text"] as? [String: Any],
            let textValue = textDict["value"] as? String
        {
            text = textValue
        }
    }

    private func parseAction(from data: [String: Any]) {
        actionType = .dismiss
        appID = 0
        actionString = ""

        guard
            let typeDict = data["type"] as? [String: Any],
            let buttonType = typeDict["value"] as? String
        else { return }

        switch buttonType {
        case "INSTALL":
            actionType = .install
            appID = parseAppId(from: data)
        case "CUSTOM":
            actionType = .custom
            actionString = parseActionString(from: data)
        case "COPY_TO_CLIPBOARD":
            actionType = .clipboard
            actionString = parseActionString(from: data)
        case "REQUEST_CAPABILITY":
            actionType = .capability
            actionString = parseActionString(from: data)
        case "PAGE_LINK":
            actionType = .pageLink
            appID = parseAppId(from: data)
            actionString = parseActionString(from: data)
        case "OPEN_APP_SETTINGS":
            actionType = .openSettings
            actionString = parseActionString(from: data)
        case "OPEN_NOTIFICATION_SETTINGS":
            actionType = .openNotificationSettings
            actionString = parseActionString(from: data)
        case "START_GEO":
            actionType = .startGeo
            actionString = parseActionString(from: data)
        default:
            actionType = .dismiss
            actionString = ""
        }
    }

    private func parseOptionalFields(from data: [String: Any]) {
        accessibilityText = data["accessibility_text"] as? String
        events = data["events"] as? [Any]
        userUpdates = data["user_updates"] as? [[String: Any]]
        if let themeDict = data["theme"] as? [String: Any] {
            theme = SwrveButtonTheme(dictionary: themeDict)
        }
        if let zIndex = data["iam_z_index"] as? Int64 {
            iamZIndex = zIndex
        }
    }

    private func parseAppId(from data: [String: Any]) -> Int64 {
        guard let gameIdDict = data["game_id"] as? [String: Any] else { return 0 }
        if let numberValue = gameIdDict["value"] as? NSNumber {
            return numberValue.int64Value
        } else if let stringValue = gameIdDict["value"] as? String, let intValue = Int64(stringValue) {
            return intValue
        }
        return 0
    }

    private func parseActionString(from data: [String: Any]) -> String {
        guard
            let actionDict = data["action"] as? [String: Any],
            let value = actionDict["value"] as? String
        else { return "" }
        return value
    }
}
