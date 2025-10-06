import Foundation

@objc public class SwrveButtonTheme: NSObject {

    // MARK: - Properties

    @objc public var fontSize: NSNumber?
    @objc public var fontFile: String?
    @objc public var fontDigest: String?
    @objc public var fontNativeStyle: String?
    @objc public var fontPostscriptName: String?

    @objc public var topPadding: NSNumber?
    @objc public var rightPadding: NSNumber?
    @objc public var bottomPadding: NSNumber?
    @objc public var leftPadding: NSNumber?

    @objc public var cornerRadius: NSNumber?

    @objc public var fontColor: String?
    @objc public var bgColor: String?

    @objc public var borderWidth: NSNumber?
    @objc public var borderColor: String?

    @objc public var bgImage: String?
    @objc public var truncate: Bool = false

    @objc public var pressedState: SwrveButtonThemeState
    @objc public var focusedState: SwrveButtonThemeState?

    @objc public var hAlign: String?

    // MARK: - Init

    @objc public init(dictionary themeData: [String: Any]) {
        // Simple values
        fontSize = SwrveButtonTheme.cgFloat(from: themeData["font_size"]) as NSNumber?
        fontFile = themeData["font_file"] as? String

        if let digest = themeData["font_digest"] as? String {
            fontDigest = digest
        }
        if let nativeStyle = themeData["font_native_style"] as? String {
            fontNativeStyle = nativeStyle
        }

        fontPostscriptName = themeData["font_postscript_name"] as? String

        // Padding
        if let padding = themeData["padding"] as? [String: Any] {
            topPadding = SwrveButtonTheme.cgFloat(from: padding["top"]) as NSNumber?
            bottomPadding = SwrveButtonTheme.cgFloat(from: padding["bottom"]) as NSNumber?
            rightPadding = SwrveButtonTheme.cgFloat(from: padding["right"]) as NSNumber?
            leftPadding = SwrveButtonTheme.cgFloat(from: padding["left"]) as NSNumber?
        }

        cornerRadius = SwrveButtonTheme.cgFloat(from: themeData["corner_radius"]) as NSNumber?
        fontColor = themeData["font_color"] as? String

        // Note: original Obj-C sets fontDigest again; harmless no-op here if present
        if let digestAgain = themeData["font_digest"] as? String {
            fontDigest = digestAgain
        }

        if let bg = themeData["bg_color"] as? String {
            bgColor = bg
        }
        if let bw = themeData["border_width"] {
            borderWidth = SwrveButtonTheme.cgFloat(from: bw) as NSNumber?
        }
        if let bc = themeData["border_color"] as? String {
            borderColor = bc
        }

        // bg_image = { "value": "<string>" } (and may be NSNull)
        if let bgImageAny = themeData["bg_image"], !(bgImageAny is NSNull),
            let bgImageDict = bgImageAny as? [String: Any]
        {
            bgImage = bgImageDict["value"] as? String
        }

        truncate = (themeData["truncate"] as? Bool) ?? false

        // States
        let pressedDict = (themeData["pressed_state"] as? [String: Any]) ?? [:]
        self.pressedState = SwrveButtonThemeState(dictionary: pressedDict)

        if let focusedAny = themeData["focused_state"], !(focusedAny is NSNull),
            let focusedDict = focusedAny as? [String: Any]
        {
            self.focusedState = SwrveButtonThemeState(dictionary: focusedDict)
        }

        hAlign = themeData["h_align"] as? String
    }

    // MARK: - Helpers

    private static func cgFloat(from any: Any?) -> CGFloat? {
        switch any {
        case let n as NSNumber:
            return CGFloat(truncating: n)
        case let d as Double:
            return CGFloat(d)
        case let f as Float:
            return CGFloat(f)
        case let i as Int:
            return CGFloat(i)
        case let s as String:
            if let d = Double(s) { return CGFloat(d) }
            return nil
        default:
            return nil
        }
    }
}
