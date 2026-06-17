import Foundation

// MARK: - Date types

enum FMDateKind {
    case date  // ?date — accepts datetime or date-only strings, yields calendar date
    case dateTime  // ?datetime — requires full datetime string (must contain T)
    case strictDate  // ?datetime?date chain — requires full datetime string, yields calendar date
}

enum FMDateExpr {
    case property(variable: String, kind: FMDateKind)
    case propertyWithDefault(variable: String, defaultValue: String, kind: FMDateKind)
    case now(kind: FMDateKind)  // .now or .now?date
}

struct FMCalendarDate: Comparable, Equatable {
    let year: Int, month: Int, day: Int

    static func < (lhs: FMCalendarDate, rhs: FMCalendarDate) -> Bool {
        if lhs.year != rhs.year { return lhs.year < rhs.year }
        if lhs.month != rhs.month { return lhs.month < rhs.month }
        return lhs.day < rhs.day
    }
}

enum FMDateValue {
    case calendarDate(FMCalendarDate)
    case dateTime(Date)
}

// MARK: - FMParser date built-in helpers

extension FMParser {

    func dateKindOf(_ expr: FMDateExpr) -> FMDateKind {
        switch expr {
        case .property(_, let kind): return kind
        case .propertyWithDefault(_, _, let kind): return kind
        case .now(let kind): return kind
        }
    }

    func isDateExpression(_ s: String) -> Bool {
        s.hasSuffix("?date") || s.hasSuffix("?datetime") || s == ".now"
    }

    // Throws if the expression looks like an attempted (key!"default") that could not be parsed —
    // i.e. starts with '(' and contains '!', but didn't match the expected form.
    func throwIfMalformedParenthesizedDefault(_ s: String, context: String) throws {
        if s.hasPrefix("(") && s.contains("!") {
            throw FreemarkerError("Malformed parenthesized default in \(context): \(s) — expected (key!\"default\") form")
        }
    }

    // Detects (key!"default") form and returns (key, defaultValue), or nil if not in that form.
    func parseParenthesizedDefault(_ s: String) -> (key: String, defaultValue: String)? {
        let trimmed = s.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("(") && trimmed.hasSuffix(")") else { return nil }
        let inner = String(trimmed.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)
        guard let bangIdx = inner.firstIndex(of: "!") else { return nil }
        let key = String(inner[inner.startIndex..<bangIdx]).trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty, !key.contains("?"), !key.contains("("), !key.contains(")") else { return nil }
        let defaultPart = String(inner[inner.index(after: bangIdx)...]).trimmingCharacters(in: .whitespaces)
        guard let defaultValue = try? parseStringLiteral(defaultPart, context: "!") else { return nil }
        return (key, defaultValue)
    }

    func parseDateExpr(_ s: String) throws -> FMDateExpr {
        let trimmed = s.trimmingCharacters(in: .whitespaces)
        if trimmed.hasSuffix("?datetime?date") {
            let base = String(trimmed.dropLast("?datetime?date".count)).trimmingCharacters(in: .whitespaces)
            if base != ".now" { try validateBareKey(base, context: "?datetime?date") }
            return base == ".now" ? .now(kind: .date) : .property(variable: base, kind: .strictDate)
        } else if trimmed.hasSuffix("?datetime") {
            let base = String(trimmed.dropLast("?datetime".count)).trimmingCharacters(in: .whitespaces)
            if base != ".now" { try validateBareKey(base, context: "?datetime") }
            return base == ".now" ? .now(kind: .dateTime) : .property(variable: base, kind: .dateTime)
        } else if trimmed.hasSuffix("?date") {
            let base = String(trimmed.dropLast("?date".count)).trimmingCharacters(in: .whitespaces)
            if base == ".now" { return .now(kind: .date) }
            if let (key, defVal) = parseParenthesizedDefault(base) {
                return .propertyWithDefault(variable: key, defaultValue: defVal, kind: .date)
            }
            try throwIfMalformedParenthesizedDefault(base, context: "?date")
            try validateBareKey(base, context: "?date")
            return .property(variable: base, kind: .date)
        } else if trimmed == ".now" {
            return .now(kind: .dateTime)
        }
        throw FreemarkerError("Expected ?date or ?datetime built-in on: \(trimmed)")
    }
}

// MARK: - FMParser string transform helpers

extension FMParser {

    // Peels zero or more string-transform built-ins from the right of an expression,
    // returning the base variable name and transforms in left-to-right application order.
    // Recognised transforms: ?trim, ?lower_case, ?upper_case
    func parseStringTransforms(_ s: String) -> (variable: String, transforms: [FMStringTransform]) {
        let knownTransforms: [(String, FMStringTransform)] = [
            ("?lower_case", .lowerCase),
            ("?upper_case", .upperCase),
            ("?trim", .trim)
        ]
        var remaining = s.trimmingCharacters(in: .whitespaces)
        var transforms: [FMStringTransform] = []
        var changed = true
        while changed {
            changed = false
            for (suffix, transform) in knownTransforms where remaining.hasSuffix(suffix) {
                remaining = String(remaining.dropLast(suffix.count)).trimmingCharacters(in: .whitespaces)
                transforms.insert(transform, at: 0)
                changed = true
                break
            }
        }
        return (remaining, transforms)
    }
}

// MARK: - FMParser numeric built-in helpers

extension FMParser {

    // gt / gte / lt / lte comparisons for both ?number and ?date/?datetime operands —
    // they share the same operator syntax, dispatched by isDateExpression.
    // Returns nil if no comparison operator is present.
    // Returns the index of the first occurrence of `sub` in `s` that is outside quotes and parens, or nil.
    private func indexOutsideQuotes(_ s: String, of sub: String) -> String.Index? {
        var i = s.startIndex
        var inQuotes = false
        var quoteChar: Character = "\""
        var parenDepth = 0
        while i < s.endIndex {
            let c = s[i]
            if inQuotes {
                if c == quoteChar { inQuotes = false }
                i = s.index(after: i)
            } else if c == "\"" || c == "'" {
                inQuotes = true
                quoteChar = c
                i = s.index(after: i)
            } else if c == "(" {
                parenDepth += 1
                i = s.index(after: i)
            } else if c == ")" {
                parenDepth -= 1
                if parenDepth < 0 { return nil }
                i = s.index(after: i)
            } else if parenDepth == 0, s[i...].hasPrefix(sub) {
                return i
            } else {
                i = s.index(after: i)
            }
        }
        return nil
    }

    func parseNumericCompare(_ s: String) throws -> FMConditionExpr? {
        // gte/lte checked before gt/lt to avoid partial prefix match
        let ops: [(String, FMNumericOp)] = [
            (" gte ", .greaterThanOrEqual),
            (" lte ", .lessThanOrEqual),
            (" gt ", .greaterThan),
            (" lt ", .lessThan)
        ]
        for (opStr, op) in ops {
            if let idx = indexOutsideQuotes(s, of: opStr) {
                let varPart = String(s[s.startIndex..<idx]).trimmingCharacters(in: .whitespaces)
                let rhsPart = String(s[s.index(idx, offsetBy: opStr.count)...]).trimmingCharacters(in: .whitespaces)
                if isDateExpression(varPart) {
                    let lhsExpr = try parseDateExpr(varPart)
                    let rhsExpr = try parseDateExpr(rhsPart)
                    let lhsIsDatetime = dateKindOf(lhsExpr) == .dateTime
                    let rhsIsDatetime = dateKindOf(rhsExpr) == .dateTime
                    if lhsIsDatetime != rhsIsDatetime {
                        throw FreemarkerError(
                            "Type mismatch: cannot mix ?date and ?datetime in the same comparison — use .now?date with ?date or ?datetime?date, or .now with ?datetime"
                        )
                    }
                    return .dateCompare(lhsExpr, op, rhsExpr)
                }
                guard varPart.hasSuffix("?number") else {
                    throw FreemarkerError("Numeric comparison requires ?number built-in on left-hand side: \(varPart)")
                }
                guard let value = Double(rhsPart), !value.isNaN, !value.isInfinite else {
                    throw FreemarkerError(
                        "Expected finite numeric literal for \(opStr.trimmingCharacters(in: .whitespaces)) operator, got: \(rhsPart)")
                }
                let base = String(varPart.dropLast("?number".count)).trimmingCharacters(in: .whitespaces)
                let (variable, transforms) = parseStringTransforms(base)
                if let (key, defVal) = parseParenthesizedDefault(variable) {
                    return .numericCompareWithDefault(key, transforms, defVal, op, value)
                }
                try throwIfMalformedParenthesizedDefault(variable, context: "?number")
                try validateBareKey(variable, context: "?number")
                return .numericCompare(variable, op, value, transforms)
            }
        }
        return nil
    }

    // ?boolean — used as a truth value directly in <#if>
    // Supports any string-transform chain before ?boolean: e.g. ?trim?boolean, ?lower_case?boolean, ?trim?lower_case?boolean
    // Returns nil if the expression does not end with ?boolean.
    func parseBooleanBuiltin(_ s: String) throws -> FMConditionExpr? {
        guard s.hasSuffix("?boolean") else { return nil }
        let prefix = String(s.dropLast("?boolean".count)).trimmingCharacters(in: .whitespaces)
        let (variable, transforms) = parseStringTransforms(prefix)
        if let (key, defVal) = parseParenthesizedDefault(variable) {
            return .booleanValueWithDefault(key, transforms, defVal)
        }
        try throwIfMalformedParenthesizedDefault(variable, context: "?boolean")
        try validateBareKey(variable, context: "?boolean")
        return .booleanValue(variable, transforms)
    }
}

// MARK: - FMParser string built-in helpers

extension FMParser {

    // ?has_content: variable?has_content or variable?transforms?has_content
    func parseHasContent(_ s: String) throws -> FMConditionExpr? {
        guard s.hasSuffix("?has_content") else { return nil }
        let prefix = String(s.dropLast("?has_content".count)).trimmingCharacters(in: .whitespaces)
        let (variable, transforms) = parseStringTransforms(prefix)
        if let (key, defVal) = parseParenthesizedDefault(variable) {
            return .hasContentWithDefault(key, transforms, defVal)
        }
        try throwIfMalformedParenthesizedDefault(variable, context: "?has_content")
        try validateBareKey(variable, context: "?has_content")
        return .hasContent(variable, transforms)
    }

    // String-transform built-ins and optional default in ${} interpolation context.
    // Handles: variable?transforms*!"default", variable?transforms*
    // Also validates that ?has_content cannot appear in interpolation.
    // Returns nil if no string-transform built-ins are present (caller handles bare variable and bare !default).
    func parseStringTransformInterpolation(_ s: String) throws -> FMInterpolationExpr? {
        if s.hasSuffix("?has_content") {
            throw FreemarkerError("?has_content produces a boolean and cannot be used in ${} interpolation")
        }

        // Look for a default-operator bang followed by a quote char: variable?transforms*!"literal"
        var bangIdx: String.Index?
        var inQuotes = false
        var quoteChar: Character = "\""
        var i = s.startIndex
        while i < s.endIndex {
            let c = s[i]
            let next = s.index(after: i)
            if inQuotes {
                if c == quoteChar { inQuotes = false }
            } else if c == "\"" || c == "'" {
                inQuotes = true
                quoteChar = c
            } else if c == "!" && next < s.endIndex && (s[next] == "\"" || s[next] == "'") && i != s.startIndex {
                bangIdx = i
                break
            }
            i = next
        }

        if let bang = bangIdx {
            let prefix = String(s[s.startIndex..<bang]).trimmingCharacters(in: .whitespaces)
            let defaultPart = String(s[s.index(after: bang)...]).trimmingCharacters(in: .whitespaces)
            let defaultValue = try parseStringLiteral(defaultPart, context: "!")
            let (variable, transforms) = parseStringTransforms(prefix)
            guard !transforms.isEmpty else { return nil }  // let caller handle bare variable!"default"
            try validateBareKey(variable, context: "${} transform+default")
            return .withDefault(variable, transforms, defaultValue)
        }

        // No default operator — just transforms
        let (variable, transforms) = parseStringTransforms(s)
        guard !transforms.isEmpty else { return nil }
        try validateBareKey(variable, context: "${} transform")
        return .variable(variable, transforms)
    }
}
