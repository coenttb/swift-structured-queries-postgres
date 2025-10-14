import Foundation
import StructuredQueriesCore

// MARK: - Pattern Matching Functions
//
// PostgreSQL Chapter 9.7: Pattern Matching
// https://www.postgresql.org/docs/18/functions-matching.html
//
// Advanced pattern matching functions beyond basic LIKE/ILIKE operators.

// MARK: - SIMILAR TO Operator

extension QueryExpression where QueryValue == String {
    /// PostgreSQL's `SIMILAR TO` operator - SQL standard regular expressions
    ///
    /// Combines features of LIKE and POSIX regular expressions.
    ///
    /// ```swift
    /// User.where { $0.email.similarTo("%@(gmail|yahoo).com") }
    /// // SELECT … FROM "users" WHERE ("users"."email" SIMILAR TO '%@(gmail|yahoo).com')
    ///
    /// Product.where { $0.code.similarTo("A[0-9]{3}") }
    /// // SELECT … FROM "products" WHERE ("products"."code" SIMILAR TO 'A[0-9]{3}')
    /// ```
    ///
    /// **Pattern Syntax:**
    /// - `%` matches any sequence of characters (like LIKE)
    /// - `_` matches exactly one character (like LIKE)
    /// - `|` denotes alternation (either of two alternatives)
    /// - `*` denotes repetition of the previous item zero or more times
    /// - `+` denotes repetition of the previous item one or more times
    /// - `?` denotes the previous item is optional (zero or one time)
    /// - `{m}` denotes repetition exactly m times
    /// - `{m,}` denotes repetition m or more times
    /// - `{m,n}` denotes repetition at least m and at most n times
    /// - `()` groups items into a single logical item
    /// - `[...]` specifies a character class
    ///
    /// - Parameters:
    ///   - pattern: The SQL regex pattern to match against
    ///   - escape: Optional escape character for literal matching
    /// - Returns: A boolean expression indicating whether the string matches the pattern
    ///
    /// > Note: SIMILAR TO is part of SQL standard, but less powerful than POSIX regex
    public func similarTo(
        _ pattern: some StringProtocol,
        escape: Character? = nil
    ) -> some QueryExpression<Bool> {
        SimilarToOperator(string: self, pattern: "\(pattern)", escape: escape)
    }

    /// PostgreSQL's `NOT SIMILAR TO` operator - negated SQL regex match
    ///
    /// ```swift
    /// User.where { $0.username.notSimilarTo("%[^a-zA-Z0-9_]%") }
    /// // SELECT … FROM "users" WHERE ("users"."username" NOT SIMILAR TO '%[^a-zA-Z0-9_]%')
    /// ```
    ///
    /// - Parameters:
    ///   - pattern: The SQL regex pattern that should NOT match
    ///   - escape: Optional escape character for literal matching
    /// - Returns: A boolean expression indicating whether the string does NOT match the pattern
    public func notSimilarTo(
        _ pattern: some StringProtocol,
        escape: Character? = nil
    ) -> some QueryExpression<Bool> {
        NotSimilarToOperator(string: self, pattern: "\(pattern)", escape: escape)
    }
}

// MARK: - POSIX Regular Expression Operators

extension QueryExpression where QueryValue == String {
    /// PostgreSQL's `~` operator - case-sensitive POSIX regex match
    ///
    /// More powerful than SIMILAR TO, using full POSIX Extended Regular Expressions.
    ///
    /// ```swift
    /// User.where { $0.email.regexMatch("^[a-z0-9._%+-]+@[a-z0-9.-]+\\.[a-z]{2,}$") }
    /// // SELECT … FROM "users" WHERE ("users"."email" ~ '^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$')
    ///
    /// Product.where { $0.sku.regexMatch("^[A-Z]{3}-\\d{6}$") }
    /// // SELECT … FROM "products" WHERE ("products"."sku" ~ '^[A-Z]{3}-\d{6}$')
    /// ```
    ///
    /// **Pattern Syntax** (POSIX Extended Regular Expressions):
    /// - `.` matches any single character
    /// - `^` matches start of string
    /// - `$` matches end of string
    /// - `*` zero or more repetitions
    /// - `+` one or more repetitions
    /// - `?` zero or one repetition
    /// - `{m,n}` at least m, at most n repetitions
    /// - `|` alternation
    /// - `()` grouping
    /// - `[...]` character class
    /// - `\` escape character
    ///
    /// - Parameter pattern: The POSIX regex pattern to match against
    /// - Returns: A boolean expression indicating whether the string matches the pattern
    ///
    /// > Note: For case-insensitive matching, use `regexMatchCaseInsensitive()`
    public func regexMatch(_ pattern: some StringProtocol) -> some QueryExpression<Bool> {
        RegexMatchOperator(string: self, pattern: "\(pattern)")
    }

    /// PostgreSQL's `~*` operator - case-insensitive POSIX regex match
    ///
    /// ```swift
    /// User.where { $0.username.regexMatchCaseInsensitive("^admin") }
    /// // SELECT … FROM "users" WHERE ("users"."username" ~* '^admin')
    /// ```
    ///
    /// - Parameter pattern: The POSIX regex pattern to match against (case-insensitive)
    /// - Returns: A boolean expression indicating whether the string matches the pattern
    public func regexMatchCaseInsensitive(_ pattern: some StringProtocol) -> some QueryExpression<
        Bool
    > {
        RegexMatchCaseInsensitiveOperator(string: self, pattern: "\(pattern)")
    }

    /// PostgreSQL's `!~` operator - case-sensitive POSIX regex non-match
    ///
    /// ```swift
    /// User.where { $0.username.regexNotMatch("[^a-zA-Z0-9_]") }
    /// // SELECT … FROM "users" WHERE ("users"."username" !~ '[^a-zA-Z0-9_]')
    /// ```
    ///
    /// - Parameter pattern: The POSIX regex pattern that should NOT match
    /// - Returns: A boolean expression indicating whether the string does NOT match the pattern
    public func regexNotMatch(_ pattern: some StringProtocol) -> some QueryExpression<Bool> {
        RegexNotMatchOperator(string: self, pattern: "\(pattern)")
    }

    /// PostgreSQL's `!~*` operator - case-insensitive POSIX regex non-match
    ///
    /// ```swift
    /// User.where { $0.email.regexNotMatchCaseInsensitive("(spam|junk)") }
    /// // SELECT … FROM "users" WHERE ("users"."email" !~* '(spam|junk)')
    /// ```
    ///
    /// - Parameter pattern: The POSIX regex pattern that should NOT match (case-insensitive)
    /// - Returns: A boolean expression indicating whether the string does NOT match the pattern
    public func regexNotMatchCaseInsensitive(_ pattern: some StringProtocol)
        -> some QueryExpression<Bool>
    {
        RegexNotMatchCaseInsensitiveOperator(string: self, pattern: "\(pattern)")
    }
}

// MARK: - Regular Expression Functions

extension QueryExpression where QueryValue == String {
    /// PostgreSQL's `regexp_like(string, pattern)` function - boolean regex match
    ///
    /// Equivalent to the `~` operator, but in function form for composability.
    ///
    /// ```swift
    /// User.where { $0.email.regexpLike("^[a-z]+@example\\.com$") }
    /// // SELECT … FROM "users" WHERE regexp_like("users"."email", '^[a-z]+@example\.com$')
    /// ```
    ///
    /// - Parameters:
    ///   - pattern: The POSIX regex pattern to match against
    ///   - flags: Optional regex flags ('i' for case-insensitive, 'g' for global, etc.)
    /// - Returns: A boolean expression indicating whether the string matches the pattern
    public func regexpLike(
        _ pattern: some StringProtocol,
        flags: String? = nil
    ) -> some QueryExpression<Bool> {
        if let flags {
            return SQLQueryExpression(
                "regexp_like(\(self.queryFragment), \(bind: String(pattern)), \(bind: flags))",
                as: Bool.self
            )
        } else {
            return SQLQueryExpression(
                "regexp_like(\(self.queryFragment), \(bind: String(pattern)))",
                as: Bool.self
            )
        }
    }

    /// PostgreSQL's `regexp_count(string, pattern)` function - count regex matches
    ///
    /// Returns the number of times the pattern matches in the string.
    ///
    /// ```swift
    /// Article.select { $0.content.regexpCount("\\bthe\\b") }
    /// // SELECT regexp_count("articles"."content", '\bthe\b') FROM "articles"
    /// ```
    ///
    /// - Parameters:
    ///   - pattern: The POSIX regex pattern to count matches for
    ///   - start: Optional starting position (1-indexed)
    ///   - flags: Optional regex flags
    /// - Returns: An integer expression with the count of matches
    public func regexpCount(
        _ pattern: some StringProtocol,
        start: Int? = nil,
        flags: String? = nil
    ) -> some QueryExpression<Int> {
        if let start, let flags {
            return SQLQueryExpression(
                "regexp_count(\(self.queryFragment), \(bind: String(pattern)), \(start), \(bind: flags))",
                as: Int.self
            )
        } else if let start {
            return SQLQueryExpression(
                "regexp_count(\(self.queryFragment), \(bind: String(pattern)), \(start))",
                as: Int.self
            )
        } else if let flags {
            return SQLQueryExpression(
                "regexp_count(\(self.queryFragment), \(bind: String(pattern)), 1, \(bind: flags))",
                as: Int.self
            )
        } else {
            return SQLQueryExpression(
                "regexp_count(\(self.queryFragment), \(bind: String(pattern)))",
                as: Int.self
            )
        }
    }

    /// PostgreSQL's `regexp_instr(string, pattern)` function - find regex match position
    ///
    /// Returns the position (1-indexed) where the pattern first matches, or 0 if no match.
    ///
    /// ```swift
    /// Log.where { $0.message.regexpInstr("error|warning") > 0 }
    /// // SELECT … FROM "logs" WHERE regexp_instr("logs"."message", 'error|warning') > 0
    /// ```
    ///
    /// - Parameters:
    ///   - pattern: The POSIX regex pattern to find
    ///   - start: Optional starting position (1-indexed)
    ///   - n: Optional occurrence number (which match to return position for)
    ///   - flags: Optional regex flags
    /// - Returns: An integer expression with the match position (1-indexed, or 0 if no match)
    public func regexpInstr(
        _ pattern: some StringProtocol,
        start: Int? = nil,
        occurrence n: Int? = nil,
        flags: String? = nil
    ) -> some QueryExpression<Int> {
        if let start, let n, let flags {
            return SQLQueryExpression(
                "regexp_instr(\(self.queryFragment), \(bind: String(pattern)), \(start), \(n), \(bind: flags))",
                as: Int.self
            )
        } else if let start, let n {
            return SQLQueryExpression(
                "regexp_instr(\(self.queryFragment), \(bind: String(pattern)), \(start), \(n))",
                as: Int.self
            )
        } else if let start, let flags {
            return SQLQueryExpression(
                "regexp_instr(\(self.queryFragment), \(bind: String(pattern)), \(start), 1, \(bind: flags))",
                as: Int.self
            )
        } else if let start {
            return SQLQueryExpression(
                "regexp_instr(\(self.queryFragment), \(bind: String(pattern)), \(start))",
                as: Int.self
            )
        } else if let n, let flags {
            return SQLQueryExpression(
                "regexp_instr(\(self.queryFragment), \(bind: String(pattern)), 1, \(n), \(bind: flags))",
                as: Int.self
            )
        } else if let n {
            return SQLQueryExpression(
                "regexp_instr(\(self.queryFragment), \(bind: String(pattern)), 1, \(n))",
                as: Int.self
            )
        } else if let flags {
            return SQLQueryExpression(
                "regexp_instr(\(self.queryFragment), \(bind: String(pattern)), 1, 1, \(bind: flags))",
                as: Int.self
            )
        } else {
            return SQLQueryExpression(
                "regexp_instr(\(self.queryFragment), \(bind: String(pattern)))",
                as: Int.self
            )
        }
    }

    /// PostgreSQL's `regexp_replace(string, pattern, replacement)` function - replace regex matches
    ///
    /// Replaces all matches of the pattern with the replacement string.
    ///
    /// ```swift
    /// User.update { $0.phone = $0.phone.regexpReplace("[^0-9]", "") }
    /// // UPDATE "users" SET "phone" = regexp_replace("users"."phone", '[^0-9]', '')
    /// ```
    ///
    /// - Parameters:
    ///   - pattern: The POSIX regex pattern to match
    ///   - replacement: The replacement string (can include `\1`, `\2` for capture groups)
    ///   - start: Optional starting position (1-indexed)
    ///   - flags: Optional regex flags ('g' for global is default)
    /// - Returns: A string expression with replacements applied
    public func regexpReplace(
        _ pattern: some StringProtocol,
        _ replacement: some StringProtocol,
        start: Int? = nil,
        flags: String? = nil
    ) -> some QueryExpression<String> {
        if let start, let flags {
            return SQLQueryExpression(
                "regexp_replace(\(self.queryFragment), \(bind: String(pattern)), \(bind: String(replacement)), \(start), \(bind: flags))",
                as: String.self
            )
        } else if let start {
            return SQLQueryExpression(
                "regexp_replace(\(self.queryFragment), \(bind: String(pattern)), \(bind: String(replacement)), \(start))",
                as: String.self
            )
        } else if let flags {
            return SQLQueryExpression(
                "regexp_replace(\(self.queryFragment), \(bind: String(pattern)), \(bind: String(replacement)), 1, \(bind: flags))",
                as: String.self
            )
        } else {
            return SQLQueryExpression(
                "regexp_replace(\(self.queryFragment), \(bind: String(pattern)), \(bind: String(replacement)))",
                as: String.self
            )
        }
    }

    /// PostgreSQL's `regexp_substr(string, pattern)` function - extract matching substring
    ///
    /// Returns the substring that matches the pattern, or NULL if no match.
    ///
    /// ```swift
    /// Log.select { $0.message.regexpSubstr("ERROR: .*") }
    /// // SELECT regexp_substr("logs"."message", 'ERROR: .*') FROM "logs"
    /// ```
    ///
    /// - Parameters:
    ///   - pattern: The POSIX regex pattern to extract
    ///   - start: Optional starting position (1-indexed)
    ///   - n: Optional occurrence number (which match to extract)
    ///   - flags: Optional regex flags
    /// - Returns: An optional string expression with the matching substring
    public func regexpSubstr(
        _ pattern: some StringProtocol,
        start: Int? = nil,
        occurrence n: Int? = nil,
        flags: String? = nil
    ) -> some QueryExpression<String?> {
        if let start, let n, let flags {
            return SQLQueryExpression(
                "regexp_substr(\(self.queryFragment), \(bind: String(pattern)), \(start), \(n), \(bind: flags))",
                as: String?.self
            )
        } else if let start, let n {
            return SQLQueryExpression(
                "regexp_substr(\(self.queryFragment), \(bind: String(pattern)), \(start), \(n))",
                as: String?.self
            )
        } else if let start, let flags {
            return SQLQueryExpression(
                "regexp_substr(\(self.queryFragment), \(bind: String(pattern)), \(start), 1, \(bind: flags))",
                as: String?.self
            )
        } else if let start {
            return SQLQueryExpression(
                "regexp_substr(\(self.queryFragment), \(bind: String(pattern)), \(start))",
                as: String?.self
            )
        } else if let n, let flags {
            return SQLQueryExpression(
                "regexp_substr(\(self.queryFragment), \(bind: String(pattern)), 1, \(n), \(bind: flags))",
                as: String?.self
            )
        } else if let n {
            return SQLQueryExpression(
                "regexp_substr(\(self.queryFragment), \(bind: String(pattern)), 1, \(n))",
                as: String?.self
            )
        } else if let flags {
            return SQLQueryExpression(
                "regexp_substr(\(self.queryFragment), \(bind: String(pattern)), 1, 1, \(bind: flags))",
                as: String?.self
            )
        } else {
            return SQLQueryExpression(
                "regexp_substr(\(self.queryFragment), \(bind: String(pattern)))",
                as: String?.self
            )
        }
    }
}

// MARK: - Internal Operator Types

/// Internal operator type for `SIMILAR TO` expressions
private struct SimilarToOperator<
    LHS: QueryExpression<String>,
    RHS: QueryExpression<String>
>: QueryExpression {
    typealias QueryValue = Bool

    let string: LHS
    let pattern: RHS
    let escape: Character?

    var queryFragment: QueryFragment {
        var query: QueryFragment = "(\(string.queryFragment) SIMILAR TO \(pattern.queryFragment)"
        if let escape {
            query.append(" ESCAPE \(bind: String(escape))")
        }
        query.append(")")
        return query
    }
}

/// Internal operator type for `NOT SIMILAR TO` expressions
private struct NotSimilarToOperator<
    LHS: QueryExpression<String>,
    RHS: QueryExpression<String>
>: QueryExpression {
    typealias QueryValue = Bool

    let string: LHS
    let pattern: RHS
    let escape: Character?

    var queryFragment: QueryFragment {
        var query: QueryFragment =
            "(\(string.queryFragment) NOT SIMILAR TO \(pattern.queryFragment)"
        if let escape {
            query.append(" ESCAPE \(bind: String(escape))")
        }
        query.append(")")
        return query
    }
}

/// Internal operator type for `~` (regex match) expressions
private struct RegexMatchOperator<
    LHS: QueryExpression<String>,
    RHS: QueryExpression<String>
>: QueryExpression {
    typealias QueryValue = Bool

    let string: LHS
    let pattern: RHS

    var queryFragment: QueryFragment {
        "(\(string.queryFragment) ~ \(pattern.queryFragment))"
    }
}

/// Internal operator type for `~*` (regex match case-insensitive) expressions
private struct RegexMatchCaseInsensitiveOperator<
    LHS: QueryExpression<String>,
    RHS: QueryExpression<String>
>: QueryExpression {
    typealias QueryValue = Bool

    let string: LHS
    let pattern: RHS

    var queryFragment: QueryFragment {
        "(\(string.queryFragment) ~* \(pattern.queryFragment))"
    }
}

/// Internal operator type for `!~` (regex non-match) expressions
private struct RegexNotMatchOperator<
    LHS: QueryExpression<String>,
    RHS: QueryExpression<String>
>: QueryExpression {
    typealias QueryValue = Bool

    let string: LHS
    let pattern: RHS

    var queryFragment: QueryFragment {
        "(\(string.queryFragment) !~ \(pattern.queryFragment))"
    }
}

/// Internal operator type for `!~*` (regex non-match case-insensitive) expressions
private struct RegexNotMatchCaseInsensitiveOperator<
    LHS: QueryExpression<String>,
    RHS: QueryExpression<String>
>: QueryExpression {
    typealias QueryValue = Bool

    let string: LHS
    let pattern: RHS

    var queryFragment: QueryFragment {
        "(\(string.queryFragment) !~* \(pattern.queryFragment))"
    }
}
