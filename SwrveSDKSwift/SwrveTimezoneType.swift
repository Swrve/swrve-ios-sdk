/// Represents the timezone type.
///
/// - GLOBAL: Global timezone type.
/// - LOCAL: Local timezone type.
@objc public enum SwrveTimezoneType: Int, CustomStringConvertible {
    case GLOBAL
    case LOCAL

    /// This is necessary to display the enum that uses `@objc`.
    /// - Returns: A string representing the timezone type (`"GLOBAL"` or `"LOCAL").
    public var description: String {
        switch self {
        case .GLOBAL:
            return "global"
        case .LOCAL:
            return "local"
        }
    }

    /// Creates a `SwrveTimezoneType` from a JSON dictionary.
    /// - Parameter jsonDict: The dictionary containing the "timezone_type" key.
    /// - Returns: The corresponding `SwrveTimezoneType`, or `nil` if the string is invalid.
    public static func create(from jsonDict: [String: Any]) -> SwrveTimezoneType {
        guard let timezoneTypeString = jsonDict["timezone_type"] as? String else {
            return .GLOBAL
        }

        switch timezoneTypeString.lowercased() {
        case "global":
            return .GLOBAL
        case "local":
            return .LOCAL
        default:
            return .GLOBAL
        }
    }
}
