import Foundation

// MARK: - FMParser
// Recursive descent parser: parseBody calls itself to handle nested blocks,
// mirroring the grammar rule: body = (text | interpolation | ifStatement | switchStatement)*

private enum FMNestingContext {
    case topLevel
    case ifBody  // inside <#if> / <#elseif> / <#else> — stops on elseif/else/endif
    case switchBody  // inside <#case> / <#default> — stops on case/default/break/endswitch
}

// swiftlint:disable:next type_body_length
final class FMParser {
    private let tokens: [FMToken]
    private var pos: Int = 0

    init(_ tokens: [FMToken]) { self.tokens = tokens }

    func parse() throws -> [FMASTNode] {
        try parseBody(nestingContext: .topLevel, depth: 0)
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func parseBody(nestingContext: FMNestingContext, depth: Int) throws -> [FMASTNode] {
        guard depth <= 100 else { throw FreemarkerError("Template nesting depth exceeds limit (max 100)") }
        var nodes: [FMASTNode] = []

        while pos < tokens.count {
            switch tokens[pos] {
            case .text(let s):
                nodes.append(.text(s))
                pos += 1

            case .interpolation(let expr):
                nodes.append(.interpolation(try parseInterpolation(expr)))
                pos += 1

            case .ifDirective(let conditionStr):
                pos += 1
                let condition = try parseCondition(conditionStr)
                let thenBody = try parseBody(nestingContext: .ifBody, depth: depth + 1)
                var elseIfClauses: [(FMConditionExpr, [FMASTNode])] = []
                while pos < tokens.count, case .elseIfDirective(let elseIfCondStr) = tokens[pos] {
                    pos += 1
                    let elseIfCond = try parseCondition(elseIfCondStr)
                    let elseIfBody = try parseBody(nestingContext: .ifBody, depth: depth + 1)
                    elseIfClauses.append((elseIfCond, elseIfBody))
                }
                var elseBody: [FMASTNode] = []
                if pos < tokens.count, case .elseDirective = tokens[pos] {
                    pos += 1
                    elseBody = try parseBody(nestingContext: .ifBody, depth: depth + 1)
                }
                guard pos < tokens.count, case .endIf = tokens[pos] else {
                    throw FreemarkerError("Unclosed <#if> — missing </#if>")
                }
                pos += 1
                nodes.append(.ifStatement(condition: condition, thenBody: thenBody, elseIfClauses: elseIfClauses, elseBody: elseBody))

            case .elseIfDirective:
                switch nestingContext {
                case .ifBody: return nodes
                case .switchBody: throw FreemarkerError("Unexpected <#elseif> inside <#case> or <#default>")
                case .topLevel: throw FreemarkerError("Unexpected <#elseif> without matching <#if>")
                }

            case .elseDirective:
                switch nestingContext {
                case .ifBody: return nodes
                case .switchBody: throw FreemarkerError("Unexpected <#else> inside <#case> or <#default>")
                case .topLevel: throw FreemarkerError("Unexpected <#else> without matching <#if>")
                }

            case .endIf:
                switch nestingContext {
                case .ifBody: return nodes
                case .switchBody, .topLevel: throw FreemarkerError("Unexpected </#if> without matching <#if>")
                }

            case .switchDirective(let expr):
                pos += 1
                nodes.append(try parseSwitch(expr, depth: depth + 1))

            case .caseDirective:
                switch nestingContext {
                case .switchBody: return nodes
                case .ifBody: throw FreemarkerError("Unexpected <#case> inside <#if>")
                case .topLevel: throw FreemarkerError("Unexpected <#case> outside <#switch>")
                }

            case .defaultDirective:
                switch nestingContext {
                case .switchBody: return nodes
                case .ifBody: throw FreemarkerError("Unexpected <#default> inside <#if>")
                case .topLevel: throw FreemarkerError("Unexpected <#default> outside <#switch>")
                }

            case .breakDirective:
                switch nestingContext {
                case .switchBody: return nodes
                case .ifBody:
                    throw FreemarkerError("<#break> inside <#if> is not supported — <#break> must appear directly inside <#case> or <#default>")
                case .topLevel: throw FreemarkerError("Unexpected <#break> outside <#switch>")
                }

            case .endSwitch:
                switch nestingContext {
                case .switchBody: return nodes
                case .ifBody: throw FreemarkerError("Unexpected </#switch> inside <#if>")
                case .topLevel: throw FreemarkerError("Unexpected </#switch> without matching <#switch>")
                }
            }
        }

        switch nestingContext {
        case .ifBody: throw FreemarkerError("Unclosed <#if> — missing </#if>")
        case .switchBody: throw FreemarkerError("Unclosed <#switch> — missing </#switch>")
        case .topLevel: break
        }

        return nodes
    }

    private func parseSwitch(_ expr: String, depth: Int) throws -> FMASTNode {
        let (candidate, transforms) = parseStringTransforms(expr.trimmingCharacters(in: .whitespaces))
        guard !candidate.isEmpty else { throw FreemarkerError("Empty variable name in <#switch>") }
        let variable: String
        let switchDefault: String?
        if let bangRange = findDefaultBang(candidate) {
            variable = String(candidate[candidate.startIndex..<bangRange.lowerBound]).trimmingCharacters(in: .whitespaces)
            guard !variable.isEmpty else { throw FreemarkerError("Empty variable name in <#switch> before '!'") }
            if variable.contains("!") {
                throw FreemarkerError("Malformed <#switch> expression — unexpected '!' before the default operator: \(variable)")
            }
            if variable.contains("?") { throw FreemarkerError("Unsupported built-in in <#switch> expression: \(variable)") }
            try validateBareKey(variable, context: "<#switch>")
            switchDefault = try parseStringLiteral(String(candidate[bangRange.upperBound...]).trimmingCharacters(in: .whitespaces), context: "!")
        } else {
            if candidate.contains("!") {
                throw FreemarkerError("Unsupported '!' syntax in <#switch> expression — use variable!\"default\" with a quoted string literal")
            }
            if candidate.contains("?") { throw FreemarkerError("Unsupported built-in in <#switch> expression: \(candidate)") }
            variable = candidate
            try validateBareKey(variable, context: "<#switch>")
            switchDefault = nil
        }
        var cases: [FMSwitchCase] = []
        var defaultBody: [FMASTNode] = []
        var hasDefault = false

        while pos < tokens.count {
            switch tokens[pos] {
            case .endSwitch:
                pos += 1
                return .switchStatement(
                    variable: variable, switchDefault: switchDefault, transforms: transforms, cases: cases, defaultBody: defaultBody)
            case .caseDirective(let rawValue):
                if hasDefault {
                    throw FreemarkerError("<#case> after <#default> is not allowed — <#default> must be last")
                }
                pos += 1
                let value = try parseStringLiteral(rawValue, context: "case")
                let (body, hasBreak) = try parseFMSwitchCaseBody(depth: depth)
                cases.append(FMSwitchCase(value: value, body: body, hasBreak: hasBreak))
            case .defaultDirective:
                if hasDefault {
                    throw FreemarkerError("Duplicate <#default> inside <#switch>")
                }
                hasDefault = true
                pos += 1
                let (body, _) = try parseFMSwitchCaseBody(depth: depth)
                defaultBody = body
            case .text(let text):
                guard text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    let preview = String(text.prefix(30)).replacingOccurrences(of: "\n", with: "\\n")
                    throw FreemarkerError("Unexpected text inside <#switch> outside a <#case> or <#default>: \"\(preview)\"")
                }
                pos += 1
            default:
                throw FreemarkerError("Expected <#case>, <#default>, or </#switch> inside <#switch>")
            }
        }
        throw FreemarkerError("Unclosed <#switch> — missing </#switch>")
    }

    // Parses the body of a <#case> or <#default> block.
    // Delegates to parseBody(nestingContext: .switchBody) which returns when it sees a switch stop-token
    // (caseDirective, defaultDirective, endSwitch, breakDirective) without consuming it.
    // This method then checks whether the stop was a <#break> and consumes it if so.
    private func parseFMSwitchCaseBody(depth: Int) throws -> (nodes: [FMASTNode], hasBreak: Bool) {
        let nodes = try parseBody(nestingContext: .switchBody, depth: depth)
        if pos < tokens.count, case .breakDirective = tokens[pos] {
            pos += 1
            return (nodes, true)
        }
        return (nodes, false)
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private func parseCondition(_ expr: String) throws -> FMConditionExpr {
        let s = expr.trimmingCharacters(in: .whitespaces)

        // Parenthesized group — strip outer parens and recurse
        if s.hasPrefix("("),
            let closeIdx = matchingParen(s, from: s.startIndex),
            closeIdx == s.index(before: s.endIndex)
        {
            let inner = String(s[s.index(after: s.startIndex)..<closeIdx]).trimmingCharacters(in: .whitespaces)
            return try parseCondition(inner)
        }

        // OR — lowest precedence, split first so && binds tighter
        if let parts = splitOutsideQuotes(s, on: "||"), parts.count > 1 {
            var result = try parseCondition(parts[0])
            for part in parts.dropFirst() {
                result = .or(result, try parseCondition(part))
            }
            return result
        }

        // AND — higher precedence than OR
        if let parts = splitOutsideQuotes(s, on: "&&"), parts.count > 1 {
            var result = try parseCondition(parts[0])
            for part in parts.dropFirst() {
                result = .and(result, try parseCondition(part))
            }
            return result
        }

        // Negation: !condition — e.g. !Recipient.flag?boolean
        if s.hasPrefix("!") {
            let inner = String(s.dropFirst()).trimmingCharacters(in: .whitespaces)
            return .not(try parseCondition(inner))
        }

        // Exists check: variable??
        // ?trim?? or any other built-in before ?? is not supported
        if s.hasSuffix("??") {
            let varPart = String(s.dropLast(2)).trimmingCharacters(in: .whitespaces)
            if varPart.contains("?") {
                throw FreemarkerError("Built-in before ?? is not supported: \(varPart)")
            }
            try validateBareKey(varPart, context: "??")
            return .exists(varPart)
        }

        if let expr = try parseHasContent(s) { return expr }

        // Equality: variable == "literal" (optionally variable?trim == "literal" or (variable!"default") == "literal")
        // Spaces around == are optional — variable=="value" is also accepted.
        if let idx = findOperator("==", in: s) {
            let varPart = String(s[s.startIndex..<idx]).trimmingCharacters(in: .whitespaces)
            let rhsRaw = String(s[s.index(idx, offsetBy: 2)...]).trimmingCharacters(in: .whitespaces)
            if varPart.hasPrefix("\"") || varPart.hasPrefix("'") {
                throw FreemarkerError("String literal cannot be used as the left-hand side of == / != — put the variable on the left")
            }
            if varPart.hasSuffix("?number"), let numericValue = Double(rhsRaw) {
                if numericValue.isNaN || numericValue.isInfinite {
                    throw FreemarkerError("?number: '\(rhsRaw)' is not a valid finite numeric literal for == comparison")
                }
                let base = String(varPart.dropLast("?number".count)).trimmingCharacters(in: .whitespaces)
                let (variable, transforms) = parseStringTransforms(base)
                if let (key, defVal) = parseParenthesizedDefault(variable) {
                    return .numericCompareWithDefault(key, transforms, defVal, .equals, numericValue)
                }
                try throwIfMalformedParenthesizedDefault(variable, context: "?number")
                try validateBareKey(variable, context: "?number ==")
                return .numericCompare(variable, .equals, numericValue, transforms)
            }
            let literal = try parseStringLiteral(rhsRaw, context: "==")
            let (variable, transforms, defaultValue) = try parseVarExpr(varPart)
            if let defaultValue {
                return .equalsWithDefault(variable, defaultValue, transforms, literal, isParenDefaultForm(varPart))
            }
            return .equals(variable, transforms, literal)
        }

        // Inequality: variable != "literal" (optionally variable?trim != "literal" or (variable!"default") != "literal")
        // Spaces around != are optional — variable!="value" is also accepted.
        if let idx = findOperator("!=", in: s) {
            let varPart = String(s[s.startIndex..<idx]).trimmingCharacters(in: .whitespaces)
            let rhsRaw = String(s[s.index(idx, offsetBy: 2)...]).trimmingCharacters(in: .whitespaces)
            if varPart.hasPrefix("\"") || varPart.hasPrefix("'") {
                throw FreemarkerError("String literal cannot be used as the left-hand side of == / != — put the variable on the left")
            }
            if varPart.hasSuffix("?number"), let numericValue = Double(rhsRaw) {
                if numericValue.isNaN || numericValue.isInfinite {
                    throw FreemarkerError("?number: '\(rhsRaw)' is not a valid finite numeric literal for != comparison")
                }
                let base = String(varPart.dropLast("?number".count)).trimmingCharacters(in: .whitespaces)
                let (variable, transforms) = parseStringTransforms(base)
                if let (key, defVal) = parseParenthesizedDefault(variable) {
                    return .numericCompareWithDefault(key, transforms, defVal, .notEquals, numericValue)
                }
                try throwIfMalformedParenthesizedDefault(variable, context: "?number")
                try validateBareKey(variable, context: "?number !=")
                return .numericCompare(variable, .notEquals, numericValue, transforms)
            }
            let literal = try parseStringLiteral(rhsRaw, context: "!=")
            let (variable, transforms, defaultValue) = try parseVarExpr(varPart)
            if let defaultValue {
                return .notEqualsWithDefault(variable, defaultValue, transforms, literal, isParenDefaultForm(varPart))
            }
            return .notEquals(variable, transforms, literal)
        }

        if let expr = try parseNumericCompare(s) { return expr }

        if let expr = try parseBooleanBuiltin(s) { return expr }

        throw FreemarkerError("Unsupported condition expression: \(s)")
    }

    private func parseInterpolation(_ expr: String) throws -> FMInterpolationExpr {
        let s = expr.trimmingCharacters(in: .whitespaces)

        if s.hasPrefix("!") {
            throw FreemarkerError("Leading '!' is not valid in ${} interpolation — use ${x!\"default\"} to provide a fallback value")
        }

        // Concatenation: parts joined by "+" (spaces optional) — string literals, variable references, and string transforms (?trim, ?lower_case, ?upper_case)
        // Must precede parseStringTransformInterpolation to avoid matching a trailing transform on the last concat operand
        if let parts = splitOutsideQuotes(s, on: "+"), parts.count > 1 {
            let concatParts: [FMConcatPart] = try parts.map { part in
                let p = part.trimmingCharacters(in: .whitespaces)
                if p.isEmpty {
                    throw FreemarkerError("Malformed concatenation: empty operand in \(s)")
                }
                if p.hasPrefix("\"") || p.hasPrefix("'") {
                    return try .literal(parseStringLiteral(p, context: "+"))
                }
                // (key!"default")?transforms* as a concat operand
                if p.hasPrefix("("), let closeIdx = findMatchingParen(p) {
                    let innerStart = p.index(after: p.startIndex)
                    let inner = String(p[innerStart..<closeIdx]).trimmingCharacters(in: .whitespaces)
                    if let bangRange = findDefaultBang(inner) {
                        let varSection = String(inner[inner.startIndex..<bangRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                        if varSection.contains("?") {
                            throw FreemarkerError("Built-in chains inside (key!\"default\") are not supported in + concatenation: \(varSection)")
                        }
                        let defaultPart = String(inner[bangRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                        let defaultValue = try parseStringLiteral(defaultPart, context: "!")
                        let (remaining, concatTransforms) = parseStringTransforms(
                            String(p[p.index(after: closeIdx)...]).trimmingCharacters(in: .whitespaces))
                        if !remaining.isEmpty {
                            throw FreemarkerError(
                                // swiftlint:disable:next line_length
                                "Unsupported syntax after ) in concat paren-default operand: \(remaining) — only ?trim, ?lower_case, ?upper_case are allowed"
                            )
                        }
                        try validateBareKey(varSection, context: "+ concatenation")
                        return .parenDefault(varSection, concatTransforms, defaultValue)
                    }
                }
                let (varName, transforms) = parseStringTransforms(p)
                if !transforms.isEmpty {
                    if varName.isEmpty {
                        throw FreemarkerError("Malformed concatenation: empty operand in \(s)")
                    }
                    try validateBareKey(varName, context: "+ concatenation")
                    return .variable(varName, transforms)
                }
                if p.contains("!") {
                    throw FreemarkerError("Default operator '!' is not supported in + concatenation — use ${x!\"default\"} outside the concatenation")
                }
                if p.contains("?") {
                    // Built-ins that are not string transforms (?number, ?boolean, ?has_content, ?date, ?datetime)
                    // don't produce string output and have no meaningful role in a + concatenation expression.
                    throw FreemarkerError("Only ?trim, ?lower_case, and ?upper_case are supported in + concatenation: \(p)")
                }
                try validateBareKey(p, context: "+ concatenation")
                return .variable(p, [])
            }
            return .concat(concatParts)
        }

        // (key!"default")?transforms* in interpolation — paren-default with optional trailing transforms
        if s.hasPrefix("("), let closeIdx = findMatchingParen(s) {
            let innerStart = s.index(after: s.startIndex)
            let inner = String(s[innerStart..<closeIdx]).trimmingCharacters(in: .whitespaces)
            let after = String(s[s.index(after: closeIdx)...]).trimmingCharacters(in: .whitespaces)
            if let bangRange = findDefaultBang(inner) {
                let varSection = String(inner[inner.startIndex..<bangRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                if varSection.contains("?") {
                    throw FreemarkerError("Built-in chains inside (key!\"default\") are not supported — use a plain property key: \(varSection)")
                }
                let defaultPart = String(inner[bangRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                let defaultValue = try parseStringLiteral(defaultPart, context: "!")
                let (remaining, transforms) = parseStringTransforms(after)
                if !remaining.isEmpty {
                    throw FreemarkerError(
                        "Unsupported syntax after ) in paren-default expression: \(remaining) — only ?trim, ?lower_case, ?upper_case are allowed")
                }
                try validateBareKey(varSection, context: "${} interpolation")
                return .parenDefaultWithTransform(varSection, transforms, defaultValue)
            }
        }

        if let expr = try parseStringTransformInterpolation(s) { return expr }

        // Default value: variable!"literal" or bare variable! (empty-string default, with optional transforms)
        if let bangIdx = defaultOperatorIndex(in: s) {
            let varPart = String(s[s.startIndex..<bangIdx]).trimmingCharacters(in: .whitespaces)
            let defaultPart = String(s[s.index(after: bangIdx)...]).trimmingCharacters(in: .whitespaces)
            let defaultValue = defaultPart.isEmpty ? "" : try parseStringLiteral(defaultPart, context: "!")
            let (variable, transforms) = parseStringTransforms(varPart)
            if variable.contains("?") { throw FreemarkerError("Unsupported built-in in ${} interpolation: \(varPart)") }
            try validateBareKey(variable, context: "${} default")
            return .withDefault(variable, transforms, defaultValue)
        }

        if s.contains("?") { throw FreemarkerError("Unsupported built-in in ${} interpolation: \(s)") }
        try validateBareKey(s, context: "${} interpolation")
        return .variable(s, [])
    }

    /// Returns the index of the `!` default operator, if present.
    /// The `!` must not be inside a quoted string and must not be at the start of the expression.
    /// The position-0 exclusion handles the FreeMarker "missing value test" prefix (e.g. `!varName`),
    /// which is a different construct and not supported here.
    private func defaultOperatorIndex(in s: String) -> String.Index? {
        var inQuotes = false
        var quoteChar: Character = "\""
        for idx in s.indices {
            let c = s[idx]
            if inQuotes {
                if c == quoteChar { inQuotes = false }
            } else if c == "\"" || c == "'" {
                inQuotes = true
                quoteChar = c
            } else if c == "!" && idx != s.startIndex {
                return idx
            }
        }
        return nil
    }

    /// Splits `s` on every occurrence of `op` that is not inside a quoted string or parentheses.
    /// Returns nil if `op` does not appear outside quotes/parens (i.e. no split needed).
    private func splitOutsideQuotes(_ s: String, on op: String) -> [String]? {
        var parts: [String] = []
        var segmentStart = s.startIndex
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
                i = s.index(after: i)
            } else if parenDepth < 0 {
                return nil  // unbalanced closing paren
            } else if parenDepth == 0 && s[i...].hasPrefix(op) {
                parts.append(String(s[segmentStart..<i]).trimmingCharacters(in: .whitespaces))
                i = s.index(i, offsetBy: op.count)
                segmentStart = i
            } else {
                i = s.index(after: i)
            }
        }
        guard !parts.isEmpty else { return nil }
        guard parenDepth == 0 else { return nil }  // unclosed paren
        parts.append(String(s[segmentStart...]).trimmingCharacters(in: .whitespaces))
        return parts
    }

    /// Returns the index of the `)` matching the `(` at `from`, or nil if unbalanced.
    private func matchingParen(_ s: String, from: String.Index) -> String.Index? {
        guard s[from] == "(" else { return nil }
        var depth = 0
        var inQuotes = false
        var quoteChar: Character = "\""
        var i = from
        while i < s.endIndex {
            let c = s[i]
            if inQuotes {
                if c == quoteChar { inQuotes = false }
            } else if c == "\"" || c == "'" {
                inQuotes = true
                quoteChar = c
            } else if c == "(" {
                depth += 1
            } else if c == ")" {
                depth -= 1
                if depth == 0 { return i }
            }
            i = s.index(after: i)
        }
        return nil
    }

    /// Returns the index of the first occurrence of `op` in `s` that is not inside a quoted string or parentheses.
    /// Used to find `==` and `!=` operators with optional surrounding whitespace.
    private func findOperator(_ op: String, in s: String) -> String.Index? {
        var inQuotes = false
        var quoteChar: Character = "\""
        var parenDepth = 0
        var i = s.startIndex
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
                if parenDepth < 0 { return nil }  // unbalanced — stop, consistent with splitOutsideQuotes
                i = s.index(after: i)
            } else if parenDepth == 0 && s[i...].hasPrefix(op) {
                return i
            } else {
                i = s.index(after: i)
            }
        }
        return nil
    }

    // Parses the LHS of a == / != condition, handling optional outer parens and ! default syntax.
    // Returns (variable, transforms, defaultValue?) where defaultValue is non-nil when ! is present.
    // True only for the paren-default form (key!"default")?transforms — i.e. the `!` falls inside the
    // leading parenthesised group. Grouping parens like (key?trim)!"d" (bang after the `)`) are NOT
    // paren-default and must still throw when the key is missing and transforms are present.
    private func isParenDefaultForm(_ varPart: String) -> Bool {
        let t = varPart.trimmingCharacters(in: .whitespaces)
        guard t.hasPrefix("("), let close = t.firstIndex(of: ")"), let bang = t.firstIndex(of: "!") else { return false }
        return bang > t.startIndex && bang < close
    }

    func parseVarExpr(_ varPart: String) throws -> (variable: String, transforms: [FMStringTransform], defaultValue: String?) {
        var s = varPart.trimmingCharacters(in: .whitespaces)
        // (key!"default")?transforms* — paren-default with optional trailing string transforms
        if s.hasPrefix("("), let closeIdx = findMatchingParen(s) {
            let innerStart = s.index(after: s.startIndex)
            let inner = String(s[innerStart..<closeIdx]).trimmingCharacters(in: .whitespaces)
            let after = String(s[s.index(after: closeIdx)...]).trimmingCharacters(in: .whitespaces)
            if let bangRange = findDefaultBang(inner) {
                let varSection = String(inner[inner.startIndex..<bangRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                if varSection.contains("?") {
                    throw FreemarkerError("Built-in chains inside (key!\"default\") are not supported — use a plain property key: \(varSection)")
                }
                let defaultPart = String(inner[bangRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                let defaultValue = try parseStringLiteral(defaultPart, context: "!")
                let (remaining, transforms) = parseStringTransforms(after)
                if !remaining.isEmpty {
                    throw FreemarkerError(
                        "Unsupported syntax after ) in paren-default expression: \(remaining) — only ?trim, ?lower_case, ?upper_case are allowed")
                }
                try rejectTerminalBuiltin(varSection)
                return (varSection, transforms, defaultValue)
            }
        }
        if s.hasPrefix("(") && s.hasSuffix(")") {
            s = String(s.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)
        }
        if s.hasPrefix("\"") || s.hasPrefix("'") {
            throw FreemarkerError("String literal cannot be used as the left-hand side of == / != — put the variable on the left")
        }
        if let bangRange = findDefaultBang(s) {
            let varSection = String(s[s.startIndex..<bangRange.lowerBound]).trimmingCharacters(in: .whitespaces)
            let defaultPart = String(s[bangRange.upperBound...]).trimmingCharacters(in: .whitespaces)
            let defaultValue = try parseStringLiteral(defaultPart, context: "!")
            let (variable, transforms) = parseStringTransforms(varSection)
            try rejectTerminalBuiltin(variable)
            return (variable, transforms, defaultValue)
        }
        // Bare ! (no explicit default) — x! or x?transforms! — uses "" as the default value
        if s.hasSuffix("!") {
            let varSection = String(s.dropLast()).trimmingCharacters(in: .whitespaces)
            let (variable, transforms) = parseStringTransforms(varSection)
            try rejectTerminalBuiltin(variable)
            return (variable, transforms, "")
        }
        let (variable, transforms) = parseStringTransforms(s)
        try rejectTerminalBuiltin(variable)
        return (variable, transforms, nil)
    }

    // Throws if a resolved key still contains parentheses — indicates an unrecognised paren form that
    // would silently mis-key the property lookup. The one legitimate paren form (key!"default") is fully
    // consumed by the parser before any key reaches this point, so parens here are always a bug.
    func validateBareKey(_ key: String, context: String) throws {
        if key.contains("(") || key.contains(")") {
            throw FreemarkerError("Invalid property key '\(key)' in \(context) — parentheses are not valid in a bare key name")
        }
    }

    // Throws if the variable name still ends with a terminal built-in that can't be used in == / !=.
    private func rejectTerminalBuiltin(_ variable: String) throws {
        try validateBareKey(variable, context: "== / != condition")
        if variable.hasSuffix("?boolean") || variable.hasSuffix("?has_content") {
            let t = variable.hasSuffix("?boolean") ? "?boolean" : "?has_content"
            throw FreemarkerError("\(t) produces a boolean — use it as a standalone <#if> condition")
        }
        if variable.hasSuffix("?number") {
            throw FreemarkerError(
                "?number with a quoted string RHS is not supported — use an unquoted numeric literal (e.g. ?number == 10) or gt/gte/lt/lte operators")
        }
        if variable.hasSuffix("?date") || variable.hasSuffix("?datetime") {
            let t = variable.hasSuffix("?datetime") ? "?datetime" : "?date"
            throw FreemarkerError("\(t) produces a date — use gt/gte/lt/lte for date comparisons")
        }
    }

    // Returns the String.Index of the ) that closes the ( at s.startIndex, respecting nested parens and quoted strings.
    private func findMatchingParen(_ s: String) -> String.Index? {
        matchingParen(s, from: s.startIndex)
    }

    // Finds the index range of ! immediately followed by a quote character, outside quoted strings.
    // This distinguishes the default-value ! from the != operator (which has = after the !).
    private func findDefaultBang(_ s: String) -> Range<String.Index>? {
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
            } else if c == "!" && next < s.endIndex && (s[next] == "\"" || s[next] == "'") {
                return i..<next
            }
            i = next
        }
        return nil
    }

    func parseStringLiteral(_ s: String, context: String) throws -> String {
        let trimmed = s.trimmingCharacters(in: .whitespaces)
        if trimmed.count >= 2 {
            let quote = trimmed.first!
            if (quote == "\"" || quote == "'") && trimmed.last! == quote {
                let interior = String(trimmed.dropFirst().dropLast())
                if !interior.contains(quote) {
                    return interior
                }
            }
        }
        throw FreemarkerError("Expected string literal for \(context) operator, got: \(trimmed)")
    }
}
