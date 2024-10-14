import Foundation

/// Represents the state of a Swrve Campaign.
@objc public class SwrveCampaignState: NSObject {

    /// Unique identifier of the campaign.
    @objc public var campaignID: UInt

    /// Number of times the campaign has been shown to the user.
    @objc public var impressions: UInt

    /// Status of the campaign (e.g., unseen, seen, etc.).
    @objc public var status: SwrveCampaignStatus

    /// Timestamp to block messages from appearing too frequently.
    @objc public var showMsgsAfterDelay: Date

    /// Timestamp when the campaign was first downloaded.
    @objc public var downloadDate: Date

    /// Initialize a fresh campaign state.
    /// - Parameters:
    ///   - campaignID: The unique identifier for the campaign.
    ///   - downloadDate: The date when the campaign was first downloaded.

    public init(campaignID: UInt, downloadDate: Date) {
        self.campaignID = campaignID
        self.impressions = 0
        self.status = .unseen  // Default status as unseen
        self.downloadDate = downloadDate
        self.showMsgsAfterDelay = downloadDate.addingTimeInterval(0)  // Default to no delay
    }

    /// Initialize the campaign state with JSON data.
    /// - Parameter json: A dictionary containing campaign data.

    @objc public init(from json: [String: Any]) {
        self.campaignID = json["ID"] as? UInt ?? 0
        self.impressions = json["impressions"] as? UInt ?? 0
        self.status = SwrveCampaignStatus(rawValue: json["status"] as? Int ?? 0) ?? .unseen
        self.downloadDate = json["downloadDate"] as? Date ?? Date()
        self.showMsgsAfterDelay = json["showMsgsAfterDelay"] as? Date ?? Date()
    }

    /// Converts the campaign state to a dictionary.
    /// - Returns: A dictionary representation of the campaign state.

    @objc public func asDictionary() -> [String: Any] {
        [
            "ID": campaignID,
            "impressions": impressions,
            "status": status.rawValue,
            "showMsgsAfterDelay": showMsgsAfterDelay,
            "downloadDate": downloadDate
        ]
    }
}
