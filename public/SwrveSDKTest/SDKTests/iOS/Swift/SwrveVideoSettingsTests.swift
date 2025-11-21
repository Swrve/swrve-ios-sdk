import XCTest

@testable import SwrveSDK

class SwrveVideoSettingsTests: XCTestCase {

    func testDefaultInitializer() {
        let settings = SwrveVideoSettings()

        XCTAssertTrue(settings.autoPlay, "Default value for autoPlay should be true")
        XCTAssertTrue(settings.loop, "Default value for loop should be true")
        XCTAssertFalse(settings.fillScreen, "Default value for fillScreen should be false")
        XCTAssertTrue(settings.showControls, "Default value for showControls should be true")
    }

    func testInitializerWithJSON() {
        let json: NSDictionary = [
            "auto_play": false,
            "loop": true,
            "fill_screen": true,
            "show_controls": false
        ]

        let settings = SwrveVideoSettings(json)

        XCTAssertFalse(settings.autoPlay, "autoPlay should be set to true from JSON")
        XCTAssertTrue(settings.loop, "loop should be set to true from JSON")
        XCTAssertTrue(settings.fillScreen, "fillScreen should be set to true from JSON")
        XCTAssertFalse(settings.showControls, "showControls should be set to false from JSON")
    }

    func testInitializerWithPartialJSON() {
        let json: NSDictionary = [
            "auto_play": false
        ]

        let settings = SwrveVideoSettings(json)

        XCTAssertFalse(settings.autoPlay, "autoPlay should be set to false from JSON")
        XCTAssertTrue(settings.loop, "loop should remain the default value of true")
        XCTAssertFalse(settings.fillScreen, "fillScreen should remain the default value of false")
        XCTAssertTrue(settings.showControls, "showControls should remain the default value of true")
    }
}
