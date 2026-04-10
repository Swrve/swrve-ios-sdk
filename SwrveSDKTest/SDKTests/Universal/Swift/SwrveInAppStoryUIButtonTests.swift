import XCTest

@testable import SwrveSDK

class SwrveInAppStoryUIButtonTests: XCTestCase {

    func testButtonInitialization() {
        let storySettings: [String: Any] = [
            "id": "123",
            "name": "Dismiss",
            "color": "#FF0000",
            "pressed_color": "#00FF00",
            "focused_color": "#0000FF",
            "size": "large",
            "margin_top": 10,
            "accessibility_text": "Close Button"
        ]

        let dismissButton = SwrveStoryDismissButton(storySettings: storySettings)

        var normalImage: UIImage?
        var highlightedImage: UIImage?
        if #available(tvOS 13.0, *) {
            normalImage = UIImage(systemName: "xmark.circle")
        } else {
            normalImage = UIImage(named: "xmark.circle")
        }

        if #available(tvOS 13.0, *) {
            highlightedImage = UIImage(systemName: "xmark.circle.fill")
        } else {
            highlightedImage = UIImage(named: "xmark.circle.fill")
        }

        let button = SwrveInAppStoryUIButton(
            button: dismissButton,
            dismissImage: normalImage!,
            dismissImageHighlighted: highlightedImage
        )

        XCTAssertEqual(button.storyDismissButton, dismissButton)
        XCTAssertEqual(button.image(for: .normal), normalImage)
        XCTAssertEqual(button.image(for: .highlighted), highlightedImage)
        XCTAssertEqual(button.tintColor, SwrveUtils.processHexColorValue(dismissButton.color))
        XCTAssertEqual(button.translatesAutoresizingMaskIntoConstraints, false)
        XCTAssertEqual(button.imageView!.contentMode, .scaleToFill)
        XCTAssertEqual(button.contentHorizontalAlignment, .fill)
        XCTAssertEqual(button.contentVerticalAlignment, .fill)
        XCTAssertEqual(button.adjustsImageWhenHighlighted, false)
        XCTAssertEqual(button.isAccessibilityElement, true)
        XCTAssertEqual(button.accessibilityLabel, dismissButton.accessibilityText)
        XCTAssertEqual(button.accessibilityHint, "Button")
    }

    func testButtonHighlightState() {
        let storySettings: [String: Any] = [
            "id": "123",
            "name": "Dismiss",
            "color": "#FF0000",
            "pressed_color": "#00FF00",
            "focused_color": "#0000FF",
            "size": "large",
            "margin_top": 10,
            "accessibility_text": "Close Button"
        ]

        let dismissButton = SwrveStoryDismissButton(storySettings: storySettings)

        var dismissImage: UIImage?
        var dismissHighlightedImage: UIImage?
        if #available(tvOS 13.0, *) {
            dismissImage = UIImage(systemName: "xmark.circle")
        } else {
            dismissImage = UIImage(named: "xmark.circle")
        }

        if #available(tvOS 13.0, *) {
            dismissHighlightedImage = UIImage(systemName: "xmark.circle.fill")
        } else {
            dismissHighlightedImage = UIImage(named: "xmark.circle.fill")
        }

        let button = SwrveInAppStoryUIButton(
            button: dismissButton,
            dismissImage: dismissImage!,
            dismissImageHighlighted: dismissHighlightedImage!
        )

        button.isHighlighted = true
        XCTAssertEqual(button.tintColor, SwrveUtils.processHexColorValue(dismissButton.pressedColor))

        button.isHighlighted = false
        XCTAssertEqual(button.tintColor, SwrveUtils.processHexColorValue(dismissButton.color))
    }
}
