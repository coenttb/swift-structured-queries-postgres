import Foundation
import StructuredQueriesCore

// MARK: - Case Conversion Functions
//
// PostgreSQL Chapter 9.4: String Functions and Operators
// https://www.postgresql.org/docs/18/functions-string.html
//
// Functions for converting string case: upper(), lower(), initcap()

extension PostgreSQL.String {
    /// Converts a string to uppercase
    ///
    /// PostgreSQL's `upper(string)` function.
    ///
    /// ```swift
    /// PostgreSQL.String.upper($0.name)
    /// // SELECT upper("users"."name") FROM "users"
    /// ```
    ///
    /// - Parameter value: The string expression to convert
    /// - Returns: The string in uppercase
    public static func upper(_ value: some QueryExpression<Swift.String>) -> some QueryExpression<Swift.String> {
        SQLQueryExpression(
            "upper(\(value.queryFragment))",
            as: Swift.String.self
        )
    }

    /// Converts an optional string to uppercase
    ///
    /// PostgreSQL's `upper(string)` function.
    public static func upper(_ value: some QueryExpression<Swift.String?>) -> some QueryExpression<Swift.String?> {
        SQLQueryExpression(
            "upper(\(value.queryFragment))",
            as: Swift.String?.self
        )
    }

    /// Converts a string to lowercase
    ///
    /// PostgreSQL's `lower(string)` function.
    ///
    /// ```swift
    /// PostgreSQL.String.lower($0.email)
    /// // SELECT lower("users"."email") FROM "users"
    /// ```
    ///
    /// - Parameter value: The string expression to convert
    /// - Returns: The string in lowercase
    public static func lower(_ value: some QueryExpression<Swift.String>) -> some QueryExpression<Swift.String> {
        SQLQueryExpression(
            "lower(\(value.queryFragment))",
            as: Swift.String.self
        )
    }

    /// Converts an optional string to lowercase
    ///
    /// PostgreSQL's `lower(string)` function.
    public static func lower(_ value: some QueryExpression<Swift.String?>) -> some QueryExpression<Swift.String?> {
        SQLQueryExpression(
            "lower(\(value.queryFragment))",
            as: Swift.String?.self
        )
    }

    /// Converts the first letter of each word to uppercase, rest to lowercase
    ///
    /// PostgreSQL's `initcap(string)` function.
    ///
    /// ```swift
    /// PostgreSQL.String.initcap($0.name)
    /// // SELECT initcap("users"."name") FROM "users"
    /// // "john doe" -> "John Doe"
    /// ```
    ///
    /// - Parameter value: The string expression to convert
    /// - Returns: The string with title case (initial capitals)
    public static func initcap(_ value: some QueryExpression<Swift.String>) -> some QueryExpression<Swift.String> {
        SQLQueryExpression(
            "initcap(\(value.queryFragment))",
            as: Swift.String.self
        )
    }

    /// Converts the first letter of each word to uppercase, rest to lowercase (optional string)
    ///
    /// PostgreSQL's `initcap(string)` function.
    public static func initcap(_ value: some QueryExpression<Swift.String?>) -> some QueryExpression<Swift.String?> {
        SQLQueryExpression(
            "initcap(\(value.queryFragment))",
            as: Swift.String?.self
        )
    }
}

// MARK: - QueryExpression Extension (Fluent API)

extension QueryExpression where QueryValue == Swift.String {
    /// Converts the string to uppercase
    ///
    /// PostgreSQL's `upper(string)` function.
    ///
    /// ```swift
    /// User.select { $0.name.uppercased() }
    /// // SELECT upper("users"."name") FROM "users"
    /// ```
    ///
    /// - Returns: The string in uppercase
    ///
    /// > Note: The `@_disfavoredOverload` attribute ensures Swift's stdlib `String.uppercased()` is preferred
    /// > for regular Swift strings, while this method is available for QueryExpressions.
    @_disfavoredOverload
    public func uppercased() -> some QueryExpression<Swift.String> {
        PostgreSQL.String.upper(self)
    }

    /// Converts the string to lowercase
    ///
    /// PostgreSQL's `lower(string)` function.
    ///
    /// ```swift
    /// User.select { $0.email.lowercased() }
    /// // SELECT lower("users"."email") FROM "users"
    /// ```
    ///
    /// - Returns: The string in lowercase
    ///
    /// > Note: The `@_disfavoredOverload` attribute ensures Swift's stdlib `String.lowercased()` is preferred
    /// > for regular Swift strings, while this method is available for QueryExpressions.
    @_disfavoredOverload
    public func lowercased() -> some QueryExpression<Swift.String> {
        PostgreSQL.String.lower(self)
    }

    /// Converts the first letter of each word to uppercase, rest to lowercase
    ///
    /// PostgreSQL's `initcap(string)` function.
    ///
    /// ```swift
    /// User.select { $0.name.initcap() }
    /// // SELECT initcap("users"."name") FROM "users"
    /// // "john doe" -> "John Doe"
    /// ```
    ///
    /// - Returns: The string with title case (initial capitals)
    public func initcap() -> some QueryExpression<Swift.String> {
        PostgreSQL.String.initcap(self)
    }
}

extension QueryExpression where QueryValue == Swift.String? {
    /// Converts the string to uppercase, or NULL if string is NULL
    ///
    /// PostgreSQL's `upper(string)` function.
    public func uppercased() -> some QueryExpression<Swift.String?> {
        PostgreSQL.String.upper(self)
    }

    /// Converts the string to lowercase, or NULL if string is NULL
    ///
    /// PostgreSQL's `lower(string)` function.
    public func lowercased() -> some QueryExpression<Swift.String?> {
        PostgreSQL.String.lower(self)
    }

    /// Converts the first letter of each word to uppercase, rest to lowercase
    ///
    /// PostgreSQL's `initcap(string)` function.
    public func initcap() -> some QueryExpression<Swift.String?> {
        PostgreSQL.String.initcap(self)
    }
}
