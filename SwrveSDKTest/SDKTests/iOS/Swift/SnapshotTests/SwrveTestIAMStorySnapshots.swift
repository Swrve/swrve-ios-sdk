import UIKit
import XCTest

@testable import SwrveSDK

// A story on page 2 of 3 with its progress bar half full: https://dashboard.swrve.com/apps/32032/campaigns/749307, as the
// server sent it for this screen, with a trigger and each page's page_duration added by hand. Android's story test uses it too.
class SwrveTestIAMStorySnapshots: SwrveIAMSnapshotTestCase {

    override func setUpWithError() throws {
        try skipOnIPad()
    }

    func testStory() throws {
        let controller = try startMessageController(campaignFile: "campaign_screenshot_story") {
            copyResources([
                "2a7a896f0a5178e3d451af70bb7a664f563fa68f", "f8225a53ae23c7565c0c2c73675a45c8877dca8c",
                "6a5b7ac575cd2206c54661313170c3b7861e690e", Self.font, Self.buttonImage, Self.buttonImagePressed
            ])
        }
        let vc = try messageViewController(controller, campaignId: 749307)
        let window = try show(vc, size: Self.phone)

        // The bar's timer only fires when the run loop runs, so it stays still while the test moves the story on, as the bar
        // does when page 1 ends
        let storyView = try XCTUnwrap(vc.storyView)
        storyView.stop()
        vc.segmentFinished(at: 0)
        storyView.startSegment(atIndex: 1)
        storyView.stop()
        XCTAssertEqual(917504, (vc.viewControllers?.first as? SwrveMessagePageViewController)?.pageId)
        XCTAssertEqual(1, storyView.currentIndex)

        // Fill page 2's segment to half its track with the bar's own ticks
        let track = try XCTUnwrap(storyView.subviews.dropFirst().first)
        let segment = try XCTUnwrap(track.subviews.first)
        for _ in 0..<100_000 where segment.frame.width < track.bounds.width / 2 {
            storyView.perform(NSSelectorFromString("animateSegmentTick"))
        }
        XCTAssertEqual(track.bounds.width / 2, segment.frame.width, accuracy: 1)
        XCTAssertEqual(1, storyView.currentIndex)

        checkSnapshot(capture(window), testName: #function)
    }
}
