import Foundation

@objc public class SwrveButtonThemeState: NSObject {

    @objc public var fontColor: String?
    @objc public var bgColor: String?
    @objc public var borderColor: String?
    @objc public var bgImage: String?

    @objc public init(dictionary themeState: [String: Any]) {
        if let fontColor = themeState["font_color"] as? String {
            self.fontColor = fontColor
        }
        if let bgColor = themeState["bg_color"] as? String {
            self.bgColor = bgColor
        }
        if let borderColor = themeState["border_color"] as? String {
            self.borderColor = borderColor
        }
        if let bgImageAny = themeState["bg_image"], !(bgImageAny is NSNull),
            let bgImageDict = bgImageAny as? [String: Any]
        {
            self.bgImage = bgImageDict["value"] as? String
        }
    }
}
