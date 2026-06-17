import XCTest

@testable import SwrveSDK

// MARK: - <#if> / <#else> / <#elseif>, boolean, negation, exists check, nested <#if>, logical operators

// swiftlint:disable:next type_body_length
class SwrveTestFreemarkerConditionals: XCTestCase {

    // MARK: - <#if> / <#else>

    func testIfElseTrueBranch() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.loyalty_points == "1200">Gold<#else>Standard</#if>"#,
            properties: ["Recipient.loyalty_points": "1200"]
        )
        XCTAssertEqual(result, "Gold")
    }

    func testIfElseFalseBranch() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.loyalty_points == "1200">Gold<#else>Standard</#if>"#,
            properties: ["Recipient.loyalty_points": "500"]
        )
        XCTAssertEqual(result, "Standard")
    }

    func testIfWithoutElse() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.flag == "yes">Shown</#if>"#,
            properties: ["Recipient.flag": "yes"]
        )
        XCTAssertEqual(result, "Shown")
    }

    func testIfWithoutElseFalse() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.flag == "yes">Shown</#if>"#,
            properties: ["Recipient.flag": "no"]
        )
        XCTAssertEqual(result, "")
    }

    func testIfMissingKeySuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                #"<#if Recipient.missing == "x">A<#else>B</#if>"#,
                properties: [:]
            ))
    }

    func testNotEquals() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.country != "US">International<#else>Domestic</#if>"#,
            properties: ["Recipient.country": "UK"]
        )
        XCTAssertEqual(result, "International")
    }

    func testNotEqualsMissingKeySuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                #"<#if Recipient.country != "US">International<#else>Domestic</#if>"#,
                properties: [:]
            ))
    }

    // MARK: - <#elseif>

    func testElseIfFirstBranch() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.loyalty_points?number gte 1000>Gold<#elseif Recipient.loyalty_points?number gte 500>Silver<#else>Bronze</#if>",
            properties: ["Recipient.loyalty_points": "1200"]
        )
        XCTAssertEqual(result, "Gold")
    }

    func testElseIfSecondBranch() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.loyalty_points?number gte 1000>Gold<#elseif Recipient.loyalty_points?number gte 500>Silver<#else>Bronze</#if>",
            properties: ["Recipient.loyalty_points": "700"]
        )
        XCTAssertEqual(result, "Silver")
    }

    func testElseIfFallsToElse() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.loyalty_points?number gte 1000>Gold<#elseif Recipient.loyalty_points?number gte 500>Silver<#else>Bronze</#if>",
            properties: ["Recipient.loyalty_points": "100"]
        )
        XCTAssertEqual(result, "Bronze")
    }

    func testElseIfMultipleClauses() throws {
        // Three elseif tiers — confirms the loop processes all clauses in order
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.loyalty_points?number gte 1000>Gold"
                + "<#elseif Recipient.loyalty_points?number gte 750>Silver"
                + "<#elseif Recipient.loyalty_points?number gte 500>Bronze"
                + "<#else>Basic</#if>",
            properties: ["Recipient.loyalty_points": "600"]
        )
        XCTAssertEqual(result, "Bronze")
    }

    func testElseIfBoundaryGte() throws {
        // gte 1000 with exactly 1000 — should match first branch
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.loyalty_points?number gte 1000>Gold<#elseif Recipient.loyalty_points?number gte 500>Silver<#else>Bronze</#if>",
            properties: ["Recipient.loyalty_points": "1000"]
        )
        XCTAssertEqual(result, "Gold")
    }

    // MARK: - ?boolean

    func testBooleanTrue() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.email_opt_in?boolean>Subscribed<#else>Not subscribed</#if>",
            properties: ["Recipient.email_opt_in": "true"]
        )
        XCTAssertEqual(result, "Subscribed")
    }

    func testBooleanFalse() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.email_opt_in?boolean>Subscribed<#else>Not subscribed</#if>",
            properties: ["Recipient.email_opt_in": "false"]
        )
        XCTAssertEqual(result, "Not subscribed")
    }

    func testBooleanCaseInsensitive() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.email_opt_in?boolean>Subscribed</#if>",
            properties: ["Recipient.email_opt_in": "TRUE"]
        )
        XCTAssertEqual(result, "Subscribed")
    }

    func testBooleanInvalidValueSuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                "<#if Recipient.email_opt_in?boolean>Subscribed</#if>",
                properties: ["Recipient.email_opt_in": "yes"]
            ))
    }

    func testBooleanMissingKeySuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                "<#if Recipient.email_opt_in?boolean>Subscribed</#if>",
                properties: [:]
            ))
    }

    // MARK: - ?trim?boolean chain

    func testTrimBooleanChainTrue() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.flag?trim?boolean>yes<#else>no</#if>",
            properties: ["Recipient.flag": "  true  "]
        )
        XCTAssertEqual(result, "yes")
    }

    func testTrimBooleanChainFalse() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.flag?trim?boolean>yes<#else>no</#if>",
            properties: ["Recipient.flag": "  false  "]
        )
        XCTAssertEqual(result, "no")
    }

    // MARK: - Negation

    func testNegationFalseBecomesTrue() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if !Recipient.email_opt_in?boolean>Not subscribed<#else>Subscribed</#if>",
            properties: ["Recipient.email_opt_in": "false"]
        )
        XCTAssertEqual(result, "Not subscribed")
    }

    func testNegationTrueBecomesFalse() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if !Recipient.email_opt_in?boolean>Not subscribed<#else>Subscribed</#if>",
            properties: ["Recipient.email_opt_in": "true"]
        )
        XCTAssertEqual(result, "Subscribed")
    }

    func testNegationOfExistsCheck() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if !Recipient.name??>No name<#else>Has name</#if>",
            properties: [:]
        )
        XCTAssertEqual(result, "No name")
    }

    // MARK: - Exists check ??

    func testExistsCheckKeyPresent() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.firstName??>Hello ${Recipient.firstName}<#else>Hello there</#if>",
            properties: ["Recipient.firstName": "Joe"]
        )
        XCTAssertEqual(result, "Hello Joe")
    }

    func testExistsCheckKeyMissing() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.firstName??>Hello ${Recipient.firstName}<#else>Hello there</#if>",
            properties: [:]
        )
        XCTAssertEqual(result, "Hello there")
    }

    func testExistsWithBuiltinBeforeSuppresses() {
        // Recipient.name?trim?? — built-in before ?? is not supported
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                "<#if Recipient.name?trim??>yes</#if>",
                properties: ["Recipient.name": "Joe"]
            ))
    }

    // MARK: - Nested <#if>

    func testNestedIf() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.tier == "gold"><#if Recipient.vip == "true">VIP Gold<#else>Gold</#if><#else>Standard</#if>"#,
            properties: ["Recipient.tier": "gold", "Recipient.vip": "true"]
        )
        XCTAssertEqual(result, "VIP Gold")
    }

    func testNestedIfInnerFalseBranch() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.tier == "gold"><#if Recipient.vip == "true">VIP Gold<#else>Gold</#if><#else>Standard</#if>"#,
            properties: ["Recipient.tier": "gold", "Recipient.vip": "false"]
        )
        XCTAssertEqual(result, "Gold")
    }

    func testNestedIfOuterFalseBranch() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.tier == "gold"><#if Recipient.vip == "true">VIP Gold<#else>Gold</#if><#else>Standard</#if>"#,
            properties: ["Recipient.tier": "bronze", "Recipient.vip": "true"]
        )
        XCTAssertEqual(result, "Standard")
    }

    // MARK: - Logical operators && / ||

    func testAndBothTrue() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.tier == "gold" && Recipient.active == "true">yes<#else>no</#if>"#,
            properties: ["Recipient.tier": "gold", "Recipient.active": "true"]
        )
        XCTAssertEqual(result, "yes")
    }

    func testAndLeftFalse() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.tier == "gold" && Recipient.active == "true">yes<#else>no</#if>"#,
            properties: ["Recipient.tier": "silver", "Recipient.active": "true"]
        )
        XCTAssertEqual(result, "no")
    }

    func testAndRightFalse() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.tier == "gold" && Recipient.active == "true">yes<#else>no</#if>"#,
            properties: ["Recipient.tier": "gold", "Recipient.active": "false"]
        )
        XCTAssertEqual(result, "no")
    }

    func testOrLeftTrue() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.tier == "gold" || Recipient.tier == "platinum">premium<#else>standard</#if>"#,
            properties: ["Recipient.tier": "gold"]
        )
        XCTAssertEqual(result, "premium")
    }

    func testOrRightTrue() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.tier == "gold" || Recipient.tier == "platinum">premium<#else>standard</#if>"#,
            properties: ["Recipient.tier": "platinum"]
        )
        XCTAssertEqual(result, "premium")
    }

    func testOrBothFalse() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.tier == "gold" || Recipient.tier == "platinum">premium<#else>standard</#if>"#,
            properties: ["Recipient.tier": "bronze"]
        )
        XCTAssertEqual(result, "standard")
    }

    func testAndPrecedenceOverOr() throws {
        // a || b && c should parse as a || (b && c)
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.a == "1" || Recipient.b == "1" && Recipient.c == "1">yes<#else>no</#if>"#,
            properties: ["Recipient.a": "1", "Recipient.b": "0", "Recipient.c": "0"]
        )
        // a=true, b=false, c=false → true || (false && false) = true (correct); (true || false) && false = false (wrong parse)
        XCTAssertEqual(result, "yes")
    }

    func testAndShortCircuitMissingKey() throws {
        // Left side is false — right side has missing key but should not throw due to short-circuit
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.a?? && Recipient.b == "x">yes<#else>no</#if>"#,
            properties: [:]
        )
        // Both Recipient.a and Recipient.b are missing — ?? returns false — short-circuit skips right side (which would throw)
        XCTAssertEqual(result, "no")
    }

    func testOrShortCircuitMissingKey() throws {
        // Left side is true — right side has missing key but should not throw due to short-circuit
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.tier == "gold" || Recipient.missing == "x">yes<#else>no</#if>"#,
            properties: ["Recipient.tier": "gold"]
        )
        XCTAssertEqual(result, "yes")
    }

    func testChainedAnd() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.a == "1" && Recipient.b == "1" && Recipient.c == "1">yes<#else>no</#if>"#,
            properties: ["Recipient.a": "1", "Recipient.b": "1", "Recipient.c": "1"]
        )
        XCTAssertEqual(result, "yes")
    }

    func testNegationWithAnd() throws {
        // !a && b
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if !Recipient.flag?boolean && Recipient.tier == "gold">yes<#else>no</#if>"#,
            properties: ["Recipient.flag": "false", "Recipient.tier": "gold"]
        )
        XCTAssertEqual(result, "yes")
    }

    // MARK: - Newline stripping after if/else/elseif directive tags

    func testIfDirectiveNewlineStripped() throws {
        // Newline immediately after <#if ...> is stripped; content newline is preserved
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.tier == \"gold\">\nGold\n</#if>",
            properties: ["Recipient.tier": "gold"]
        )
        XCTAssertEqual(result, "Gold\n")
    }

    func testEndIfDirectiveNewlineStripped() throws {
        // Newline after </#if> is stripped
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.tier == \"gold\">\nGold\n</#if>\nafter",
            properties: ["Recipient.tier": "gold"]
        )
        XCTAssertEqual(result, "Gold\nafter")
    }

    func testElseDirectiveNewlineNotStrippedWhenInline() throws {
        // <#else> is mid-line (after "Gold") — newline is kept, matching FreeMarker behaviour
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.tier == \"gold\">\nGold<#else>\nSilver</#if>",
            properties: ["Recipient.tier": "silver"]
        )
        XCTAssertEqual(result, "\nSilver")
    }

    func testElseOnOwnLineNewlineStripped() throws {
        // <#else> starts a new line — \n after it is stripped, matching FreeMarker behaviour
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.tier == \"gold\">\nGold\n<#else>\nSilver\n</#if>",
            properties: ["Recipient.tier": "silver"]
        )
        XCTAssertEqual(result, "Silver\n")
    }

    func testElseIfDirectiveNewlineNotStrippedWhenInline() throws {
        // <#elseif> is mid-line — newline before the matching branch body is kept
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.tier == \"gold\">\nGold<#elseif Recipient.tier == \"silver\">\nSilver<#else>\nBronze</#if>",
            properties: ["Recipient.tier": "silver"]
        )
        XCTAssertEqual(result, "\nSilver")
    }

    func testElseIfOnOwnLineNewlineStripped() throws {
        // <#elseif> starts a new line — \n after it is stripped, matching FreeMarker behaviour
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.tier == \"gold\">\nGold\n<#elseif Recipient.tier == \"silver\">\nSilver\n<#else>\nBronze\n</#if>",
            properties: ["Recipient.tier": "silver"]
        )
        XCTAssertEqual(result, "Silver\n")
    }

    func testInlineDirectiveNewlineNotStripped() throws {
        // <#if> is mid-line (non-whitespace before it) — \n after </#if> is kept
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "Hello<#if Recipient.name??>!</#if>\nWorld",
            properties: ["Recipient.name": "Alice"]
        )
        XCTAssertEqual(result, "Hello!\nWorld")
    }

    func testCrlfAfterDirectiveStripped() throws {
        // CRLF line endings: \r\n after an on-own-line directive is stripped
        // Note: cannot be a conformance fixture — the fixture generator normalises CRLF
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.tier == \"gold\">\r\nGold\r\n</#if>",
            properties: ["Recipient.tier": "gold"]
        )
        XCTAssertEqual(result, "Gold\r\n")
    }

    func testCrAfterDirectiveStripped() throws {
        // Bare \r (classic Mac) after an on-own-line directive is stripped
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.tier == \"gold\">\rGold\r</#if>",
            properties: ["Recipient.tier": "gold"]
        )
        XCTAssertEqual(result, "Gold\r")
    }

    func testCrlfInlineDirectiveNotStripped() throws {
        // </#if> is mid-line — \r\n after it must NOT be stripped
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "Hello<#if Recipient.name??>!</#if>\r\nWorld",
            properties: ["Recipient.name": "Alice"]
        )
        XCTAssertEqual(result, "Hello!\r\nWorld")
    }

    func testNewlineNotStrippedWhenSpacesBefore() throws {
        // Spaces between > and \n — newline must NOT be stripped
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.tier == \"gold\">  \nGold</#if>",
            properties: ["Recipient.tier": "gold"]
        )
        XCTAssertEqual(result, "  \nGold")
    }

    // MARK: - ! default in <#if> condition expressions

    func testDefaultInConditionKeyMissing() throws {
        // (Recipient.tier!"bronze") == "gold" — key absent, default used, no match
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if (Recipient.tier!"bronze") == "gold">Gold<#else>Not gold</#if>"#,
            properties: [:]
        )
        XCTAssertEqual(result, "Not gold")
    }

    func testDefaultInConditionKeyMissingDefaultMatches() throws {
        // (Recipient.tier!"gold") == "gold" — key absent, default matches
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if (Recipient.tier!"gold") == "gold">Gold<#else>Not gold</#if>"#,
            properties: [:]
        )
        XCTAssertEqual(result, "Gold")
    }

    func testDefaultInConditionKeyPresent() throws {
        // Key present — default is not used
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if (Recipient.tier!"bronze") == "gold">Gold<#else>Not gold</#if>"#,
            properties: ["Recipient.tier": "gold"]
        )
        XCTAssertEqual(result, "Gold")
    }

    func testDefaultInConditionWithoutParens() throws {
        // ! default also works without outer parens
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.tier!"bronze" == "bronze">Bronze<#else>Other</#if>"#,
            properties: [:]
        )
        XCTAssertEqual(result, "Bronze")
    }

    func testDefaultInNotEqualsCondition() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if (Recipient.tier!"bronze") != "gold">Not gold<#else>Gold</#if>"#,
            properties: [:]
        )
        XCTAssertEqual(result, "Not gold")
    }

    func testTrimWithDefaultInCondition() throws {
        // ?trim applied before default — key present with surrounding whitespace
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.tier?trim!"bronze" == "gold">Gold<#else>Not gold</#if>"#,
            properties: ["Recipient.tier": "  gold  "]
        )
        XCTAssertEqual(result, "Gold")
    }

    func testTrimWithDefaultInConditionKeyMissingSuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                #"<#if Recipient.tier?trim!"bronze" == "bronze">Bronze<#else>Other</#if>"#,
                properties: [:]
            )
        )
    }

    // MARK: - Bare ! default in <#if> conditions

    func testBareDefaultInConditionKeyMissing() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.tier! == "gold">Gold<#else>Not gold</#if>"#,
            properties: [:]
        )
        XCTAssertEqual(result, "Not gold")
    }

    func testBareDefaultInConditionEmptyStringMatchesEmpty() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.tier! == "">Empty</#if>"#,
            properties: [:]
        )
        XCTAssertEqual(result, "Empty")
    }

    func testBareDefaultInConditionKeyPresent() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.tier! == "gold">Gold<#else>Not gold</#if>"#,
            properties: ["Recipient.tier": "gold"]
        )
        XCTAssertEqual(result, "Gold")
    }

    func testBareDefaultNotEqualsKeyMissing() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.tier! != "gold">Not gold</#if>"#,
            properties: [:]
        )
        XCTAssertEqual(result, "Not gold")
    }

    func testBareDefaultWithTrimKeyMissingSuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                #"<#if Recipient.tier?trim! == "gold">Gold<#else>Not gold</#if>"#,
                properties: [:]
            )
        )
    }

    // MARK: - > inside quoted string literals

    func testComparisonKeywordGtInsideStringLiteralMatches() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.label == "a gt b">yes<#else>no</#if>"#,
            properties: ["Recipient.label": "a gt b"]
        )
        XCTAssertEqual(result, "yes")
    }

    func testComparisonKeywordGtInsideStringLiteralNoMatch() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.label == "a gt b">yes<#else>no</#if>"#,
            properties: ["Recipient.label": "other"]
        )
        XCTAssertEqual(result, "no")
    }

    func testComparisonKeywordLtInsideStringLiteralMatches() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.label == "x lt y">yes<#else>no</#if>"#,
            properties: ["Recipient.label": "x lt y"]
        )
        XCTAssertEqual(result, "yes")
    }

    func testComparisonKeywordGteInsideStringLiteralMatches() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.label == "x gte y">yes<#else>no</#if>"#,
            properties: ["Recipient.label": "x gte y"]
        )
        XCTAssertEqual(result, "yes")
    }

    func testComparisonKeywordNotEqualsWithGtInLiteral() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.label != "a gt b">yes<#else>no</#if>"#,
            properties: ["Recipient.label": "other"]
        )
        XCTAssertEqual(result, "yes")
    }

    func testGreaterThanInsideStringLiteralInCondition() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.label == "a>b">yes<#else>no</#if>"#,
            properties: ["Recipient.label": "a>b"]
        )
        XCTAssertEqual(result, "yes")
    }

    func testGreaterThanInsideStringLiteralNoMatch() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.label == "a>b">yes<#else>no</#if>"#,
            properties: ["Recipient.label": "other"]
        )
        XCTAssertEqual(result, "no")
    }

    // MARK: - Quote-aware numeric operator search

    func testOperatorInsideQuotedDefaultNotMisParsed() throws {
        // " gt " inside the string literal must not be treated as a numeric comparison operator.
        // Before fix: range(of: " gt ") splits inside the literal → throws "Numeric comparison requires ?number".
        // After fix: indexOutsideQuotes skips the quoted span → parseNumericCompare returns nil → parseBooleanBuiltin handles it.
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if (Recipient.flag!"a gt b")?boolean>yes<#else>no</#if>"#,
            properties: ["Recipient.flag": "true"]
        )
        XCTAssertEqual(result, "yes")
    }

    func testOperatorInsideQuotedDefaultDefaultPathNotMisParsed() {
        // Same but key is absent — default "a gt b" is not a valid boolean → suppresses.
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                #"<#if (Recipient.flag!"a gt b")?boolean>yes<#else>no</#if>"#,
                properties: [:]
            )
        )
    }

    // MARK: - Terminal built-ins rejected in == / != LHS

    func testBooleanBuiltinInEqualityLHSSuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                "<#if Recipient.flag?boolean == \"true\">yes</#if>",
                properties: ["Recipient.flag": "true"]
            )
        ) { error in
            XCTAssertTrue(error.localizedDescription.contains("?boolean"))
        }
    }

    func testNumberBuiltinInEqualityLHSSuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                #"<#if Recipient.points?number == "10">yes</#if>"#,
                properties: ["Recipient.points": "10"]
            )
        ) { error in
            XCTAssertTrue(error.localizedDescription.contains("?number"))
        }
    }

    func testHasContentBuiltinInEqualityLHSSuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                #"<#if Recipient.name?has_content == "true">yes</#if>"#,
                properties: ["Recipient.name": "Alice"]
            )
        ) { error in
            XCTAssertTrue(error.localizedDescription.contains("?has_content"))
        }
    }

    // MARK: - Mixed content

    func testIfWithInterpolationInBody() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.tier == "gold">Welcome ${Recipient.name}, Gold member!<#else>Welcome ${Recipient.name}.</#if>"#,
            properties: ["Recipient.tier": "gold", "Recipient.name": "Alice"]
        )
        XCTAssertEqual(result, "Welcome Alice, Gold member!")
    }

    // MARK: - String literal interior quote validation

    func testStringLiteralInteriorDoubleQuoteSuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                #"<#if Recipient.x == "y" != "z">ok</#if>"#,
                properties: ["Recipient.x": "y"]
            )
        )
    }

    func testStringLiteralInteriorSingleQuoteSuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                "<#if Recipient.x == 'a' 'b'>ok</#if>",
                properties: ["Recipient.x": "a"]
            )
        )
    }

    func testStringLiteralValidDoubleQuotedAccepted() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.x == "hello">ok</#if>"#,
            properties: ["Recipient.x": "hello"]
        )
        XCTAssertEqual(result, "ok")
    }

    func testStringLiteralValidSingleQuotedAccepted() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.x == 'hello'>ok</#if>",
            properties: ["Recipient.x": "hello"]
        )
        XCTAssertEqual(result, "ok")
    }
}
