@objcMembers public class SwrveMessageButtonDetails: NSObject {
    public var buttonName: String
    public var buttonText: String?
    public var actionType: SwrveActionType
    public var actionString: String

    public init(with buttonName: String, buttonText: String?, actionType: SwrveActionType, actionString: String) {
        self.buttonName = buttonName
        self.buttonText = buttonText
        self.actionType = actionType
        self.actionString = actionString
        super.init()
    }
}
