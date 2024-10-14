import Foundation
import UIKit

#if canImport(SwrveSDK)
    import SwrveSDK
#endif

#if canImport(SwrveSDKCommon)
    import SwrveSDKCommon
#endif

@objc public enum SwrveEmbeddedDataType: Int {
    case json
    case other
}

@objc public class SwrveEmbeddedMessage: SwrveBaseMessage {

    @objc public var data: String?
    @objc public var type: SwrveEmbeddedDataType = .other
    @objc public var buttons: [String] = []

    @objc public static func fromDictionary(_ json: [String: Any], andCampaign campaign: SwrveCampaign) -> SwrveEmbeddedMessage {
        let message = SwrveEmbeddedMessage()
        message.campaign = campaign

        guard let id = json["id"] as? NSNumber else {
            return message
        }

        message.messageID = id
        message.priority = json["priority"] as? NSNumber ?? NSNumber(value: 9999)
        message.buttons = json["buttons"] as? [String] ?? []

        let typeString = json["type"] as? String
        message.type = typeString == "json" ? .json : .other

        message.data = json["data"] as? String
        message.name = json["name"] as? String

        if let messageCenterDetailsJSON = json["message_center_details"] as? [String: Any] {
            message.messageCenterDetails = SwrveMessageCenterDetails(withJSON: messageCenterDetailsJSON)
        }

        if let control = json["control"] as? Bool {
            message.control = control
        }

        return message
    }

}
