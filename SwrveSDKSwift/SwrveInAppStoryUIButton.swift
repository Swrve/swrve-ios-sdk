import UIKit

@objc public class SwrveInAppStoryUIButton: UIButton {

    @objc public var storyDismissButton: SwrveStoryDismissButton

    @objc(initWithButton:dismissImage:dismissImageHighlighted:)
    public init(
        button: SwrveStoryDismissButton,
        dismissImage: UIImage,
        dismissImageHighlighted: UIImage?
    ) {

        self.storyDismissButton = button
        super.init(frame: .zero)

        self.setImage(dismissImage, for: .normal)
        if let highlightedImage = dismissImageHighlighted {
            self.setImage(highlightedImage, for: .highlighted)
        }

        self.tintColor = SwrveUtils.processHexColorValue(button.color)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.imageView?.contentMode = .scaleToFill
        self.contentHorizontalAlignment = .fill
        self.contentVerticalAlignment = .fill
        self.adjustsImageWhenHighlighted = false

        // Accessibility setup
        self.isAccessibilityElement = true
        self.accessibilityLabel = button.accessibilityText
        self.accessibilityHint = "Button"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc public override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                if let pressedColor = storyDismissButton.pressedColor {
                    self.tintColor = SwrveUtils.processHexColorValue(pressedColor)
                }
            } else if let normalColor = storyDismissButton.color {
                self.tintColor = SwrveUtils.processHexColorValue(normalColor)
            }
        }
    }
}
