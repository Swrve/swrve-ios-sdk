import Foundation

enum SwrveError: Error {
    case InvalidValue(_ message: String)
}

extension Optional where Wrapped == String {
    var nilSafe: String {
        self ?? "<nil>"
    }
}

/// Represents a message in the Swrve push inbox.
@objc public class SwrvePushInboxMessage: NSObject {

    /// The push campaign message id.
    @objc public private(set) var messageId: UInt64 = 0

    /// The push campaign variant id.
    @objc public private(set) var variantId: UInt64 = 0

    /// The state of the message (READ or UNREAD).
    @objc public internal(set) var state: SwrvePushInboxMessageState = SwrvePushInboxMessageState.UNREAD

    /// The JSON object containing customer-specific data.
    @objc public private(set) var customerJson: NSDictionary? = nil

    /// The date the push notification was sent.
    @objc public private(set) var sentDate: UInt64 = 0

    /// The expiry date of the push message. After this date, the message will no longer be returned from APIs.
    @objc public private(set) var endDate: UInt64 = 0

    /// Optional tracking data from MG, forwarded in inbox events. Empty string if not present.
    @objc public private(set) var trackingData: String = ""

    @objc init(_ objectData: NSDictionary) throws {

        messageId = try SwrvePushInboxMessage.requiredUInt64(objectData, "message_id")
        variantId = try SwrvePushInboxMessage.requiredUInt64(objectData, "variant_id")

        let state = (objectData.value(forKey: "state") as? String)?.uppercased()
        self.state =
            switch state {
            case "U": SwrvePushInboxMessageState.UNREAD
            case "R": SwrvePushInboxMessageState.READ
            default: throw SwrveError.InvalidValue("SwrvePushInboxMessageState \(state.nilSafe)")
            }

        customerJson = objectData.value(forKey: "customer_json") as? NSDictionary ?? nil
        sentDate = try SwrvePushInboxMessage.requiredUInt64(objectData, "sent_date")
        endDate = try SwrvePushInboxMessage.requiredUInt64(objectData, "end_date")
        trackingData = objectData.value(forKey: "mg_tracking_data") as? String ?? ""
    }

    // Accepts a whole non-negative number only. Anything else (missing, null, string, negative, fractional) throws so the caller skips this message instead of crashing.
    private static func requiredUInt64(_ objectData: NSDictionary, _ key: String) throws -> UInt64 {
        let value = objectData.value(forKey: key)
        guard let number = value as? UInt64 else {
            let received = value.map { "\($0)" } ?? "<nil>"
            throw SwrveError.InvalidValue("\(key) \(received)")
        }
        return number
    }

}
