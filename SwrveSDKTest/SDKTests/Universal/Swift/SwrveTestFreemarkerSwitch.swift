import XCTest

@testable import SwrveSDK

// MARK: - <#switch> / <#case> / <#default> / <#break> and newline stripping

class SwrveTestFreemarkerSwitch: XCTestCase {

    // MARK: - <#switch> / <#case> / <#default> / <#break>

    func testSwitchMatchesFirstCase() throws {
        let template = #"<#switch Recipient.country><#case "US">US message<#break><#case "UK">UK message<#break><#default>Default message</#switch>"#
        let result = try SwrveFreemarkerEvaluator.evaluate(template, properties: ["Recipient.country": "US"])
        XCTAssertEqual(result, "US message")
    }

    func testSwitchMatchesMiddleCase() throws {
        let template = #"<#switch Recipient.country><#case "US">US message<#break><#case "UK">UK message<#break><#default>Default message</#switch>"#
        let result = try SwrveFreemarkerEvaluator.evaluate(template, properties: ["Recipient.country": "UK"])
        XCTAssertEqual(result, "UK message")
    }

    func testSwitchNoMatchFallsToDefault() throws {
        let template = #"<#switch Recipient.country><#case "US">US message<#break><#case "UK">UK message<#break><#default>Default message</#switch>"#
        let result = try SwrveFreemarkerEvaluator.evaluate(template, properties: ["Recipient.country": "CA"])
        XCTAssertEqual(result, "Default message")
    }

    func testSwitchMissingVariableSuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                #"<#switch Recipient.country><#case "US">US message<#break><#default>Default message</#switch>"#,
                properties: [:]
            )
        ) { error in
            XCTAssertTrue(error.localizedDescription.contains("Recipient.country"), "Error should name the missing key")
        }
    }

    func testSwitchNoCasesReturnsEmpty() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#switch Recipient.country></#switch>",
            properties: ["Recipient.country": "US"]
        )
        XCTAssertEqual(result, "")
    }

    func testSwitchNoMatchNoDefaultReturnsEmpty() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#switch Recipient.country><#case "US">US message<#break></#switch>"#,
            properties: ["Recipient.country": "CA"]
        )
        XCTAssertEqual(result, "")
    }

    func testSwitchFallThroughWithoutBreak() throws {
        // Case "a" has no <#break>, so execution falls through into case "b"
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#switch Recipient.x><#case "a">A<#case "b">B<#break><#default>D</#switch>"#,
            properties: ["Recipient.x": "a"]
        )
        XCTAssertEqual(result, "AB")
    }

    func testSwitchFallThroughIntoDefault() throws {
        // Last case has no <#break>, so execution falls through into <#default>
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#switch Recipient.x><#case "a">A<#default>D</#switch>"#,
            properties: ["Recipient.x": "a"]
        )
        XCTAssertEqual(result, "AD")
    }

    func testSwitchUnclosedSuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                #"<#switch Recipient.x><#case "a">text"#,
                properties: ["Recipient.x": "a"]
            ))
    }

    func testSwitchDuplicateDefaultSuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                "<#switch Recipient.x><#default>D1<#default>D2</#switch>",
                properties: [:]
            ))
    }

    func testSwitchCaseAfterDefaultSuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                #"<#switch Recipient.x><#default>D<#case "a">A<#break></#switch>"#,
                properties: ["Recipient.x": "a"]
            ))
    }

    func testSwitchNonWhitespaceTextBetweenDirectivesSuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                #"<#switch Recipient.x>oops<#case "a">A<#break></#switch>"#,
                properties: ["Recipient.x": "a"]
            ))
    }

    func testSwitchBreakInsideNestedIfSuppresses() {
        // <#break> directly inside <#if> within a <#case> is not supported
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                #"<#switch Recipient.x><#case "a"><#if Recipient.y == "b">text<#break></#if></#switch>"#,
                properties: ["Recipient.x": "a", "Recipient.y": "b"]
            )
        ) { error in
            XCTAssertTrue(error.localizedDescription.contains("<#break>"))
        }
    }

    func testSwitchWhitespaceBetweenDirectivesAllowed() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#switch Recipient.x>\#n  <#case "a">A<#break>\#n</#switch>"#,
            properties: ["Recipient.x": "a"]
        )
        XCTAssertEqual(result, "A")
    }

    // MARK: - Newline stripping after switch directive tags

    func testSwitchEndTagNewlineNotStrippedWhenInline() throws {
        // </#switch> is mid-line (after "Other") — trailing \n is kept, matching FreeMarker behaviour
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#switch Recipient.tier>\n<#case \"gold\">\nGold<#break>\n<#default>\nOther</#switch>\n",
            properties: ["Recipient.tier": "gold"]
        )
        XCTAssertEqual(result, "Gold\n")
    }

    func testDefaultDirectiveNewlineStripped() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#switch Recipient.tier>\n<#case \"gold\">\nGold<#break>\n<#default>\nOther</#switch>",
            properties: ["Recipient.tier": "bronze"]
        )
        XCTAssertEqual(result, "Other")
    }

    // MARK: - Switch expression edge cases

    func testSwitchDefaultOperatorKeyAbsentMatchesCase() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#switch Recipient.tier!\"free\"><#case \"free\">Free<#break><#case \"pro\">Pro<#break></#switch>",
            properties: [:]
        )
        XCTAssertEqual(result, "Free")
    }

    // MARK: - String transforms on switch expression

    func testSwitchUpperCaseTransformMatches() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#switch Recipient.country?upper_case><#case "US">United States<#break><#default>Other</#switch>"#,
            properties: ["Recipient.country": "us"]
        )
        XCTAssertEqual(result, "United States")
    }

    func testSwitchLowerCaseTransformMatches() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#switch Recipient.tier?lower_case><#case "gold">Gold<#break><#default>Other</#switch>"#,
            properties: ["Recipient.tier": "GOLD"]
        )
        XCTAssertEqual(result, "Gold")
    }

    func testSwitchTrimLowerCaseChainMatches() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#switch Recipient.tier?trim?lower_case><#case "gold">Gold<#break><#default>Other</#switch>"#,
            properties: ["Recipient.tier": "  GOLD  "]
        )
        XCTAssertEqual(result, "Gold")
    }

}
