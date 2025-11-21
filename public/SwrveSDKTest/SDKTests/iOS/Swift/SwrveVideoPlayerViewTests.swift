import AVFoundation
import AVKit
import XCTest

@testable import SwrveSDK

class MockSwrveVideoPlayerViewDelegate: NSObject, SwrveVideoPlayerViewDelegate {
    let didStart: XCTestExpectation?
    let didFinish: XCTestExpectation?
    init(didStart: XCTestExpectation? = nil, didFinish: XCTestExpectation? = nil) {
        self.didStart = didStart
        self.didFinish = didFinish
    }
    func videoDidStartPlaying() {
        didStart?.fulfill()
    }
    func videoDidFinishPlaying() {
        didFinish?.fulfill()
    }
}

class SwrveVideoPlayerViewTests: XCTestCase {

    var videoPlayerView: SwrveVideoPlayerView!
    var dummyViewController: UIViewController!
    var testVideoURL: URL!

    override func setUp() {
        super.setUp()
        dummyViewController = UIViewController()
        guard let path = Bundle.main.path(forResource: "SampleVideo", ofType: "mp4") else {
            XCTFail("SampleVideo.mp4 not found in test bundle")
            return
        }
        testVideoURL = URL(fileURLWithPath: path)
    }

    override func tearDown() {
        videoPlayerView?.cleanupPlayer()
        videoPlayerView = nil
        dummyViewController = nil
        testVideoURL = nil
        super.tearDown()
    }

    func testPlayerInitializesAndStartsIfAutoPlayIsOn() {
        let settings = SwrveVideoSettings()
        settings.autoPlay = true
        videoPlayerView = SwrveVideoPlayerView(
            frame: .init(x: 0, y: 0, width: 320, height: 180),
            videoSettings: settings,
            videoURL: testVideoURL,
            controller: dummyViewController,
            delegate: nil
        )

        XCTAssertNotNil(videoPlayerView.player)
        XCTAssertNotNil(videoPlayerView.playerViewController)
        XCTAssertEqual((videoPlayerView.player?.currentItem?.asset as? AVURLAsset)?.url, testVideoURL)
    }

    func testPauseFunctionality() {
        let settings = SwrveVideoSettings()
        settings.autoPlay = true
        videoPlayerView = SwrveVideoPlayerView(
            frame: .zero,
            videoSettings: settings,
            videoURL: testVideoURL,
            controller: dummyViewController,
            delegate: nil
        )

        videoPlayerView.pause()
        XCTAssertEqual(videoPlayerView.player?.timeControlStatus, .paused)
    }

    func testCleanupReleasesResources() {
        let settings = SwrveVideoSettings()
        videoPlayerView = SwrveVideoPlayerView(
            frame: .zero,
            videoSettings: settings,
            videoURL: testVideoURL,
            controller: dummyViewController,
            delegate: nil
        )

        videoPlayerView.cleanupPlayer()

        XCTAssertNil(videoPlayerView.player)
        XCTAssertNil(videoPlayerView.playerViewController)
        XCTAssertTrue(videoPlayerView.subviews.isEmpty)
    }

    func testLoopingRestartsVideo() {
        let settings = SwrveVideoSettings()
        settings.loop = true
        videoPlayerView = SwrveVideoPlayerView(
            frame: .zero,
            videoSettings: settings,
            videoURL: testVideoURL,
            controller: dummyViewController,
            delegate: nil

        )

        let expectation = self.expectation(description: "Looping playback")

        //sample vid is 5 seconds long, so we wait for 4.9 seconds to check if it loops
        videoPlayerView.player?.seek(to: CMTime(seconds: 4.9, preferredTimescale: 600)) { _ in
            self.videoPlayerView.videoFinishedPlaying()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                guard let currentTimeSeconds = self.videoPlayerView.player?.currentTime().seconds else {
                    XCTFail("Failed to get currentTime from player")
                    expectation.fulfill()
                    return
                }
                XCTAssertLessThan(currentTimeSeconds, 4.9, "Expected currentTime to be less than 4.9 after looping, got \(currentTimeSeconds)")
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 2)
    }

    func testSettingsAffectBehavior() {
        let settings = SwrveVideoSettings()
        settings.fillScreen = true
        settings.showControls = false
        videoPlayerView = SwrveVideoPlayerView(
            frame: .zero,
            videoSettings: settings,
            videoURL: testVideoURL,
            controller: dummyViewController,
            delegate: nil

        )

        XCTAssertEqual(videoPlayerView.playerViewController?.showsPlaybackControls, false)
        XCTAssertEqual(videoPlayerView.playerViewController?.videoGravity, .resizeAspectFill)
        XCTAssertEqual(videoPlayerView.frame.size.width, UIScreen.main.bounds.width)
    }

    func testDelegateIsCalled() {
        let settings = SwrveVideoSettings()
        settings.autoPlay = true

        let startCalled = expectation(description: "start should be called")
        let finishCalled = expectation(description: "finish should be called")
        let mockDelegate = MockSwrveVideoPlayerViewDelegate(didStart: startCalled, didFinish: finishCalled)

        videoPlayerView = SwrveVideoPlayerView(
            frame: .init(x: 0, y: 0, width: 320, height: 180),
            videoSettings: settings,
            videoURL: testVideoURL,
            controller: dummyViewController,
            delegate: mockDelegate

        )

        // Simulate finish
        videoPlayerView.videoFinishedPlaying()

        wait(for: [startCalled, finishCalled], timeout: 0.5)
    }

    func testNoStartCallback_WhenAutoplayFalse_AndNoPlayCalled() {
        let settings = SwrveVideoSettings()
        settings.autoPlay = false

        let startNotCalled = expectation(description: "start should NOT be called")
        startNotCalled.isInverted = true

        let mockDelegate = MockSwrveVideoPlayerViewDelegate(didStart: startNotCalled)

        _ = SwrveVideoPlayerView(
            frame: .init(x: 0, y: 0, width: 320, height: 180),
            videoSettings: settings,
            videoURL: testVideoURL,
            controller: dummyViewController,
            delegate: mockDelegate
        )
        wait(for: [startNotCalled], timeout: 0.5)
    }

}
