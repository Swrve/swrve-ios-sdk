import UIKit

@objc public class SwrveCalibration: NSObject {
    @objc public var calibrationWidth: CGFloat
    @objc public var calibrationHeight: CGFloat
    @objc public var calibrationFontSize: CGFloat
    @objc public var calibrationText: String

    @objc(initWithDictionary:)
    public init(calibration: [String: Any]) {
        self.calibrationWidth = CGFloat((calibration["width"] as? Double) ?? 0.0)
        self.calibrationHeight = CGFloat((calibration["height"] as? Double) ?? 0.0)
        self.calibrationFontSize = CGFloat((calibration["base_font_size"] as? Double) ?? 0.0)
        self.calibrationText = calibration["text"] as? String ?? ""
        super.init()
    }
}
