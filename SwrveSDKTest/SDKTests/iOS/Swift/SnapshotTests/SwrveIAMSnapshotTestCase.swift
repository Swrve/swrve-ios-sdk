import SnapshotTesting
import UIKit
import XCTest

@testable import SwrveSDK

// Shared setup for the in-app message snapshot tests: each message is shown in its own key window, as the SDK shows it,
// drawn at 3x and compared with __Snapshots__. Every snapshot is attached, so the test report shows them all.
class SwrveIAMSnapshotTestCase: XCTestCase {

    // The standard screen for the tests of message elements: an iPhone 17, 402x874pt
    static let phone = CGSize(width: 402, height: 874)

    // Assets the dashboard campaigns share, named as the CDN names them
    static let background = "57a40d228c6f3530361a4558b53f50cfcc5c8cae"
    static let font = "535.32032.3d0b9eb17e645ac34f83c49c3f988372b242173a.ttf"  // Pacifico. SIL Open Font License, see Pacifico-OFL.txt
    static let buttonImage = "ae22d321d98bf420693d766cc0d52aec70fdeff3"
    static let buttonImagePressed = "b9223ad2346bc79d5d73b2921a7a241907c1fadb"

    override class func setUp() {
        SwrveTestHelper.setUp()
        UIView.setAnimationsEnabled(false)
    }

    override class func tearDown() {
        SwrveTestHelper.tearDown()
    }

    // For tests recorded on an iPhone: an iPad's safe area, which the story bar follows, and its text rendering both differ
    func skipOnIPad() throws {
        try XCTSkipIf(UIDevice.current.userInterfaceIdiom == .pad, "The references are recorded on an iPhone")
    }

    // Starts the SDK and loads the campaigns in the file. copyAssets runs in between, once the SDK has created its cache
    // folder and before the campaigns load, so the SDK finds the assets there instead of downloading them.
    func startMessageController(campaignFile: String, copyAssets: () -> Void) throws -> SwrveMessageController {
        SwrveSDK.sharedInstance(withAppID: 123, apiKey: "key", config: SwrveConfig())
        let swrve = try XCTUnwrap(SwrveSDK.sharedInstance as? Swrve)
        let controller = try XCTUnwrap(swrve.messaging)
        copyAssets()
        let campaigns = try XCTUnwrap(getMockDataAsDictionary(fileName: campaignFile))
        controller.updateCampaigns(campaigns, withLoadingPreviousCampaignState: false, notifyCampaignsUpdated: false)
        return controller
    }

    // Copies each resource into the SDK's cache under the same name
    func copyResources(_ files: [String]) {
        for file in files {
            let url = URL(fileURLWithPath: file)
            let type = url.pathExtension.isEmpty ? nil : url.pathExtension
            SwrveTestHelper.createDummyAssets([file], withResourceName: url.deletingPathExtension().lastPathComponent, ofType: type)
        }
    }

    func messageViewController(_ controller: SwrveMessageController, campaignId: Int) throws -> SwrveMessageViewController {
        let campaign = try XCTUnwrap(controller.campaigns.compactMap { $0 as? SwrveInAppCampaign }.first { $0.ID == campaignId })
        return SwrveMessageViewController(messageController: controller, message: try XCTUnwrap(campaign.message), personalization: [:])
    }

    // Shows the controller in a window of the size, made key before the controller goes in, as the controller fits the
    // message to the key window when its view loads
    func show(_ vc: UIViewController, size: CGSize) throws -> UIWindow {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previousKeyWindow = scene.windows.first { $0.isKeyWindow }
        // Setting rootViewController reconciles the window's geometry with the scene's orientation, and from iOS 27.2 that
        // snaps a window sized as the screen turned sideways back to portrait. So rotate the scene before the window is built.
        if size.width > size.height {
            rotate(scene, to: .landscapeRight)
            addTeardownBlock { self.rotate(scene, to: .portrait) }
        }
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(origin: .zero, size: size)
        // Text is drawn at the display's scale, so match the capture's
        if #available(iOS 17.0, *) {
            window.traitOverrides.displayScale = 3
        }
        window.makeKeyAndVisible()
        addTeardownBlock {
            window.isHidden = true
            previousKeyWindow?.makeKey()
        }
        window.rootViewController = vc
        window.layoutIfNeeded()
        XCTAssertEqual(size, window.bounds.size, "The window was resized, so the message was fitted to a different size")
        return window
    }

    // Turns the scene, waiting for it to report the orientation, so a window of that shape is not reconciled away. Some
    // windowing modes refuse a programmatic rotation, the iPad's among them. That is not a failure: there the window keeps
    // the size it was given, and the assert in show() is what checks that. Stop waiting on a refusal, as the turn never comes.
    private func rotate(_ scene: UIWindowScene, to orientation: UIInterfaceOrientationMask) {
        guard #available(iOS 16.0, *) else { return }
        let refused = Refused()
        scene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation)) { _ in refused.value = true }
        let wantsLandscape = orientation == .landscapeRight
        let turned = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in refused.value || scene.interfaceOrientation.isLandscape == wantsLandscape },
            object: nil)
        _ = XCTWaiter().wait(for: [turned], timeout: 10)
    }

    // The error handler and the predicate run on different queues, so the flag needs a reference type rather than a captured var
    private final class Refused {
        var value = false
    }

    func capture(_ window: UIWindow) -> UIImage {
        window.layoutIfNeeded()
        let format = UIGraphicsImageRendererFormat()
        format.scale = 3
        format.opaque = false
        return UIGraphicsImageRenderer(size: window.bounds.size, format: format).image { context in
            window.layer.render(in: context.cgContext)
        }
    }

    // Attaches the image to the results and compares it with its reference
    func checkSnapshot(_ image: UIImage, testName: String, file: StaticString = #filePath, line: UInt = #line) {
        let attachment = XCTAttachment(image: image)
        attachment.name = testName
        attachment.lifetime = .keepAlways
        add(attachment)
        assertSnapshot(of: image, as: .image(precision: 0.99, perceptualPrecision: 0.98), file: file, testName: testName, line: line)
    }

    // The message's elements in the order the message view draws them
    func elements(of vc: SwrveMessageViewController) throws -> [UIView] {
        func find(_ view: UIView) -> SwrveMessageUIView? {
            if let messageView = view as? SwrveMessageUIView { return messageView }
            return view.subviews.lazy.compactMap(find).first
        }
        return try XCTUnwrap(find(vc.view)).subviews
    }
}
