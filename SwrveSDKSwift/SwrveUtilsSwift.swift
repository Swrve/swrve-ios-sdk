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
}
