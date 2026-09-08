import Foundation
import SwrveSDK

/// What one row and one detail screen show, copied out of the SDK's message object.
///
/// A value type on purpose: the SDK hands back fresh objects each time, and modelling the row this way lets SwiftUI see that a message became read.
struct InboxMessage: Identifiable, Hashable {

    let id: UInt64
    let subject: String?
    let body: String
    let thumbnailUrl: URL?
    let actionValue: String?
    let sentDate: Date
    let unread: Bool
    /// The payload as it arrived, for this sample's debug panel only. A real inbox has no use for it.
    let rawCustomerJson: String

    /// `customerJson` is your payload, not the SDK's — it is passed through untouched, so parsing it is entirely up to you.
    init(_ message: SwrvePushInboxMessage) {
        let json = message.customerJson as? [String: Any] ?? [:]

        id = message.messageId
        subject = json.nonEmptyString("subject")
        body = json.nonEmptyString("message") ?? ""
        thumbnailUrl = json.nonEmptyString("thumbnail").flatMap(URL.init(string:))
        actionValue = json.nonEmptyString("action_value")
        sentDate = Date(timeIntervalSince1970: TimeInterval(message.sentDate) / 1000)
        unread = message.state == .UNREAD
        rawCustomerJson = InboxMessage.prettyPrinted(json)
    }

    private static func prettyPrinted(_ json: [String: Any]) -> String {
        guard JSONSerialization.isValidJSONObject(json),
            let data = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
            let string = String(data: data, encoding: .utf8)
        else {
            return String(describing: json)
        }
        return string
    }
}

extension Dictionary where Key == String, Value == Any {
    fileprivate func nonEmptyString(_ key: String) -> String? {
        guard let value = self[key] as? String, !value.isEmpty else { return nil }
        return value
    }
}
