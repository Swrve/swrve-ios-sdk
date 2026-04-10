import UIKit

@objc public class SwrveStoryDismissButton: NSObject {
    @objc public var buttonId: NSNumber?
    @objc public var name: String?
    @objc public var color: String?
    @objc public var pressedColor: String?
    @objc public var focusedColor: String?
    @objc public var size: NSNumber?
    @objc public var marginTop: NSNumber?
    @objc public var accessibilityText: String?

    @objc(initWithDictionary:)
    public init(storySettings: [String: Any]) {
        self.buttonId = storySettings["id"] as? NSNumber
        self.name = storySettings["name"] as? String
        self.color = storySettings["color"] as? String
        self.pressedColor = storySettings["pressed_color"] as? String
        self.focusedColor = storySettings["focused_color"] as? String
        self.size = storySettings["size"] as? NSNumber
        self.marginTop = storySettings["margin_top"] as? NSNumber
        self.accessibilityText = storySettings["accessibility_text"] as? String
        super.init()
    }
}
