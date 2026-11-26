import Foundation

/// QA diagnostic payload describing an image-personalization asset that could not be resolved.
@objc(SwrveQAImagePersonalizationInfo)
public class SwrveQAImagePersonalizationInfo: NSObject {

    @objc public var campaignID: UInt = 0
    @objc public var variantID: UInt = 0
    @objc public var assetName: String?
    @objc public var hasFallback: Bool = false
    @objc public var unresolvedUrl: String?
    @objc public var resolvedUrl: String?
    @objc public var reason: String?

    @objc public override init() {
        super.init()
    }

    @objc(initWithCampaign:variantID:hasFallback:unresolvedUrl:)
    public init(campaign campaignID: UInt, variantID: UInt, hasFallback: Bool, unresolvedUrl: String?) {
        self.campaignID = campaignID
        self.variantID = variantID
        self.hasFallback = hasFallback
        self.unresolvedUrl = unresolvedUrl
        super.init()
    }
}
