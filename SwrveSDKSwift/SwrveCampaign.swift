import Foundation
import UIKit

#if canImport(SwrveSDK)
    import SwrveSDK
#endif

#if canImport(SwrveSDKCommon)
    import SwrveSDKCommon
#endif

/// Base campaign class representing a campaign in the Swrve SDK.
@objc public class SwrveCampaign: NSObject {

    static let defaultMaxImpressions: UInt = 99999
    static let defaultDelayFirstMessage: Double = 180.0
    static let defaultMinimumDelayBetweenMessages = 60.0

    /// Unique identifier of the campaign.
    @objc public var ID: UInt = 0

    /// Name of the campaign.
    @objc public var name: String = ""

    /// Maximum number of impressions allowed for the campaign per user.
    @objc public var maxImpressions: UInt = defaultMaxImpressions

    /// The current state of the campaign.
    @objc public var state: SwrveCampaignState

    /// Minimum delay between showing messages from different campaigns.
    @objc public var minDelayBetweenMsgs: TimeInterval = defaultMinimumDelayBetweenMessages

    /// Timestamp to block messages after launch.
    @objc public var showMsgsAfterLaunch: Date

    /// Indicates if this is a Message Center campaign.
    @objc public var messageCenter: Bool = false

    /// The timezone type of the campaign.
    @objc public var timezoneType: SwrveTimezoneType

    /// Start date of the campaign.
    @objc public var startDateIso: String

    /// Campaign start date.
    @objc public var dateStart: Date {
        if startDateIso.isEmpty {
            return Date.distantFuture
        }
        return SwrveUtilsSwift.parseIso8601Date(startDateIso, timezoneType: timezoneType) ?? Date.distantFuture
    }

    /// End date of the campaign.
    @objc public var endDateIso: String

    /// Campaign end date.
    @objc public var dateEnd: Date {
        if endDateIso.isEmpty {
            return Date.distantPast
        }
        return SwrveUtilsSwift.parseIso8601Date(endDateIso, timezoneType: timezoneType) ?? Date.distantPast
    }

    /// Array of blackout dates for the campaign.
    @objc public var blackoutDates: [SwrveBlackoutDate] = []

    /// Array of interval times for the campaign.
    @objc public var intervalTimes: [SwrveIntervalTime] = []

    /// Enum representing the campaign type for QA Logging.
    @objc public var campaignType: SwrveCampaignType

    /// Priority of the campaign.
    @objc public var priority: NSNumber = NSNumber(value: 0)

    /// Message center campaign details, such as subject, description, and icon.
    @objc public var messageCenterDetails: SwrveMessageCenterDetails?

    /// Triggers associated with this campaign.
    private var triggers: NSMutableSet = NSMutableSet()

    /// Timestamp when the campaign was initialized.
    private var initialisedTime: Date

    private var timeZone: TimeZone

    // MARK: - Initialization

    /// Initializes the campaign at the given time with data from a dictionary.
    ///
    /// - Parameters:
    ///   - time: The time of initialization.
    ///   - json: A dictionary containing the campaign data.
    @objc public init(at time: Date, from json: [String: Any], campaignType: SwrveCampaignType, timeZone: TimeZone = .current) {
        let campaignID = json["id"] as? UInt ?? 0
        self.ID = campaignID
        self.state = SwrveCampaignState(campaignID: campaignID, downloadDate: time)
        self.showMsgsAfterLaunch = time.addingTimeInterval(SwrveCampaign.defaultDelayFirstMessage)
        self.initialisedTime = time
        self.messageCenter = json["message_center"] as? Bool ?? false
        self.campaignType = campaignType
        self.startDateIso = json["start_date_iso"] as? String ?? ""
        self.endDateIso = json["end_date_iso"] as? String ?? ""
        self.timezoneType = SwrveTimezoneType.create(from: json)
        self.timeZone = timeZone
        super.init()

        loadTriggers(from: json)
        loadRules(from: json)
        loadBlackoutDates(from: json)
        loadIntervalTimes(from: json)
    }

    @objc public class SwrveBlackoutDate: NSObject {
        @objc public let from: String
        @objc public let to: String

        public init(from: String, to: String) {
            self.from = from
            self.to = to
        }
    }

    @objc public class SwrveIntervalTime: NSObject {
        @objc public let from: String
        @objc public let to: String

        public init(from: String, to: String) {
            self.from = from
            self.to = to
        }
    }

    // MARK: - Methods

    /// Sets a throttle to delay future messages.
    ///
    /// - Parameter timeShown: The time the message was shown to the user.
    @objc public func setMessageMinDelayThrottle(at timeShown: Date) {
        self.state.showMsgsAfterDelay = timeShown.addingTimeInterval(self.minDelayBetweenMsgs)
    }

    /// Marks the campaign as shown to the user and applies throttle.
    ///
    /// - Parameter timeShown: The time the message was shown to the user.
    @objc public func wasShownToUser(at timeShown: Date) {
        self.state.impressions += 1
        setMessageMinDelayThrottle(at: timeShown)
        self.state.status = .seen
    }

    /// Checks if the campaign supports a given device orientation (iOS only).
    ///
    /// - Parameter orientation: The device orientation.
    /// - Returns: `true` if the campaign supports the orientation.
    ///
    #if os(iOS)
        @objc public func supportsOrientation(_ orientation: UIInterfaceOrientation) -> Bool {
            false
        }
    #endif

    /// Checks if all required assets are ready for the campaign.
    ///
    /// - Parameters:
    ///   - assets: A set of required assets.
    ///   - personalization: Personalization data for the assets.
    /// - Returns: `true` if all assets are ready.
    @objc public func assetsReady(_ assets: Set<String>, withPersonalization personalization: [String: Any]) -> Bool {
        false
    }

    /// Gets the download date of the campaign.
    ///
    /// - Returns: The date when the campaign was downloaded.
    @objc public func downloadDate() -> Date {
        state.downloadDate
    }

    @objc public func isTooSoonToShowMessageAfterLaunch(_ now: Date) -> Bool {
        now.compare(showMsgsAfterLaunch) == .orderedAscending
    }

    @objc public func isTooSoonToShowMessageAfterDelay(_ now: Date) -> Bool {
        now.compare(state.showMsgsAfterDelay) == .orderedAscending
    }

    /// Logs and adds a reason for a campaign not triggering.
    ///
    /// - Parameters:
    ///   - reason: The reason why the campaign didn't trigger.
    ///   - campaignReasons: Mutable dictionary to store reasons.
    func logAndAdd(reason: String, withReasons campaignReasons: NSMutableDictionary) {
        SwrveLogger.logDebug(reason)
        campaignReasons.setValue(reason, forKey: String(self.ID))
    }

    @objc public func isActive(at time: Date, withReasons campaignReasons: NSMutableDictionary) -> Bool {
        let startDate = dateStart  // evaluate once
        if startDate.compare(time) != .orderedAscending {
            let startDateLog = logDate(date: startDate, timezoneType: timezoneType)
            let nowLog = logDate(date: time, timezoneType: timezoneType)
            let text = "Campaign \(ID) has not started yet. Start:\(startDateLog) TimezoneType:\(timezoneType) Now:\(nowLog)"
            logAndAdd(reason: text, withReasons: campaignReasons)
            return false
        }

        let endDate = dateEnd  // evaluate once
        if time.compare(endDate) != .orderedAscending {
            let endDateLog = logDate(date: endDate, timezoneType: timezoneType)
            let nowLog = logDate(date: time, timezoneType: timezoneType)
            let text = "Campaign \(ID) has finished. End:\(endDateLog) TimezoneType:\(timezoneType) Now:\(nowLog)"
            logAndAdd(reason: text, withReasons: campaignReasons)
            return false
        }

        for blackoutDate in blackoutDates {
            guard let fromDate = SwrveUtilsSwift.parseIso8601Date(blackoutDate.from, timezoneType: timezoneType),
                let toDate = SwrveUtilsSwift.parseIso8601Date(blackoutDate.to, timezoneType: timezoneType)
            else {
                SwrveLogger.logError("Error parsing blackout date: \(blackoutDate) in campaign \(ID). Skip to next blackout date")
                continue
            }

            if time.compare(fromDate) == .orderedDescending && time.compare(toDate) == .orderedAscending {
                let fromLog = logDate(date: fromDate, timezoneType: timezoneType)
                let toLog = logDate(date: toDate, timezoneType: timezoneType)
                let nowLog = logDate(date: time, timezoneType: timezoneType)
                let text = "Campaign \(ID) is in blackout period. Blackout from:\(fromLog) to:\(toLog) TimezoneType:\(timezoneType) Now:\(nowLog)"
                logAndAdd(reason: text, withReasons: campaignReasons)
                return false
            }
        }

        if !hasActiveTimeInterval(now: time) {
            let nowLog = logDate(date: time, timezoneType: timezoneType)
            let text = "Campaign \(ID) is outside active interval time. TimezoneType:\(timezoneType) Now:\(nowLog)"
            logAndAdd(reason: text, withReasons: campaignReasons)
            return false
        }

        return true
    }

    func checkCampaignRules(forEvent event: String, atTime time: Date, withReasons campaignReasons: NSMutableDictionary) -> Bool {
        if !isActive(at: time, withReasons: campaignReasons) {
            return false
        }

        if event.caseInsensitiveCompare(AUTOSHOW_AT_SESSION_START_TRIGGER) != .orderedSame && isTooSoonToShowMessageAfterLaunch(time) {
            let formattedTime = String(describing: SwrveMessageController.formattedTime(showMsgsAfterLaunch))
            logAndAdd(reason: "{Campaign throttle limit} Too soon after launch. Wait until \(formattedTime)", withReasons: campaignReasons)
            return false
        }

        if isTooSoonToShowMessageAfterDelay(time) {
            let formattedTime = String(describing: SwrveMessageController.formattedTime(state.showMsgsAfterDelay))
            logAndAdd(reason: "{Campaign throttle limit} Too soon after last message. Wait until \(formattedTime)", withReasons: campaignReasons)
            return false
        }

        if state.impressions >= maxImpressions {
            logAndAdd(reason: "{Campaign throttle limit} Campaign \(ID) has been shown \(maxImpressions) times already", withReasons: campaignReasons)
            return false
        }

        return true
    }

    /// Checks if the campaign can trigger with the given event and payload.
    ///
    /// - Parameters:
    ///   - event: The event name.
    ///   - payload: The payload to check against trigger conditions.
    /// - Returns: `true` if the campaign can trigger.
    func canTrigger(withEvent event: String, andPayload payload: [AnyHashable: Any]?) -> Bool {
        for trigger in triggers {
            if let trigger = trigger as? SwrveTrigger,
                trigger.eventName == event.lowercased()
            {
                if !trigger.conditions.isEmpty {
                    return trigger.canTrigger(withPayload: payload ?? [:])
                }
                return true
            }
        }
        return false
    }

    /// Loads triggers from the campaign's JSON data.
    ///
    /// - Parameter json: A dictionary containing campaign data.
    private func loadTriggers(from json: [String: Any]) {
        if let triggerArray = SwrveTrigger.initTriggers(from: json) {
            triggers.addObjects(from: triggerArray)
        } else {
            SwrveLogger.logError("Error loading triggers")
        }
    }

    /// Loads rules from the campaign's JSON data.
    ///
    /// - Parameter json: A dictionary containing campaign data.
    private func loadRules(from json: [String: Any]) {
        if let rules = json["rules"] as? [String: Any] {
            SwrveLogger.logDebug("Rules: \(rules)")
            if let jsonMaxImpressions = rules["dismiss_after_views"] as? NSNumber {
                self.maxImpressions = jsonMaxImpressions.uintValue
            }
            if let delayFirstMsg = rules["delay_first_message"] as? NSNumber {
                self.showMsgsAfterLaunch = self.initialisedTime.addingTimeInterval(delayFirstMsg.doubleValue)
            }
            if let jsonMinDelayBetweenMsgs = rules["min_delay_between_messages"] as? NSNumber {
                self.minDelayBetweenMsgs = jsonMinDelayBetweenMsgs.doubleValue
            }
        }
    }

    private func loadBlackoutDates(from json: [String: Any]) {
        if let blackoutDatesData = json["blackout_dates"] as? [[String: Any]] {
            blackoutDates = blackoutDatesData.compactMap { blackoutDateData -> SwrveBlackoutDate? in
                guard let fromString = blackoutDateData["from"] as? String,
                    let toString = blackoutDateData["to"] as? String
                else {
                    return nil
                }
                return SwrveBlackoutDate(from: fromString, to: toString)
            }
        }
    }

    private func loadIntervalTimes(from json: [String: Any]) {
        if let intervalTimesData = json["interval_times"] as? [[String: Any]] {
            intervalTimes = intervalTimesData.compactMap { intervalTimeData -> SwrveIntervalTime? in
                guard let fromString = intervalTimeData["from"] as? String,
                    let toString = intervalTimeData["to"] as? String
                else {
                    return nil
                }
                return SwrveIntervalTime(from: fromString, to: toString)
            }
        }
    }

    func hasActiveTimeInterval(now: Date) -> Bool {
        if intervalTimes.isEmpty {
            return true  // no interval times set, so always return true
        }

        for intervalTime in intervalTimes {
            do {
                let fromSeconds = try secondsSinceMidnight(from: intervalTime.from)
                let toSeconds = try secondsSinceMidnight(from: intervalTime.to)
                let nowSeconds = try secondsSinceMidnight(from: now, timezoneType: timezoneType)

                if fromSeconds > toSeconds {
                    return false  // time intervals should not go over midnight
                }

                if (fromSeconds...toSeconds).contains(nowSeconds) {
                    return true
                }

            } catch {
                return false
            }
        }

        return false  // no interval times matched, so return false
    }

    func secondsSinceMidnight(from: String) throws -> Int {
        let timeParts = from.split(separator: ":").map { String($0) }  // Convert to String to validate later
        guard timeParts.count == 3 else {
            throw NSError(domain: "InvalidTimeInterval", code: 0, userInfo: [NSLocalizedDescriptionKey: "TimeInterval must be integer in HH:mm:ss"])
        }
        // Validate each part before converting to Int
        guard let hours = Int(timeParts[0]), let minutes = Int(timeParts[1]), let seconds = Int(timeParts[2]) else {
            throw NSError(domain: "InvalidTimeInterval", code: 0, userInfo: [NSLocalizedDescriptionKey: "TimeInterval must be integer in HH:mm:ss"])
        }
        return hours * 3600 + minutes * 60 + seconds
    }

    func secondsSinceMidnight(from: Date, timezoneType: SwrveTimezoneType) throws -> Int {
        let calendar = Calendar.current
        var components: DateComponents

        switch timezoneType {
        case .GLOBAL:
            var utcCalendar = calendar
            utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
            components = utcCalendar.dateComponents([.hour, .minute, .second], from: from)
        case .LOCAL:
            components = calendar.dateComponents([.hour, .minute, .second], from: from)
        }

        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0
        let seconds = components.second ?? 0

        return hours * 3600 + minutes * 60 + seconds
    }

    private func logDate(date: Date, timezoneType: SwrveTimezoneType) -> String {
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss z"
        dateFormat.locale = Locale(identifier: "en_US")

        let tz: TimeZone
        switch timezoneType {
        case .GLOBAL:
            tz = TimeZone(identifier: "UTC") ?? TimeZone.current
        case .LOCAL:
            tz = timeZone
        }

        dateFormat.timeZone = tz
        return dateFormat.string(from: date)
    }

}
