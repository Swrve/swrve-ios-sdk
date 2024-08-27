@objc public enum SwrvePushInboxResultCode: Int {
    case SUCCESS
    case ERROR_UNKNOWN
    case ERROR

    public var description: String {
        switch self {
        case .SUCCESS:
            return "SUCCESS"
        case .ERROR_UNKNOWN:
            return "ERROR_UNKNOWN"
        case .ERROR:
            return "ERROR"
        }
    }
}
