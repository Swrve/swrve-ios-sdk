import Foundation
import SnapshotTesting
import XCTest

extension XCTestCase {

    func runSnapshot(
        for vc: UIViewController,
        delay: TimeInterval = 0.5,
        height: CGFloat? = nil,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        assertSnapshotAfterDelay(
            for: vc,
            using: .light,
            delay: delay,
            on: .iPhoneX,
            file: file,
            testName: testName + "light",
            line: line,
            height: height
        )

        /*
         // Disable dak mode and enable when dark mode capability is in place
        assertSnapshotAfterDelay(
            for: window,
            using: .dark,
            delay: delay,
            on: device,
            file: file,
            testName: testName + "dark",
            line: line,
            height: height
        ) */
    }

    func assertSnapshotAfterDelay(
        for vc: UIViewController,
        using mode: UIUserInterfaceStyle,
        delay: TimeInterval,
        on device: ViewImageConfig,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line,
        height: CGFloat? = nil,
        record: Bool = false
    ) {

        let expectation = XCTestExpectation(description: "wait")
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            // NOTE: perceptualPrecision: The percentage a pixel must match the source
            // pixel to be considered a match.
            // [98-99% mimics the precision of the human eye.]
            // (http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e)

            withSnapshotTesting(diffTool: .ksdiff) {
                assertSnapshot(
                    of: vc,
                    as: .image(
                        perceptualPrecision: 0.90,
                        size: vc.view.frame.size
                    ),
                    named: "\(device.name)",
                    record: record,
                    file: file,
                    testName: testName,
                    line: line
                )

                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 5)
    }
}

extension ViewImageConfig {

    var name: String {

        guard let size = size else {
            return "no-size"
        }

        switch size {
        case ViewImageConfig.iPhoneX(.portrait).size:
            return "iPhoneX-portrait"
        default:
            return "\(size.width)-\(size.height)"
        }
    }
}
