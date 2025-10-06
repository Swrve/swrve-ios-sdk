@objc public class SwrveMessageButtonDetails: NSObject {
    @objc public var buttonName: String
    @objc public var buttonText: String?
    @objc public var actionType: SwrveActionType
    @objc public var actionString: String

    @objc public init(with buttonName: String, buttonText: String?, actionType: SwrveActionType, actionString: String) {
        self.buttonName = buttonName
        self.buttonText = buttonText
        self.actionType = actionType
        self.actionString = actionString
        super.init()
    }
}
