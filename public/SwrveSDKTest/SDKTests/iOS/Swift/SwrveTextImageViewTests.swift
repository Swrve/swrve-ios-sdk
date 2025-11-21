import XCTest

@testable import SwrveSDK

class SwrveTextImageViewTests: XCTestCase {

    func testImageFromString_WithValidInputs_ShouldReturnNonNilImage() {
        let image = SwrveTextImageView.image(
            from: "Hello World",
            withBackgroundColor: .white,
            withForegroundColor: .black,
            with: UIFont.systemFont(ofSize: 20),
            size: CGSize(width: 200, height: 100)
        )
        XCTAssertNotNil(image, "Image should not be nil with valid inputs.")
    }

    func testImageFromString_WithZeroSize_ShouldReturnEmptyImage() {
        let image = SwrveTextImageView.image(
            from: "Hello World",
            withBackgroundColor: .white,
            withForegroundColor: .black,
            with: UIFont.systemFont(ofSize: 20),
            size: .zero
        )
        XCTAssertEqual(image.size.width, 0)
        XCTAssertEqual(image.size.height, 0)
    }
}
