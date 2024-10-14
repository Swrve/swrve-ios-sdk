@objcMembers public class SwrveMessageDetails: NSObject {
    public var campaignSubject: String
    public var campaignId: UInt
    public var variantId: UInt
    public var messageName: String
    public var buttons: [SwrveMessageButtonDetails]

    public init(with campaignSubject: String, campaignId: UInt, variantId: UInt, messageName: String, buttons: [SwrveMessageButtonDetails]) {
        self.campaignSubject = campaignSubject
        self.campaignId = campaignId
        self.variantId = variantId
        self.messageName = messageName
        self.buttons = buttons
        super.init()
    }
}
