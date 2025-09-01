import Foundation
import UIKit

@objc public class SwrveVideoSettings: NSObject {

    /// Whether the media should autoplay.
    @objc public var autoPlay: Bool = true

    /// Whether the media should loop.
    @objc public var loop: Bool = true

    /// Whether the media should fill the screen.
    @objc public var fillScreen: Bool = false

    /// Whether media controls should be shown.
    @objc public var showControls: Bool = true

    /// Default initializer
    @objc public override init() {
        super.init()
    }

    /// Initializes SwrveMediaSettings from JSON.
    @objc(initWithJson:) public init(_ json: NSDictionary) {
        if let autoPlayValue = json.value(forKey: "auto_play") as? Bool {
            self.autoPlay = autoPlayValue
        }
        if let loopsValue = json.value(forKey: "loop") as? Bool {
            self.loop = loopsValue
        }
        if let fillScreenValue = json.value(forKey: "fill_screen") as? Bool {
            self.fillScreen = fillScreenValue
        }
        if let showControlsValue = json.value(forKey: "show_controls") as? Bool {
            self.showControls = showControlsValue
        }
    }
}
