import Foundation

@objc public class SwrveEmbeddedMessageConfig: NSObject {

    /// A block that will be called when an event triggers a control embedded message.
    /// - Parameters:
    ///   - message: The `SwrveEmbeddedMessage` object.
    ///   - personalizationProperties: Custom properties which are used for personalization.
    ///   - isControl: Flag to determine if control or treatment message. If control, this message should not be shown to users.
    public typealias SwrveEmbeddedCallback = (_ message: SwrveEmbeddedMessage, _ personalizationProperties: [String: Any], _ isControl: Bool) -> Void

    /// Implement this delegate to handle embedded messages. If it's a control message, it should not be shown to the user.
    @objc public var embeddedCallback: SwrveEmbeddedCallback?

    // init required for @objc annotation
    @objc public override init() {
    }
}
