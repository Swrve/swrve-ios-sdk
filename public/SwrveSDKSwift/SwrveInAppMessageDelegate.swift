import Foundation

@objc public enum SwrveMessageAction: Int {
    case dismiss = 0
    case custom = 1
    case clipboard = 2
    case impression = 3
}

/// Use this protocol to get callbacks for supported actions within Swrve In-App Messages
@objc public protocol SwrveInAppMessageDelegate: NSObjectProtocol {

    /// Use this protocol to get callbacks for supported actions within Swrve In-App Messages
    /// It is important to handle each message action as this delegate can be called multiple times, e.g., for an Impression and Button actions such as Custom, Dismiss, or Clipboard.
    /// ```swift
    /// func onAction(_ messageAction: SwrveMessageAction, messageDetails: SwrveMessageDetails, selectedButton: SwrveMessageButtonDetails?) {
    ///     switch messageAction {
    ///         case .impression:
    ///             break
    ///         case .custom:
    ///             // If there is a deeplink, we will call open url internally unless SwrveDeeplinkDelegate is implemented, if it is, the deeplink url will be passed to the SwrveDeeplinkDelegate.
    ///             break
    ///         case .dismiss:
    ///             break
    ///         case .clipboard:
    ///             break
    ///         default:
    ///             break
    ///     }
    /// }
    /// ```
    /// - Parameters:
    ///   - messageAction The message action, see SwrveMessageAction for supported types.
    ///   - messageDetails The message details, see SwrveMessageDetails for meta data.
    ///   - selectedButton The selected button, see SwrveMessageButtonDetails for meta data; this will be nil if messageAction is an Impression.
    @objc optional func onAction(_ messageAction: SwrveMessageAction, messageDetails: SwrveMessageDetails, selectedButton: SwrveMessageButtonDetails?)
}
