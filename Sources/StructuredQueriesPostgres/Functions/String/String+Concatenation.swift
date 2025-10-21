import Foundation
import StructuredQueriesCore

// MARK: - String Concatenation Functions
//
// PostgreSQL Chapter 9.4: String Functions and Operators
// https://www.postgresql.org/docs/18/functions-string.html
//
// Functions for concatenating strings: || operator, concat_ws()

extension PostgreSQL.String {
    /// Concatenates two strings using PostgreSQL's || operator
    ///
    /// PostgreSQL's `||` operator.
    ///
    /// ```swift
    /// PostgreSQL.String.concat($0.firstName, " ", $0.lastName)
    /// // SELECT ("users"."firstName" || ' ' || "users"."lastName") FROM "users"
    /// ```
    ///
    /// - Parameters:
    ///   - value: The first string expression
    ///   - other: The string to append
    /// - Returns: The concatenated string
    public static func concat(
        _ value: some QueryExpression<Swift.String>,
        _ other: Swift.String
    ) -> some QueryExpression<Swift.String> {
        SQLQueryExpression(
            "(\(value.queryFragment) || \(bind: other))",
            as: Swift.String.self
        )
    }

    /// Concatenates two string expressions using PostgreSQL's || operator
    ///
    /// PostgreSQL's `||` operator.
    public static func concat(
        _ value: some QueryExpression<Swift.String>,
        _ other: some QueryExpression<Swift.String>
    ) -> some QueryExpression<Swift.String> {
        SQLQueryExpression(
            "(\(value.queryFragment) || \(other.queryFragment))",
            as: Swift.String.self
        )
    }

    /// Concatenates strings with a separator, ignoring NULL values
    ///
    /// PostgreSQL's `concat_ws(separator, str1, str2, ...)` function.
    ///
    /// ```swift
    /// PostgreSQL.String.concatWithSeparator(" ", $0.firstName, $0.middleName, $0.lastName)
    /// // SELECT concat_ws(' ', "firstName", "middleName", "lastName")
    /// ```
    ///
    /// - Parameters:
    ///   - separator: The separator to use between strings
    ///   - s1: First string expression
    /// - Returns: Concatenated string with separator
    ///
    /// > Note: NULL values are skipped, not converted to empty strings
    public static func concatWithSeparator(
        _ separator: Swift.String,
        _ s1: some QueryExpression<Swift.String?>
    ) -> some QueryExpression<Swift.String> {
        SQLQueryExpression(
            "concat_ws(\(bind: separator), \(s1.queryFragment))",
            as: Swift.String.self
        )
    }

    /// Concatenates two strings with a separator, ignoring NULL values
    ///
    /// PostgreSQL's `concat_ws(separator, str1, str2)` function.
    public static func concatWithSeparator(
        _ separator: Swift.String,
        _ s1: some QueryExpression<Swift.String?>,
        _ s2: some QueryExpression<Swift.String?>
    ) -> some QueryExpression<Swift.String> {
        SQLQueryExpression(
            "concat_ws(\(bind: separator), \(s1.queryFragment), \(s2.queryFragment))",
            as: Swift.String.self
        )
    }

    /// Concatenates three strings with a separator, ignoring NULL values
    ///
    /// PostgreSQL's `concat_ws(separator, str1, str2, str3)` function.
    public static func concatWithSeparator(
        _ separator: Swift.String,
        _ s1: some QueryExpression<Swift.String?>,
        _ s2: some QueryExpression<Swift.String?>,
        _ s3: some QueryExpression<Swift.String?>
    ) -> some QueryExpression<Swift.String> {
        SQLQueryExpression(
            "concat_ws(\(bind: separator), \(s1.queryFragment), \(s2.queryFragment), \(s3.queryFragment))",
            as: Swift.String.self
        )
    }

    /// Concatenates four strings with a separator, ignoring NULL values
    ///
    /// PostgreSQL's `concat_ws(separator, str1, str2, str3, str4)` function.
    public static func concatWithSeparator(
        _ separator: Swift.String,
        _ s1: some QueryExpression<Swift.String?>,
        _ s2: some QueryExpression<Swift.String?>,
        _ s3: some QueryExpression<Swift.String?>,
        _ s4: some QueryExpression<Swift.String?>
    ) -> some QueryExpression<Swift.String> {
        SQLQueryExpression(
            "concat_ws(\(bind: separator), \(s1.queryFragment), \(s2.queryFragment), \(s3.queryFragment), \(s4.queryFragment))",
            as: Swift.String.self
        )
    }
}

// MARK: - QueryExpression Extension (Fluent API)

extension QueryExpression where QueryValue == Swift.String {
    /// Concatenates a string using PostgreSQL's || operator
    ///
    /// PostgreSQL's `||` operator.
    ///
    /// ```swift
    /// User.select { $0.firstName.concat(" ").concat($0.lastName) }
    /// // SELECT ("users"."firstName" || ' ' || "users"."lastName") FROM "users"
    /// ```
    ///
    /// - Parameter other: The string to append
    /// - Returns: The concatenated string
    public func concat(_ other: Swift.String) -> some QueryExpression<Swift.String> {
        PostgreSQL.String.concat(self, other)
    }

    /// Concatenates with another string expression using PostgreSQL's || operator
    ///
    /// PostgreSQL's `||` operator.
    ///
    /// ```swift
    /// User.select { $0.firstName.concat($0.lastName) }
    /// // SELECT ("users"."firstName" || "users"."lastName") FROM "users"
    /// ```
    ///
    /// - Parameter other: The string expression to append
    /// - Returns: The concatenated string
    public func concat(_ other: some QueryExpression<Swift.String>) -> some QueryExpression<Swift.String> {
        PostgreSQL.String.concat(self, other)
    }
}

// MARK: - Global Functions (For Convenience)

/// Concatenates strings with a separator, ignoring NULL values
///
/// PostgreSQL's `concat_ws(separator, str1, str2, ...)` function.
///
/// ```swift
/// let fullName = concatWithSeparator(" ", $0.firstName, $0.middleName, $0.lastName)
/// // SELECT concat_ws(' ', "firstName", "middleName", "lastName")
/// ```
///
/// - Parameters:
///   - separator: The separator to use between strings
///   - s1: First string expression
/// - Returns: Concatenated string with separator
///
/// > Note: NULL values are skipped, not converted to empty strings
public func concatWithSeparator(
    _ separator: Swift.String,
    _ s1: some QueryExpression<Swift.String?>
) -> some QueryExpression<Swift.String> {
    PostgreSQL.String.concatWithSeparator(separator, s1)
}

/// Concatenates two strings with a separator, ignoring NULL values
public func concatWithSeparator(
    _ separator: Swift.String,
    _ s1: some QueryExpression<Swift.String?>,
    _ s2: some QueryExpression<Swift.String?>
) -> some QueryExpression<Swift.String> {
    PostgreSQL.String.concatWithSeparator(separator, s1, s2)
}

/// Concatenates three strings with a separator, ignoring NULL values
public func concatWithSeparator(
    _ separator: Swift.String,
    _ s1: some QueryExpression<Swift.String?>,
    _ s2: some QueryExpression<Swift.String?>,
    _ s3: some QueryExpression<Swift.String?>
) -> some QueryExpression<Swift.String> {
    PostgreSQL.String.concatWithSeparator(separator, s1, s2, s3)
}

/// Concatenates four strings with a separator, ignoring NULL values
public func concatWithSeparator(
    _ separator: Swift.String,
    _ s1: some QueryExpression<Swift.String?>,
    _ s2: some QueryExpression<Swift.String?>,
    _ s3: some QueryExpression<Swift.String?>,
    _ s4: some QueryExpression<Swift.String?>
) -> some QueryExpression<Swift.String> {
    PostgreSQL.String.concatWithSeparator(separator, s1, s2, s3, s4)
}
