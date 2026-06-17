import XCTest

@testable import SwrveSDK

/// Fixture-driven conformance tests: run each case through SwrveFreemarkerEvaluator and assert
/// the output matches the expected value produced by the real FreeMarker Java library (2.3.23).
///
/// The fixture file `freemarker_conformance_fixtures.json` is generated on Android by
/// SwrveFreemarkerFixtureGenerator, which writes it directly to this repo when run with:
///
///   GENERATE_FM_FIXTURES=true ./gradlew :SwrveSDKTest:testCoreDebugUnitTest \
///     --tests "com.swrve.sdk.SwrveFreemarkerFixtureGenerator"
///
/// Fixture location: public/SwrveSDKTest/SDKTests/Helpers/freemarker_conformance_fixtures.json
///
/// ## Known divergences from real FreeMarker
///
/// Several intentional SDK divergences are excluded from the fixture file so conformance tests
/// pass. The full list is documented (with `@Ignore` annotations) in the Android equivalent:
/// `SwrveFreemarkerConformanceTest.kt`.
///
/// Notably, date built-ins (`?date`, `?datetime`, `.now`) are an intentional SDK-specific subset
/// and are deliberately excluded from the fixtures: `.now` is non-deterministic wall-clock in
/// stock FreeMarker (so it cannot be a stable golden value) and the SDK's GLOBAL/LOCAL timezone
/// semantics have no FreeMarker equivalent. They are covered by `SwrveTestFreemarkerDatetime`
/// (behaviour) and the timezone_type wiring test in `SwrveTestFreemarkerAssetPipeline`
/// (`testDynamicImageUrlDateConditionUsesCampaignTimezone`).
class SwrveTestFreemarkerConformance: XCTestCase {

    private struct Fixture: Decodable {
        let name: String
        let template: String
        let props: [String: String]
        let expected: String
    }

    private func loadFixtures() throws -> [Fixture] {
        let url = try XCTUnwrap(
            Bundle.main.url(forResource: "freemarker_conformance_fixtures", withExtension: "json"),
            "freemarker_conformance_fixtures.json not found in test bundle"
        )
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([Fixture].self, from: data)
    }

    func testAllConformanceCases() throws {
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
