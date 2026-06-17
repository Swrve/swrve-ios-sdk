import XCTest

@testable import SwrveSDK

// MARK: - ( ) grouping and + string concatenation

class SwrveTestFreemarkerGroupingConcat: XCTestCase {

    // MARK: - Parenthesis grouping

    func testParenGroupingStripsOuterParens() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if (Recipient.tier == "gold")>Gold</#if>"#,
            properties: ["Recipient.tier": "gold"]
        )
        XCTAssertEqual(result, "Gold")
    }

    func testNestedParensStripped() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if ((Recipient.tier == "gold"))>Gold</#if>"#,
            properties: ["Recipient.tier": "gold"]
        )
        XCTAssertEqual(result, "Gold")
    }

    func testParenGroupingChangesOperatorPrecedence() throws {
        // (a || b) && c — outer && is false when region != US, even though a is true
        let template =
            #"<#if (Recipient.loyalty_points?number gt 1000 || Recipient.account_status == "active") && Recipient.region == "US">Match</#if>"#
        let noMatch = try SwrveFreemarkerEvaluator.evaluate(
            template,
            properties: [
                "Recipient.loyalty_points": "1200",
                "Recipient.account_status": "inactive",
                "Recipient.region": "CA"
            ]
        )
        XCTAssertEqual(noMatch, "")
        let match = try SwrveFreemarkerEvaluator.evaluate(
            template,
            properties: [
                "Recipient.loyalty_points": "1200",
                "Recipient.account_status": "inactive",
                "Recipient.region": "US"
            ]
        )
        XCTAssertEqual(match, "Match")
    }

    func testParenGroupingOrBeforeAnd() throws {
        // (a || b) && c: x="a" satisfies the group but y="no" fails the outer && → ""
        let withGrouping = #"<#if (Recipient.x == "a" || Recipient.x == "b") && Recipient.y == "yes">Hit</#if>"#
        let result = try SwrveFreemarkerEvaluator.evaluate(
            withGrouping,
            properties: ["Recipient.x": "a", "Recipient.y": "no"]
        )
        XCTAssertEqual(result, "")
        // Without parens, a || (b && c): x="a" short-circuits OR to true regardless of y → "Hit"
        let withoutGrouping = #"<#if Recipient.x == "a" || Recipient.x == "b" && Recipient.y == "yes">Hit</#if>"#
        let result2 = try SwrveFreemarkerEvaluator.evaluate(
            withoutGrouping,
            properties: ["Recipient.x": "a", "Recipient.y": "no"]
        )
        XCTAssertEqual(result2, "Hit")
    }

    // MARK: - String concatenation

    func testConcatLiteralsAndVariables() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"${"Hi " + Recipient.first_name + ", you have " + Recipient.loyalty_points + " points"}"#,
            properties: ["Recipient.first_name": "John", "Recipient.loyalty_points": "1200"]
        )
        XCTAssertEqual(result, "Hi John, you have 1200 points")
    }

    func testConcatLiteralOnly() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"${"Hello" + " World"}"#,
            properties: [:]
        )
        XCTAssertEqual(result, "Hello World")
    }

    func testConcatMissingKeySuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                #"${"Hello " + Recipient.missing}"#,
                properties: [:]
            )
        ) { error in
            XCTAssertTrue(error.localizedDescription.contains("Recipient.missing"))
        }
    }

    func testConcatTrimLeadingPart() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"${Recipient.first_name?trim + " world"}"#,
            properties: ["Recipient.first_name": "  Alice  "]
        )
        XCTAssertEqual(result, "Alice world")
    }

    func testConcatTrimMiddlePart() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"${"Hello " + Recipient.first_name?trim + "!"}"#,
            properties: ["Recipient.first_name": "  Bob  "]
        )
        XCTAssertEqual(result, "Hello Bob!")
    }

    func testConcatTrimPreservesOtherWhitespace() throws {
        // Only the targeted variable is trimmed; literals and untrimmed variables are unchanged
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"${"prefix: " + Recipient.first_name?trim + Recipient.last_name}"#,
            properties: ["Recipient.first_name": "  Alice  ", "Recipient.last_name": " Smith"]
        )
        XCTAssertEqual(result, "prefix: Alice Smith")
    }

    func testConcatTrimTrailingPart() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"${"prefix: " + Recipient.first_name?trim}"#,
            properties: ["Recipient.first_name": "  Carol  "]
        )
        XCTAssertEqual(result, "prefix: Carol")
    }

    func testConcatTrimMissingKeySuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                #"${"Hello " + Recipient.missing?trim}"#,
                properties: [:]
            )
        ) { error in
            XCTAssertTrue(error.localizedDescription.contains("Recipient.missing"))
        }
    }

    // MARK: - Quoted LHS and paren-aware operator search

    func testQuotedLHSInEqualitySuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                #"<#if "gold" == Recipient.tier>yes</#if>"#,
                properties: ["Recipient.tier": "gold"]
            )
        ) { error in
            XCTAssertTrue(error.localizedDescription.contains("left-hand side"))
        }
    }

    func testParenWrappedVariableInNotEquals() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if (Recipient.tier) != "gold">other<#else>gold</#if>"#,
            properties: ["Recipient.tier": "gold"]
        )
        XCTAssertEqual(result, "gold")
    }

    func testEqualityInsideParensDoesNotConfuseOuterNotEquals() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                #"<#if (Recipient.a == "b") != "c">yes</#if>"#,
                properties: ["Recipient.a": "b"]
            )
        ) { error in
            XCTAssertFalse(error.localizedDescription.contains("string literal"))
        }
    }

    func testConcatUpperCaseTransform() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"${Recipient.x?upper_case + " world"}"#,
            properties: ["Recipient.x": "hello"]
        )
        XCTAssertEqual(result, "HELLO world")
    }

    func testConcatLowerCaseTransform() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"${"Prefix: " + Recipient.name?lower_case}"#,
            properties: ["Recipient.name": "ALICE"]
        )
        XCTAssertEqual(result, "Prefix: alice")
    }

    func testConcatDefaultOperatorSuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                #"${"Hello " + Recipient.name!"fallback"}"#,
                properties: [:]
            )
        ) { error in
            XCTAssertTrue(error.localizedDescription.contains("'!'"))
        }
    }

    func testConcatUnsupportedBuiltinSuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                #"${Recipient.x?boolean + " world"}"#,
                properties: ["Recipient.x": "true"]
            )
        ) { error in
            XCTAssertTrue(error.localizedDescription.contains("Only ?trim, ?lower_case, and ?upper_case are supported"))
        }
    }
}
