import Foundation

class SwrveUtilsSwift {

    static func parseIso8601Date(_ isoDate: String, timezoneType: SwrveTimezoneType, timeZone: TimeZone = .current) -> Date? {

        switch timezoneType {
        case .GLOBAL:
            let isoFormatter = ISO8601DateFormatter()
            return isoFormatter.date(from: isoDate)

        case .LOCAL:
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"  // Define the expected format
            dateFormatter.timeZone = timeZone
            if let localDate = dateFormatter.date(from: isoDate) {
                let secondsFromGMT = timeZone.secondsFromGMT(for: localDate)
                return localDate.addingTimeInterval(TimeInterval(secondsFromGMT))
            }
        }

        return nil

    }

    /// Formats an optional [AnyHashable: Any] dictionary into a human-readable string.
    /// It handles AnyHashable keys to print their base value and quotes string values.
    ///
    /// - Parameter payload: The optional dictionary to format.
    /// - Returns: A string representation of the dictionary, e.g., `['key': 'value', 'otherKey': 123]`
    static func formatPayloadForDisplay(_ payload: [AnyHashable: Any]?) -> String {
        guard let actualPayload = payload else {
            return "nil"
        }

        let sortedKeys = actualPayload.keys.sorted { (key1, key2) -> Bool in
            String(describing: key1.base) < String(describing: key2.base)
        }

        let formattedEntries = sortedKeys.map { key -> String in
            let value = actualPayload[key]!

            let keyOutput: String
            if let stringKey = key.base as? String {
                keyOutput = "'\(stringKey)'"
            } else {
                keyOutput = String(describing: key.base)
            }

            let valueOutput: String
            if let stringValue = value as? String {
                valueOutput = "'\(stringValue)'"
            } else {
                valueOutput = String(describing: value)
            }
            return "\(keyOutput): \(valueOutput)"
        }

        return "[\(formattedEntries.joined(separator: ", "))]"
    }

}
