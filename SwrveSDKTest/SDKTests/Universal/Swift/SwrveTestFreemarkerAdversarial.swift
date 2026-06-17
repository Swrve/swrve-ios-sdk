import XCTest

@testable import SwrveSDK

/// Fixture-driven adversarial conformance tests: run each case through SwrveFreemarkerEvaluator
/// and assert the output matches the expected value produced by the real FreeMarker Java library
/// (2.3.23).
///
/// The fixture file `freemarker_adversarial_fixtures.json` is generated on Android by
/// SwrveFreemarkerAdversarialFixtureGenerator, which writes it directly to this repo when run with:
///
///   GENERATE_FM_ADVERSARIAL_FIXTURES=true ./gradlew :SwrveSDKTest:testCoreDebugUnitTest \
///     --tests "com.swrve.sdk.SwrveFreemarkerAdversarialFixtureGenerator"
///
/// Fixture location: public/SwrveSDKTest/SDKTests/Helpers/freemarker_adversarial_fixtures.json
///
/// These cases are combinatorial stress tests covering every built-in × context × chain
/// combination. Cases where both SDK and FreeMarker throw (assertBothSuppress) or where they
/// disagree (assertDiverges) are excluded from the fixture and tested inline on Android in
/// SwrveFreemarkerAdversarialTest.
class SwrveTestFreemarkerAdversarial: XCTestCase {

    private struct Fixture: Decodable {
        let name: String
        let template: String
        let props: [String: String]
        let expected: String
    }

    private func loadFixtures() throws -> [Fixture] {
        let url = try XCTUnwrap(
            Bundle.main.url(forResource: "freemarker_adversarial_fixtures", withExtension: "json"),
            "freemarker_adversarial_fixtures.json not found in test bundle"
        )
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([Fixture].self, from: data)
    }

    func testAllAdversarialCases() throws {
        let fixtures = try loadFixtures()
        XCTAssertGreaterThan(fixtures.count, 0, "Fixture file is empty")

        var failures: [String] = []
        for fixture in fixtures {
            do {
                let result = try SwrveFreemarkerEvaluator.evaluate(fixture.template, properties: fixture.props as [String: Any])
                if result != fixture.expected {
                    failures.append("\(fixture.name): expected '\(fixture.expected)' got '\(result)'")
                }
            } catch {
                failures.append("\(fixture.name): threw error — \(error)")
            }
        }

        if !failures.isEmpty {
            XCTFail("\(failures.count) fixture(s) failed:\n" + failures.joined(separator: "\n"))
        }
    }
}
