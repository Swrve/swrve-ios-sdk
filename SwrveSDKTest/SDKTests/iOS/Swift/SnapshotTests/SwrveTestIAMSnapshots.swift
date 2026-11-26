import UIKit
import XCTest

@testable import SwrveSDK

// The kinds of element a message is made of, one campaign each, made in the dashboard and shown on an iPhone 17. Each
// fixture is what the server sent for this screen, with a trigger added. The Android SDK's screenshot tests use the same
// campaigns.
class SwrveTestIAMSnapshots: SwrveIAMSnapshotTestCase {

    override func setUpWithError() throws {
        try skipOnIPad()
    }

    // https://dashboard.swrve.com/apps/32032/campaigns/749297: the background button, an image, two image buttons, and an
    // image button with text
    func testImages() throws {
        let (vc, image) = try showMessage(
            campaignFile: "campaign_screenshot_images", campaignId: 749297,
            assets: [
                Self.background, "991b322d97743c1e8d8f7b3248191ecfa9f9e764", "5cdaa8c4ff8475da00d256cc7b89ee8406062ada",
                "094dfa7cb186b9dec5900db3112d0047ddee6b44", "b48be8e5feef1310d250a54e718e67a8f26b2b7a"
            ])
        let elements = try elements(of: vc)
        XCTAssertEqual(5, elements.count)
        XCTAssertTrue(elements[0] is SwrveUIButton)
        XCTAssertTrue(elements[1] is UIImageView)
        XCTAssertTrue(elements[2] is SwrveUIButton)
        XCTAssertTrue(elements[3] is SwrveUIButton)
        XCTAssertEqual("Dismiss text button", try XCTUnwrap(elements[4] as? SwrveUIButton).displayString)
        checkSnapshot(image, testName: #function)
    }

    // https://dashboard.swrve.com/apps/32032/campaigns/749300: the background button and five multiline texts: a custom font,
    // a paragraph that doesn't scroll, the same with scrolling, centred, and right aligned
    func testText() throws {
        let (vc, image) = try showMessage(campaignFile: "campaign_screenshot_text", campaignId: 749300, assets: [Self.background, Self.font])
        let texts = try elements(of: vc).dropFirst().map { try XCTUnwrap($0 as? SwrveUITextView) }
        XCTAssertEqual(5, texts.count)
        let (customFont, resize, scroll) = (texts[0], texts[1], texts[2])
        XCTAssertEqual("Pacifico-Regular", customFont.font?.fontName)
        // Set to the same size: the text that doesn't scroll shrinks to fit, and the text that scrolls keeps its size and overflows
        let resizeSize = try XCTUnwrap(resize.font?.pointSize)
        let scrollSize = try XCTUnwrap(scroll.font?.pointSize)
        XCTAssertLessThan(resizeSize, scrollSize)
        XCTAssertFalse(resize.isScrollEnabled)
        XCTAssertTrue(scroll.isScrollEnabled)
        XCTAssertGreaterThan(scroll.contentSize.height, scroll.bounds.height)
        checkSnapshot(image, testName: #function)
    }

    // https://dashboard.swrve.com/apps/32032/campaigns/749305: the background button and six themed buttons: solid, outlined,
    // truncated, shrunk to fit, a custom font, and an image background with another image for pressed
    func testButtons() throws {
        let (vc, image) = try showMessage(
            campaignFile: "campaign_screenshot_buttons", campaignId: 749305,
            assets: [
                Self.background, Self.font, Self.buttonImage, Self.buttonImagePressed
            ])
        let buttons = try elements(of: vc).dropFirst().map { try XCTUnwrap($0 as? SwrveThemedUIButton) }
        XCTAssertEqual(6, buttons.count)
        let (truncated, shrinks, customFont) = (buttons[2], buttons[3], buttons[4])
        // Set to the same size: a truncated label ends with an ellipsis, and the other shrinks to fit
        XCTAssertEqual(.byTruncatingTail, truncated.titleLabel?.lineBreakMode)
        XCTAssertEqual(true, shrinks.titleLabel?.adjustsFontSizeToFitWidth)
        let truncatedSize = try XCTUnwrap(truncated.titleLabel?.font.pointSize)
        let shrinksSize = try XCTUnwrap(shrinks.titleLabel?.font.pointSize)
        XCTAssertLessThan(shrinksSize, truncatedSize)
        XCTAssertEqual("Pacifico-Regular", customFont.titleLabel?.font.fontName)
        checkSnapshot(image, testName: #function)
    }

    // Shows the campaign's message on the phone, with its assets in the cache
    private func showMessage(campaignFile: String, campaignId: Int, assets: [String]) throws -> (SwrveMessageViewController, UIImage) {
        let controller = try startMessageController(campaignFile: campaignFile) { copyResources(assets) }
        let vc = try messageViewController(controller, campaignId: campaignId)
        return (vc, capture(try show(vc, size: Self.phone)))
    }
}
