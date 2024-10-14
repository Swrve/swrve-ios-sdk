import Foundation
import UIKit

@objc public class SwrveMessageCenterDetails: NSObject {

    @objc public var subject: String?
    @objc public var descriptionText: String?
    @objc public var image: UIImage?
    @objc public var imageSha: String?
    @objc public var imageUrl: String?
    @objc public var imageAccessibilityText: String?

    /// Initializes the message center details with a JSON dictionary.
    /// - Parameter data: A dictionary containing the message center details.
    init(withJSON data: [String: Any]) {
        self.subject = data["subject"] as? String
        self.descriptionText = data["description"] as? String
        self.imageAccessibilityText = data["accessibility_text"] as? String

        if let imageAsset = data["image_asset"] as? String {
            self.imageSha = imageAsset
        }
        if let dynamicImageUrl = data["dynamic_image_url"] as? String {
            self.imageUrl = dynamicImageUrl
        }
        super.init()

    }

    @objc override public var description: String {
        descriptionText ?? ""
    }

    /// Initializes the message center details with individual parameters.
    /// - Parameters:
    ///   - subject: The subject of the message.
    ///   - descriptionText: The description of the message.
    ///   - accessibilityText: The accessibility text for the image.
    ///   - imageUrl: The URL of the image.
    ///   - imageSha: The SHA hash of the image.
    ///   - image: The UIImage object representing the image.
    ///

    @objc public init(
        subject: String?,
        descriptionText: String?,
        accessibilityText: String?,
        imageUrl: String?,
        imageSha: String?,
        image: UIImage
    ) {
        self.subject = subject
        self.descriptionText = descriptionText
        self.imageAccessibilityText = accessibilityText
        self.imageUrl = imageUrl
        self.imageSha = imageSha
        self.image = image
        super.init()
    }
}
