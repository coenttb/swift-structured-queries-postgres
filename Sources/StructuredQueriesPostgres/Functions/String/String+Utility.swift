import Foundation
import StructuredQueriesCore

// MARK: - String Utility Functions
//
// PostgreSQL Chapter 9.4: String Functions and Operators
// https://www.postgresql.org/docs/18/functions-string.html
//
// Utility functions: chr(), ascii(), md5()

extension PostgreSQL.String {
    /// Returns the character with the given code
    ///
    /// PostgreSQL's `chr(int)` function.
    ///
    /// ```swift
    /// PostgreSQL.String.chr(65)
    /// // SELECT chr(65)  -- Returns 'A'
    /// ```
    ///
    /// - Parameter code: ASCII/Unicode code point
    /// - Returns: The character corresponding to the code
    public static func chr(_ code: Int) -> some QueryExpression<Swift.String> {
        SQLQueryExpression(
            "chr(\(code))",
            as: Swift.String.self
        )
    }

    /// Returns the ASCII code of the first character
    ///
    /// PostgreSQL's `ASCII(string)` function.
    ///
    /// ```swift
    /// PostgreSQL.String.ascii($0.name)
    /// // SELECT ASCII("users"."name") FROM "users"
    /// ```
    ///
    /// - Parameter value: The string expression
    /// - Returns: The ASCII code of the first character, or NULL if empty
    ///
    /// > Note: SQLite equivalent: `UNICODE` (partial - only ASCII range)
    public static func ascii(_ value: some QueryExpression<Swift.String>) -> some QueryExpression<Int?> {
        SQLQueryExpression(
            "ASCII(\(value.queryFragment))",
            as: Int?.self
        )
    }

    /// Returns the MD5 hash of the string as a hexadecimal string
    ///
    /// PostgreSQL's `md5(string)` function.
    ///
    /// ```swift
    /// PostgreSQL.String.md5($0.password)
    /// // SELECT md5("users"."password") FROM "users"
    /// ```
    ///
    /// - Parameter value: The string expression
    /// - Returns: The MD5 hash as a 32-character hexadecimal string
    ///
    /// > Warning: MD5 is cryptographically broken. Use only for non-security purposes
    /// > like checksums or cache keys.
    public static func md5(_ value: some QueryExpression<Swift.String>) -> some QueryExpression<Swift.String> {
        SQLQueryExpression(
            "md5(\(value.queryFragment))",
            as: Swift.String.self
        )
    }
}

// MARK: - QueryExpression Extension (Fluent API)

extension QueryExpression where QueryValue == Swift.String {
    /// Returns the character with the given code
    ///
    /// PostgreSQL's `chr(int)` function.
    ///
    /// ```swift
    /// // As a static function
    /// let char = Swift.String.chr(65)
    /// // SELECT chr(65)  -- Returns 'A'
    /// ```
    ///
    /// - Parameter code: ASCII/Unicode code point
    /// - Returns: The character corresponding to the code
    public static func chr(_ code: Int) -> some QueryExpression<Swift.String> {
        PostgreSQL.String.chr(code)
    }

    /// Returns the ASCII code of the first character
    ///
    /// PostgreSQL's `ASCII(string)` function.
    ///
    /// ```swift
    /// User.select { $0.name.ascii() }
    /// // SELECT ASCII("users"."name") FROM "users"
    /// ```
    ///
    /// - Returns: The ASCII code of the first character, or NULL if empty
    ///
    /// > Note: SQLite equivalent: `UNICODE` (partial - only ASCII range)
    public func ascii() -> some QueryExpression<Int?> {
        PostgreSQL.String.ascii(self)
    }

    /// Returns the MD5 hash of the string as a hexadecimal string
    ///
    /// PostgreSQL's `md5(string)` function.
    ///
    /// ```swift
    /// User.select { $0.password.md5() }
    /// // SELECT md5("users"."password") FROM "users"
    /// ```
    ///
    /// - Returns: The MD5 hash as a 32-character hexadecimal string
    ///
    /// > Warning: MD5 is cryptographically broken. Use only for non-security purposes
    /// > like checksums or cache keys.
    public func md5() -> some QueryExpression<Swift.String> {
        PostgreSQL.String.md5(self)
    }
}
