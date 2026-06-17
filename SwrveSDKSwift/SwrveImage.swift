import UIKit

#if canImport(SwrveSDK)
import SwrveSDK
#endif

#if canImport(SwrveSDKCommon)
import SwrveSDKCommon
#endif

@objc public class SwrveImage: NSObject {

    @objc public var file: String?
    @objc public var dynamicImageUrl: String?
    @objc public var text: String?
    @objc public var center: CGPoint = .zero
    @objc public var size: CGSize = .zero
    @objc public var messageId: Int64 = 0
    @objc public var campaignId: Int64 = 0
    @objc public var multilineText: [String: Any]?
    @objc public var accessibilityText: String?
    @objc public var iamZIndex: Int64 = 0
    @objc public var videoSettings: SwrveVideoSettings?
    @objc public var mediaId: NSNumber?
    @objc public var visibleIf: String = ""

    @objc(initWithDictionary:campaignId:messageId:) public init(
        imageData: [String: Any], campaignId swrveCampaignId: Int64, messageId swrveMessageId: Int64
    ) {
        super.init()

        self.campaignId = swrveCampaignId
        self.messageId = swrveMessageId

        if let image = imageData["image"] as? [String: Any],
            let value = image["value"] as? String
        {
            self.file = value
        }

        if let dynamicUrl = imageData["dynamic_image_url"] as? String {
            self.dynamicImageUrl = dynamicUrl
        }

        if let xDict = imageData["x"] as? [String: Any],
            let xValue = xDict["value"] as? NSNumber,
            let yDict = imageData["y"] as? [String: Any],
            let yValue = yDict["value"] as? NSNumber
        {
            self.center = CGPoint(x: CGFloat(truncating: xValue), y: CGFloat(truncating: yValue))
        }

        if let wDict = imageData["w"] as? [String: Any],
            let wValue = wDict["value"] as? NSNumber,
            let hDict = imageData["h"] as? [String: Any],
            let hValue = hDict["value"] as? NSNumber
        {
            self.size = CGSize(width: CGFloat(truncating: wValue), height: CGFloat(truncating: hValue))
        }

        if let textDict = imageData["text"] as? [String: Any],
            let textValue = textDict["value"] as? String
        {
            self.text = textValue
        }

        self.multilineText = imageData["multiline_text"] as? [String: Any]

        SwrveLogger.logDebug("Image Loaded: Asset: \"\(self.file ?? "")\" (x: \(self.center.x) y: \(self.center.y))")

        if let accessibility = imageData["accessibility_text"] as? String {
            self.accessibilityText = accessibility
        }

        if let zIndex = imageData["iam_z_index"] as? Int64 {
            self.iamZIndex = zIndex
        }

        if let videoSettingsJson = imageData["video_settings"] as? [String: Any] {
            self.videoSettings = SwrveVideoSettings(videoSettingsJson as NSDictionary)
        }

        if let mediaId = imageData["media_id"] as? NSNumber {
            self.mediaId = mediaId
        }

        self.visibleIf = imageData["visible_if"] as? String ?? ""
    }
}
