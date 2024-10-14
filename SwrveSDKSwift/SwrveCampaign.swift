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

    /// Campaign start date.
    @objc public var dateStart: Date

    /// Campaign end date.
    @objc public var dateEnd: Date

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

    // MARK: - Initialization

    /// Initializes the campaign at the given time with data from a dictionary.
    ///
    /// - Parameters:
    ///   - time: The time of initialization.
    ///   - json: A dictionary containing the campaign data.
    @objc public init(at time: Date, from json: [String: Any], campaignType: SwrveCampaignType) {
        let campaignID = json["id"] as? UInt ?? 0
        self.ID = campaignID
        self.state = SwrveCampaignState(campaignID: campaignID, downloadDate: time)
        self.showMsgsAfterLaunch = time.addingTimeInterval(SwrveCampaign.defaultDelayFirstMessage)
        self.initialisedTime = time
        self.messageCenter = json["message_center"] as? Bool ?? false
        self.campaignType = campaignType
        let now = Date()
        self.dateStart = now
        self.dateEnd = now
        super.init()

        loadTriggers(from: json)
        loadRules(from: json)
        loadDates(from: json)
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
        if dateStart.compare(time) != .orderedAscending {
            logAndAdd(reason: "Campaign \(ID) has not started yet", withReasons: campaignReasons)
            return false
        }

        if time.compare(dateEnd) != .orderedAscending {
            logAndAdd(reason: "Campaign \(ID) has finished", withReasons: campaignReasons)
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

    // MARK: - Private Methods

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

    /// Loads date-related values from the campaign's JSON data.
    ///
    /// - Parameter json: A dictionary containing campaign data.
    private func loadDates(from json: [String: Any]) {
        if let startDate = json["start_date"] as? NSNumber {
            self.dateStart = Date(timeIntervalSince1970: startDate.doubleValue / 1000.0)
        }
        if let endDate = json["end_date"] as? NSNumber {
            self.dateEnd = Date(timeIntervalSince1970: endDate.doubleValue / 1000.0)
        }
    }
}
