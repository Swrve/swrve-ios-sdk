import XCTest

@testable import SwrveSDK

class SwrveTestFreemarkerEvaluator: XCTestCase {

    // MARK: - ${Recipient.x} interpolation

    func testSimpleInterpolation() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate("Hello ${Recipient.firstName}!", properties: ["Recipient.firstName": "Joe"])
        XCTAssertEqual(result, "Hello Joe!")
    }

    func testInterpolationMissingKeySuppresses() {
        XCTAssertThrowsError(try SwrveFreemarkerEvaluator.evaluate("Hello ${Recipient.firstName}", properties: [:]))
    }

    // MARK: - Default value operator !

    func testDefaultValueKeyPresent() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(#"Hello ${Recipient.firstName!"there"}"#, properties: ["Recipient.firstName": "Joe"])
        XCTAssertEqual(result, "Hello Joe")
    }

    func testDefaultValueKeyMissing() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(#"Hello ${Recipient.firstName!"there"}"#, properties: [:])
        XCTAssertEqual(result, "Hello there")
    }

    func testDefaultValueDoesNotTriggerOnEmptyString() throws {
        // ! only triggers on missing key, not empty string
        let result = try SwrveFreemarkerEvaluator.evaluate(#"${Recipient.name!"fallback"}"#, properties: ["Recipient.name": ""])
        XCTAssertEqual(result, "")
    }

    func testDefaultValueNonStringLiteralSuppresses() {
        // ${Recipient.count!0} — numeric default not supported
        XCTAssertThrowsError(try SwrveFreemarkerEvaluator.evaluate("${Recipient.count!0}", properties: [:]))
    }

    // MARK: - Single-quoted default value

    func testDefaultValueSingleQuotedKeyMissing() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate("Hello ${Recipient.firstName!'there'}", properties: [:])
        XCTAssertEqual(result, "Hello there")
    }

    func testDefaultValueSingleQuotedKeyPresent() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate("Hello ${Recipient.firstName!'there'}", properties: ["Recipient.firstName": "Joe"])
        XCTAssertEqual(result, "Hello Joe")
    }

    // MARK: - Numeric equality

    func testNumericEqualsMatch() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.points?number == 10>yes<#else>no</#if>",
            properties: ["Recipient.points": "10"]
        )
        XCTAssertEqual(result, "yes")
    }

    func testNumericEqualsNoMatch() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.points?number == 10>yes<#else>no</#if>",
            properties: ["Recipient.points": "5"]
        )
        XCTAssertEqual(result, "no")
    }

    func testNumericNotEqualsMatch() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.points?number != 0>yes<#else>no</#if>",
            properties: ["Recipient.points": "10"]
        )
        XCTAssertEqual(result, "yes")
    }

    func testNumericEqualsFloat() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.score?number == 9.5>yes<#else>no</#if>",
            properties: ["Recipient.score": "9.5"]
        )
        XCTAssertEqual(result, "yes")
    }

    func testNumericEqualsWithTrimTransform() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.points?trim?number == 10>yes<#else>no</#if>",
            properties: ["Recipient.points": "  10  "]
        )
        XCTAssertEqual(result, "yes")
    }

    func testNumericEqualsWithQuotedRHSSuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                #"<#if Recipient.points?number == "10">yes</#if>"#,
                properties: ["Recipient.points": "10"]
            )
        )
    }

    func testNumericNaNAsRHSLiteralSuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                "<#if Recipient.score?number == NaN>bad</#if>",
                properties: ["Recipient.score": "42"]
            )
        ) { error in
            XCTAssertTrue(error.localizedDescription.contains("finite"))
        }
    }

    func testNumericInfinityAsRHSLiteralSuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                "<#if Recipient.score?number gt Infinity>bad</#if>",
                properties: ["Recipient.score": "42"]
            )
        ) { error in
            XCTAssertTrue(error.localizedDescription.contains("finite"))
        }
    }

    func testNumericNaNSuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                "<#if Recipient.score?number == 0>yes</#if>",
                properties: ["Recipient.score": "nan"]
            )
        ) { error in
            XCTAssertTrue(error.localizedDescription.contains("finite"))
        }
    }

    func testNumericInfinitySuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                "<#if Recipient.score?number gt 0>yes</#if>",
                properties: ["Recipient.score": "inf"]
            )
        ) { error in
            XCTAssertTrue(error.localizedDescription.contains("finite"))
        }
    }

    // MARK: - Numeric comparisons

    func testNumericGt() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.balance?number gt 100>Eligible<#else>Not eligible</#if>",
            properties: ["Recipient.balance": "150"]
        )
        XCTAssertEqual(result, "Eligible")
    }

    func testNumericGte() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.balance?number gte 100>Eligible<#else>Not eligible</#if>",
            properties: ["Recipient.balance": "100"]
        )
        XCTAssertEqual(result, "Eligible")
    }

    func testNumericLt() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.balance?number lt 100>Low<#else>OK</#if>",
            properties: ["Recipient.balance": "50"]
        )
        XCTAssertEqual(result, "Low")
    }

    func testNumericLte() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.balance?number lte 100>C</#if>",
            properties: ["Recipient.balance": "100"]
        )
        XCTAssertEqual(result, "C")
    }

    func testNumericGtBoundaryExcludes() throws {
        // gt 100 with exactly 100 — should not match
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.balance?number gt 100>A</#if>",
            properties: ["Recipient.balance": "100"]
        )
        XCTAssertEqual(result, "")
    }

    func testNumericLtBoundaryExcludes() throws {
        // lt 100 with exactly 100 — should not match
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.balance?number lt 100>B</#if>",
            properties: ["Recipient.balance": "100"]
        )
        XCTAssertEqual(result, "")
    }

    func testNumericNonParsableSuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                "<#if Recipient.balance?number gt 100>A</#if>",
                properties: ["Recipient.balance": "not_a_number"]
            ))
    }

    func testNumericMissingKeySuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                "<#if Recipient.balance?number gt 100>A</#if>",
                properties: [:]
            ))
    }

    func testNumericFloat() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.score?number gt 3.0>High<#else>Low</#if>",
            properties: ["Recipient.score": "3.14"]
        )
        XCTAssertEqual(result, "High")
    }

    // MARK: - Multiple interpolations

    func testMultipleInterpolations() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "${Recipient.firstName} ${Recipient.lastName}",
            properties: ["Recipient.firstName": "Joe", "Recipient.lastName": "Smith"]
        )
        XCTAssertEqual(result, "Joe Smith")
    }

    func testMultipleInterpolationsOneMissingSuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                "${Recipient.firstName} ${Recipient.lastName}",
                properties: ["Recipient.firstName": "Joe"]
            ))
    }

    // MARK: - Whitespace inside tags

    func testWhitespaceInsideIfTag() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if  Recipient.flag == "yes" >Shown</#if>"#,
            properties: ["Recipient.flag": "yes"]
        )
        XCTAssertEqual(result, "Shown")
    }

    func testWhitespaceInsideEndIfTag() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.flag == "yes">Shown</# if >"#,
            properties: ["Recipient.flag": "yes"]
        )
        XCTAssertEqual(result, "Shown")
    }

    // MARK: - Plain text pass-through

    func testPlainTextPassThrough() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate("Hello World", properties: [:])
        XCTAssertEqual(result, "Hello World")
    }

    func testEmptyTemplate() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate("", properties: [:])
        XCTAssertEqual(result, "")
    }

    // MARK: - Nil template

    func testNilTemplateSuppresses() {
        XCTAssertThrowsError(try SwrveFreemarkerEvaluator.evaluate(nil, properties: [:]))
    }

    // MARK: - Non-string property values

    func testNSNumberPropertyCoercedToString() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate("Points: ${Recipient.points}", properties: ["Recipient.points": NSNumber(value: 1200)])
        XCTAssertEqual(result, "Points: 1200")
    }

    func testNonCoerciblePropertyValueIgnored() {
        // A value that is neither NSString nor NSNumber is silently dropped.
        // A bare interpolation referencing it should suppress the campaign.
        XCTAssertThrowsError(try SwrveFreemarkerEvaluator.evaluate("${Recipient.data}", properties: ["Recipient.data": NSArray()]))
    }

    // MARK: - Error handling

    func testOrphanedElseIfSuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                #"<#elseif Recipient.x == "y">body"#,
                properties: [:]
            ))
    }

    func testOrphanedElseSuppresses() {
        XCTAssertThrowsError(try SwrveFreemarkerEvaluator.evaluate("<#else>body", properties: [:]))
    }

    func testOrphanedEndIfSuppresses() {
        XCTAssertThrowsError(try SwrveFreemarkerEvaluator.evaluate("some text</#if>", properties: [:]))
    }

    func testUnclosedIfTagSuppresses() {
        XCTAssertThrowsError(try SwrveFreemarkerEvaluator.evaluate("<#if unclosed", properties: [:]))
    }

    func testUnclosedIfBodySuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                #"<#if Recipient.x == "y">body with no end"#,
                properties: ["Recipient.x": "y"]
            ))
    }

    func testUnclosedInterpolationSuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                "Hello ${Recipient.name",
                properties: ["Recipient.name": "Joe"]
            ))
    }

    func testDefaultValueContainingClosingBrace() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"${Recipient.city!"New York}World"}"#,
            properties: [:]
        )
        XCTAssertEqual(result, "New York}World")
    }

    func testDefaultValueContainingClosingBraceSingleQuote() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "${Recipient.city!'a}b'}",
            properties: [:]
        )
        XCTAssertEqual(result, "a}b")
    }

    func testInterpolationAfterDefaultWithBrace() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"${Recipient.city!"New York}World"} is great"#,
            properties: [:]
        )
        XCTAssertEqual(result, "New York}World is great")
    }

    func testNestingDepthLimitSuppresses() {
        let deep = String(repeating: "<#if a??>", count: 101) + "x" + String(repeating: "</#if>", count: 101)
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(deep, properties: ["a": "1"])
        ) { error in
            XCTAssertTrue(error.localizedDescription.contains("depth"))
        }
    }

    func testNestingDepthAtLimitSucceeds() throws {
        let deep = String(repeating: "<#if a??>", count: 100) + "x" + String(repeating: "</#if>", count: 100)
        let result = try SwrveFreemarkerEvaluator.evaluate(deep, properties: ["a": "1"])
        XCTAssertEqual(result, "x")
    }

    func testUnsupportedDirectiveSuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                "<#list items as item>${item}</#list>",
                properties: [:]
            ))
    }

    // MARK: - String literal parser edge cases

    func testEmptyStringLiteralIsValid() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"${Recipient.name!""}"#,
            properties: [:]
        )
        XCTAssertEqual(result, "")
    }

    func testLeadingBangInInterpolationSuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate("${!Recipient.name}", properties: ["Recipient.name": "Alice"])
        ) { error in
            XCTAssertTrue(error.localizedDescription.contains("'!'"))
        }
    }

    func testBareSpaceConcatWorks() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "${Recipient.first+Recipient.last}",
            properties: ["Recipient.first": "John", "Recipient.last": "Doe"]
        )
        XCTAssertEqual(result, "JohnDoe")
    }

    func testBoolNSNumberPropertyConvertsToTrueString() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.flag?boolean>yes<#else>no</#if>",
            properties: ["Recipient.flag": NSNumber(value: true)]
        )
        XCTAssertEqual(result, "yes")
    }

    func testBoolNSNumberFalsePropertyConvertsToFalseString() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.flag?boolean>yes<#else>no</#if>",
            properties: ["Recipient.flag": NSNumber(value: false)]
        )
        XCTAssertEqual(result, "no")
    }

    func testBareDefaultOperatorKeyMissingReturnsEmpty() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "${Recipient.name!}",
            properties: [:]
        )
        XCTAssertEqual(result, "")
    }

    func testBareDefaultOperatorWithTrimKeyMissingSuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                "${Recipient.name?trim!}",
                properties: [:]
            )
        )
    }

    func testBareDefaultOperatorKeyPresentReturnsValue() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "${Recipient.name!}",
            properties: ["Recipient.name": "Alice"]
        )
        XCTAssertEqual(result, "Alice")
    }

    func testBareQuoteCharacterAsDefaultSuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                "${Recipient.name!\"}",
                properties: [:]
            ))
    }

    // MARK: - Parenthesised default in conditions: (key!"default")?builtin

    func testParenthesizedDefaultBoolean_keyPresent() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if (Recipient.is_premium!\"false\")?boolean>yes<#else>no</#if>",
            properties: ["Recipient.is_premium": "true"]
        )
        XCTAssertEqual(result, "yes")
    }

    func testParenthesizedDefaultBoolean_keyAbsent_usesDefault() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if (Recipient.is_premium!\"false\")?boolean>yes<#else>no</#if>",
            properties: [:]
        )
        XCTAssertEqual(result, "no")
    }

    func testParenthesizedDefaultNumeric_keyPresent() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if (Recipient.points!\"0\")?number gte 100>vip<#else>basic</#if>",
            properties: ["Recipient.points": "500"]
        )
        XCTAssertEqual(result, "vip")
    }

    func testParenthesizedDefaultNumeric_keyAbsent_usesDefault() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if (Recipient.points!\"0\")?number gte 100>vip<#else>basic</#if>",
            properties: [:]
        )
        XCTAssertEqual(result, "basic")
    }

    func testParenthesizedDefaultHasContent_keyPresent() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if (Recipient.promo!\"\")?has_content>show<#else>hide</#if>",
            properties: ["Recipient.promo": "SAVE20"]
        )
        XCTAssertEqual(result, "show")
    }

    func testParenthesizedDefaultHasContent_keyAbsent_usesEmptyDefault() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if (Recipient.promo!\"\")?has_content>show<#else>hide</#if>",
            properties: [:]
        )
        XCTAssertEqual(result, "hide")
    }

    // MARK: - Switch with !"default"

    func testSwitchWithDefault_keyPresent_matchesCase() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#switch Recipient.tier!\"bronze\"><#case \"gold\">Gold<#break><#case \"silver\">Silver<#break><#default>Bronze</#switch>",
            properties: ["Recipient.tier": "silver"]
        )
        XCTAssertEqual(result, "Silver")
    }

    func testSwitchWithDefault_keyAbsent_usesDefault() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#switch Recipient.tier!\"bronze\"><#case \"gold\">Gold<#break><#case \"silver\">Silver<#break><#default>Bronze</#switch>",
            properties: [:]
        )
        XCTAssertEqual(result, "Bronze")
    }

    // MARK: - Concatenation without spaces around "+"

    func testBareConcat_noSpaces() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "${Recipient.first+\" \"+Recipient.last}",
            properties: ["Recipient.first": "John", "Recipient.last": "Doe"]
        )
        XCTAssertEqual(result, "John Doe")
    }

    func testBareConcat_mixedSpacing() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "${Recipient.first +\" \"+ Recipient.last}",
            properties: ["Recipient.first": "John", "Recipient.last": "Doe"]
        )
        XCTAssertEqual(result, "John Doe")
    }

}
