import Foundation
import StructuredQueriesCore

// MARK: - PostgreSQL Pattern Matching (ILIKE)

extension QueryExpression where QueryValue == String {
    /// PostgreSQL's `ILIKE` operator - case-insensitive pattern matching
    ///
    /// Similar to `LIKE`, but performs case-insensitive matching. This is a PostgreSQL-specific
    /// extension and is more efficient than using `LOWER()` with `LIKE`.
    ///
    /// ```swift
    /// Reminder.where { $0.title.ilike("%buy%") }
    /// // SELECT … FROM "reminders" WHERE ("reminders"."title" ILIKE '%buy%')
    ///
    /// // Case-insensitive search (matches "Buy", "BUY", "buy", etc.)
    /// User.where { $0.name.ilike("john%") }
    /// // SELECT … FROM "users" WHERE ("users"."name" ILIKE 'john%')
    /// ```
    ///
    /// **Pattern Syntax:**
    /// - `%` matches any sequence of characters (including zero characters)
    /// - `_` matches exactly one character
    /// - Use `ESCAPE` clause to match literal `%` or `_` characters
    ///
    /// - Parameters:
    ///   - pattern: The pattern to match against (can include `%` and `_` wildcards)
    ///   - escape: Optional escape character for literal `%` or `_` matching
    /// - Returns: A boolean expression indicating whether the string matches the pattern
    public func ilike(
        _ pattern: some StringProtocol,
        escape: Character? = nil
    ) -> some QueryExpression<Bool> {
        IlikeOperator(string: self, pattern: "\(pattern)", escape: escape)
    }
}

/// Internal operator type for `ILIKE` expressions
private struct IlikeOperator<
    LHS: QueryExpression<String>,
    RHS: QueryExpression<String>
>: QueryExpression {
    typealias QueryValue = Bool

    let string: LHS
    let pattern: RHS
    let escape: Character?

    var queryFragment: QueryFragment {
        var query: QueryFragment = "(\(string.queryFragment) ILIKE \(pattern.queryFragment)"
        if let escape {
            query.append(" ESCAPE \(bind: String(escape))")
        }
        query.append(")")
        return query
    }
}
