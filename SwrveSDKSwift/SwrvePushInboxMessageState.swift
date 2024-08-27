/// Represents the state of a message in the Swrve push inbox.
///
/// - UNREAD: The message has not been read.
/// - READ: The message has been read.
/// - DELETED: The message has been deleted.
@objc public enum SwrvePushInboxMessageState: Int, CustomStringConvertible {
    /// The message has not been read.
    case UNREAD

    /// The message has been read.
    case READ

    /// The message has been deleted
    case DELETED

    /**
     This is necessary to display the enum that uses `@objc`.
     - Returns: A string representing the message state (`"UNREAD"` or `"READ" or "DELETED"`).
     */
    public var description: String {
        switch self {
        case .UNREAD:
            return "UNREAD"
        case .READ:
            return "READ"
        case .DELETED:
            return "DELETED"
        }
    }
}
