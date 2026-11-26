import UIKit
import XCTest

@testable import SwrveSDK

// Messages on the iPhone Duo's screens, closed and open in both orientations. The campaign has the proportions of a template for phones, foldables and tablets: a 1500x2325 background round a 1000x1550
// safe zone, which fills these screens. The Android SDK's fit screenshot test uses the same campaign.
class SwrveTestIAMFitSnapshots: SwrveIAMSnapshotTestCase {

    func testClosedPortrait() throws {
        // 1398x2034px. Fit 678/1550 = 0.437, so the background is 656x1017pt, cropped on every side
        try checkMessage(size: CGSize(width: 466, height: 678), format: "portrait")
    }

    func testClosedLandscape() throws {
        // 2034x1398px. Fit 678/1550 = 0.437, so the background is 1017x656pt, cropped on every side
        try checkMessage(size: CGSize(width: 678, height: 466), format: "landscape")
    }

    func testOpenPortrait() throws {
        // 2007x2853px. Fit 951/1550 = 0.614, so the background is 920x1426pt, cropped on every side
        try checkMessage(size: CGSize(width: 669, height: 951), format: "portrait")
    }

    func testOpenLandscape() throws {
        // 2853x2007px. Fit 951/1550 = 0.614, so the background is 1426x920pt, cropped on every side
        try checkMessage(size: CGSize(width: 951, height: 669), format: "landscape")
    }

    // The size is in points, drawn at the Duo's scale of 3
    private func checkMessage(size: CGSize, format formatName: String, testName: String = #function) throws {
        let controller = try startMessageController(campaignFile: "campaign_fit") {
            SwrveTestHelper.createDummyAssets(["bc5f1b888921145eb25b37b9bd1fd0cbd3b52a82"], withResourceName: "iam_fit_portrait", ofType: "png")
            SwrveTestHelper.createDummyAssets(["c8891dc537d4b0f36ccb16a34d989047af5b8a6e"], withResourceName: "iam_fit_landscape", ofType: "png")
        }
        let vc = try messageViewController(controller, campaignId: 900)
        let image = capture(try show(vc, size: size))

        // The format for the screen's shape, its safe zone touching two edges and not cropped
        let format = try XCTUnwrap(vc.currentMessageFormat)
        XCTAssertEqual(formatName, format.name)
        let fit = SwrveSDKUtils.renderScale(for: format, withParentSize: size)
        let safeZone = CGSize(width: format.size.width * fit, height: format.size.height * fit)
        XCTAssertLessThanOrEqual(safeZone.width, size.width + 0.01)
        XCTAssertLessThanOrEqual(safeZone.height, size.height + 0.01)
        XCTAssertTrue(abs(safeZone.width - size.width) < 0.01 || abs(safeZone.height - size.height) < 0.01, "safe zone \(safeZone)")

        XCTAssertEqual([0, 0, 0, 0], try transparentStrips(image))  // the background reaches every edge

        checkSnapshot(image, testName: testName)
    }

    // The transparent pixels in from each edge (left, top, right, bottom), where the app would show through, measured along
    // the lines through the centre
    private func transparentStrips(_ image: UIImage) throws -> [Int] {
        let cgImage = try XCTUnwrap(image.cgImage)
        let width = cgImage.width
        let height = cgImage.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let context = try XCTUnwrap(
            CGContext(
                data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        func alpha(_ x: Int, _ y: Int) -> UInt8 { pixels[(y * width + x) * 4 + 3] }
        func count(_ points: [(Int, Int)]) -> Int { points.prefix { alpha($0.0, $0.1) == 0 }.count }
        let centreX = width / 2
        let centreY = height / 2
        return [
            count((0..<width).map { ($0, centreY) }),
            count((0..<height).map { (centreX, $0) }),
            count((0..<width).reversed().map { ($0, centreY) }),
            count((0..<height).reversed().map { (centreX, $0) })
        ]
    }
}
