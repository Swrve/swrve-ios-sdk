import XCTest

@testable import SwrveSDK

class SwrveTestFreemarkerDatetime: XCTestCase {

    private var previousNowProvider: (() -> Date)?

    // Inject a fixed .now so tests are deterministic
    override func setUp() {
        super.setUp()
        previousNowProvider = SwrveFreemarkerEvaluator.nowProvider
        // 2026-04-16T12:00:00Z — noon UTC on April 16
        let fixedNow = makeDate("2026-04-16T12:00:00Z")
        SwrveFreemarkerEvaluator.nowProvider = { fixedNow }
    }

    override func tearDown() {
        SwrveFreemarkerEvaluator.nowProvider = previousNowProvider ?? { Date() }
        previousNowProvider = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeDate(_ iso: String) -> Date {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime]
        guard let date = fmt.date(from: iso) else {
            XCTFail("Invalid ISO 8601 fixture string: \(iso)")
            return Date()
        }
        return date
    }

    private func evaluate(_ template: String, _ props: [String: Any] = [:], local: Bool = false) throws -> String {
        try SwrveFreemarkerEvaluator.evaluate(template, properties: props, useLocalTimezone: local)
    }
}

// MARK: - ?date comparisons

extension SwrveTestFreemarkerDatetime {

    func testDateFutureIsValid() throws {
        let result = try evaluate(
            "<#if Recipient.expiry?date gt .now?date>Valid offer<#else>Expired</#if>",
            ["Recipient.expiry": "2099-01-01T00:00:00Z"]
        )
        XCTAssertEqual(result, "Valid offer")
    }

    func testDatePastIsExpired() throws {
        let result = try evaluate(
            "<#if Recipient.expiry?date gt .now?date>Valid offer<#else>Expired</#if>",
            ["Recipient.expiry": "2020-01-01T00:00:00Z"]
        )
        XCTAssertEqual(result, "Expired")
    }

    func testDateGteEqualDayIsValid() throws {
        // .now = 2026-04-16T12:00:00Z → .now?date = 2026-04-16 (UTC)
        let result = try evaluate(
            "<#if Recipient.expiry?date gte .now?date>Valid<#else>Expired</#if>",
            ["Recipient.expiry": "2026-04-16T00:00:00Z"]
        )
        XCTAssertEqual(result, "Valid")
    }

    func testDateDateOnlyStringAccepted() throws {
        let result = try evaluate(
            "<#if Recipient.expiry?date gt .now?date>Future<#else>Past</#if>",
            ["Recipient.expiry": "2099-01-01"]
        )
        XCTAssertEqual(result, "Future")
    }

    func testDateLtAndLteOperators() throws {
        // lte: expiry on same day as .now → not less than, so lte passes; lt does not
        let ltResult = try evaluate(
            "<#if Recipient.expiry?date lt .now?date>Past<#else>NotPast</#if>",
            ["Recipient.expiry": "2026-04-16T00:00:00Z"]
        )
        XCTAssertEqual(ltResult, "NotPast")

        let lteResult = try evaluate(
            "<#if Recipient.expiry?date lte .now?date>PastOrSame<#else>Future</#if>",
            ["Recipient.expiry": "2026-04-16T00:00:00Z"]
        )
        XCTAssertEqual(lteResult, "PastOrSame")
    }

    func testDateMissingKeySuppresses() {
        XCTAssertThrowsError(
            try evaluate("<#if Recipient.expiry?date gt .now?date>ok</#if>")
        )
    }
}

// MARK: - ?datetime comparisons

extension SwrveTestFreemarkerDatetime {

    func testDatetimeFutureIsActive() throws {
        let result = try evaluate(
            "<#if Recipient.expiry?datetime gt .now>Active<#else>Expired</#if>",
            ["Recipient.expiry": "2099-01-01T00:00:00Z"]
        )
        XCTAssertEqual(result, "Active")
    }

    func testDatetimePastIsExpired() throws {
        let result = try evaluate(
            "<#if Recipient.expiry?datetime gt .now>Active<#else>Expired</#if>",
            ["Recipient.expiry": "2020-01-01T00:00:00Z"]
        )
        XCTAssertEqual(result, "Expired")
    }

    func testDatetimeOnDateOnlyStringSuppresses() {
        XCTAssertThrowsError(
            try evaluate(
                "<#if Recipient.expiry?datetime gt .now>ok</#if>",
                ["Recipient.expiry": "2099-01-01"]
            )
        )
    }

    func testDatetimeMissingKeySuppresses() {
        XCTAssertThrowsError(
            try evaluate("<#if Recipient.expiry?datetime gt .now>ok</#if>")
        )
    }
}

// MARK: - ?datetime?date chain

extension SwrveTestFreemarkerDatetime {

    func testDatetimeDateChainYieldsCalendarDate() throws {
        // ?datetime?date: parse as datetime, strip time — should behave like ?date
        let result = try evaluate(
            "<#if Recipient.expiry?datetime?date gte .now?date>Valid<#else>Expired</#if>",
            ["Recipient.expiry": "2099-01-01T00:00:00Z"]
        )
        XCTAssertEqual(result, "Valid")
    }

    func testDatetimeDateChainOnDateOnlyStringSuppresses() {
        // ?datetime?date requires a full datetime string — date-only suppresses
        XCTAssertThrowsError(
            try evaluate(
                "<#if Recipient.expiry?datetime?date gte .now?date>ok</#if>",
                ["Recipient.expiry": "2099-01-01"]
            )
        )
    }
}

// MARK: - Type mismatch suppression

extension SwrveTestFreemarkerDatetime {

    func testDateVsDatetimeMismatchSuppresses() {
        // ?date (calendarDate) vs .now (?datetime) — type mismatch
        XCTAssertThrowsError(
            try evaluate(
                "<#if Recipient.expiry?date gt .now>ok</#if>",
                ["Recipient.expiry": "2099-01-01T00:00:00Z"]
            )
        )
    }
}

// MARK: - Timezone: GLOBAL vs LOCAL

extension SwrveTestFreemarkerDatetime {

    func testNowDateGlobalUsesUTC() throws {
        // .now = 2026-04-16T12:00:00Z → in UTC, .now?date = 2026-04-16
        // expiry = 2026-04-16 → gte passes
        let result = try evaluate(
            "<#if Recipient.expiry?date gte .now?date>Valid<#else>Expired</#if>",
            ["Recipient.expiry": "2026-04-16T00:00:00Z"],
            local: false
        )
        XCTAssertEqual(result, "Valid")
    }

    func testNowDateLocalUsesDeviceTimezone() throws {
        // setUp fixes .now = 2026-04-16T12:00:00Z. Expiry is far in the future (2099),
        // so gte always holds regardless of what local calendar date .now resolves to.
        // This asserts the LOCAL timezone code path executes correctly and returns "Valid".
        let result = try evaluate(
            "<#if Recipient.expiry?date gte .now?date>Valid<#else>Expired</#if>",
            ["Recipient.expiry": "2099-12-31T00:00:00Z"],
            local: true
        )
        XCTAssertEqual(result, "Valid")
    }

    func testNowDateGlobalMidnightBoundary() throws {
        // .now = 2026-04-16T23:30:00Z → in UTC, date is April 16
        SwrveFreemarkerEvaluator.nowProvider = { self.makeDate("2026-04-16T23:30:00Z") }
        let result = try evaluate(
            "<#if Recipient.expiry?date gte .now?date>Valid<#else>Expired</#if>",
            ["Recipient.expiry": "2026-04-16T00:00:00Z"],
            local: false
        )
        XCTAssertEqual(result, "Valid")
    }

    func testNonDateValueContainingTGivesDateError() {
        // E-5 regression: "NOT SET" contains uppercase T; before fix it was routed through datetime
        // parser and gave a confusing "ISO 8601 datetime" error. After fix it gives a date error.
        XCTAssertThrowsError(
            try evaluate(
                "<#if Recipient.expiry?date gt .now?date>Valid</#if>",
                ["Recipient.expiry": "NOT SET"],
                local: false
            )
        ) { error in
            XCTAssertFalse(
                error.localizedDescription.contains("ISO 8601 datetime"),
                "Error should not mention 'datetime' for a ?date built-in on a non-date value")
        }
    }

    func testDateVsDatetimeMismatchCaughtAtParseTime() {
        // E-4: mismatch between ?date and ?datetime now detected at parse time
        XCTAssertThrowsError(
            try evaluate(
                "<#if Recipient.expiry?date gt .now>Valid</#if>",
                ["Recipient.expiry": "2099-01-01T00:00:00Z"],
                local: false
            )
        ) { error in
            XCTAssertTrue(error.localizedDescription.contains("mismatch") || error.localizedDescription.contains("mix"))
        }
    }

    func testDateVsBareNowTypeMismatchErrorMessage() {
        // Bare .now is a datetime; comparing against ?date without .now?date is a type mismatch.
        // The error message should guide the developer to use .now?date instead.
        XCTAssertThrowsError(
            try evaluate(
                "<#if Recipient.expiry?date gt .now>Valid</#if>",
                ["Recipient.expiry": "2026-04-16T00:00:00Z"],
                local: false
            )
        ) { error in
            XCTAssertTrue(error.localizedDescription.contains(".now?date"))
        }
    }
}
