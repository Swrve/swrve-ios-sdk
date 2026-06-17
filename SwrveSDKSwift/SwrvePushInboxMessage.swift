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

        messageId = (objectData.value(forKey: "message_id") as? UInt64)!
        variantId = (objectData.value(forKey: "variant_id") as? UInt64)!

        let state = (objectData.value(forKey: "state") as? String)?.uppercased()
        self.state =
            switch state {
            case "U": SwrvePushInboxMessageState.UNREAD
            case "R": SwrvePushInboxMessageState.READ
            default: throw SwrveError.InvalidValue("SwrvePushInboxMessageState \(state.nilSafe)")
            }

        customerJson = objectData.value(forKey: "customer_json") as? NSDictionary ?? nil
        sentDate = (objectData.value(forKey: "sent_date") as? UInt64)!
        endDate = (objectData.value(forKey: "end_date") as? UInt64)!
        trackingData = objectData.value(forKey: "mg_tracking_data") as? String ?? ""
    }

}
