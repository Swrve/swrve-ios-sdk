import Foundation
import UIKit

#if canImport(SwrveSDK)
import SwrveSDK
#endif

#if canImport(SwrveSDKCommon)
import SwrveSDKCommon
#endif

@objc public class SwrveEmbeddedCampaign: SwrveCampaign {

    /// Message attached to this embedded campaign.
    @objc public var message: SwrveEmbeddedMessage?

    /// Initializes the embedded campaign at the given time from the provided dictionary.
    ///
    /// - Parameters:
    ///   - time: The time of initialization.
    ///   - json: A dictionary containing the campaign data.
    /// - Returns: An initialized instance of `SwrveEmbeddedCampaign`.
    @objc public init(at time: Date, from json: [String: Any]) {
        super.init(at: time, from: json, campaignType: SWRVE_CAMPAIGN_EMBEDDED)

        if let embeddedMessageDict = json["embedded_message"] as? [String: Any] {
            self.message = SwrveEmbeddedMessage.fromDictionary(embeddedMessageDict, andCampaign: self)
        }

        self.name = self.message?.name ?? ""
    }

    /// Checks whether the campaign has a message for the given event with payload.
    ///
    /// - Parameters:
    ///   - event: The trigger event to check for.
    ///   - payload: A dictionary containing the payload for verifying conditions.
    /// - Returns: `true` if the campaign contains a message for the event, otherwise `false`.
    @objc public func hasMessage(forEvent event: String, withPayload payload: [String: Any]?) -> Bool {
        canTrigger(withEvent: event, andPayload: payload)
    }

    /// Retrieves the message for the given event, payload, and time.
    ///
    /// - Parameters:
    ///   - event: The trigger event.
    ///   - payload: The payload for verifying conditions.
    ///   - time: The current device time.
    ///   - campaignReasons: A dictionary containing the reasons the campaign did not return a message.
    /// - Returns: The embedded message for the event, or `nil` if no message exists.
    @objc public func message(
        forEvent event: String,
        withPayload payload: [String: Any]?,
        at time: Date,
        withReasons campaignReasons: NSMutableDictionary
    ) -> SwrveEmbeddedMessage? {

        if !hasMessage(forEvent: event, withPayload: payload) {
            let payloadDescription = SwrveUtilsSwift.formatPayloadForDisplay(payload)
            let reason = "There is no trigger in \(ID) that matches \(event) with conditions \(payloadDescription)"
            SwrveLogger.logDebug(reason)
            logAndAdd(reason: reason, withReasons: campaignReasons)
            return nil
        }

        guard let message = self.message else {
            let reason = "No embedded message in campaign \(self.ID)"
            logAndAdd(reason: reason, withReasons: campaignReasons)
            return nil
        }

        if !checkCampaignRules(forEvent: event, atTime: time, withReasons: campaignReasons) {
            return nil
        }

        return message
    }

    /// Checks whether the campaign supports a specific orientation.
    ///
    /// - Parameter orientation: The interface orientation.
    /// - Returns: `true` if the campaign supports the orientation, otherwise `false`.
    #if os(iOS)
    public override func supportsOrientation(_ orientation: UIInterfaceOrientation) -> Bool {
        true
    }
    #endif

    /// Checks if the assets for the campaign are ready.
    ///
    /// - Parameters:
    ///   - assets: The set of assets.
    ///   - personalization: The personalization dictionary.
    /// - Returns: `true` if the assets are ready, otherwise `false`.
    @objc public override func assetsReady(_ assets: Set<String>, withPersonalization personalization: [String: Any]?) -> Bool {
        true
    }
}
