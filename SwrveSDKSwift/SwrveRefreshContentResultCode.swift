@objc public enum SwrveRefreshContentResultCode: Int {
    /// Successful operation.
    case SUCCESS
    /// Operation failed due to an unknown error.
    case ERROR_UNKNOWN
    /// Operation failed due to a general error.
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
