import Foundation
import UIKit

#if canImport(SwrveSDK)
import SwrveSDK
#endif

#if canImport(SwrveSDKCommon)
import SwrveSDKCommon
#endif

@objc public class SwrveBaseMessage: NSObject {

    @objc public var campaign: SwrveCampaign?

    @objc public var campaignID: UInt = 0

    @objc public var messageID: NSNumber?

    @objc public var priority: NSNumber?

    @objc public var name: String?

    @objc public var messageCenterDetails: SwrveMessageCenterDetails?

    @objc public var control: Bool = false

    public override init() {
        super.init()
    }
}
