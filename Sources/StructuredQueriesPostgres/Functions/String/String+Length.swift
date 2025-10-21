import Foundation
import StructuredQueriesCore

// MARK: - String Length Functions
//
// PostgreSQL Chapter 9.4: String Functions and Operators
// https://www.postgresql.org/docs/18/functions-string.html
//
// Functions for measuring string length: length(), char_length(), bit_length(), octet_length()

extension PostgreSQL.String {
    /// Returns the number of characters in a string
    ///
    /// PostgreSQL's `length(string)` function.
    ///
    /// ```swift
    /// PostgreSQL.String.length($0.title)
    /// // SELECT length("reminders"."title") FROM "reminders"
    /// ```
    ///
    /// - Parameter value: The string expression
    /// - Returns: The number of characters in the string
    ///
    /// > Note: For byte length, use `octetLength()`
    public static func length(_ value: some QueryExpression<Swift.String>) -> some QueryExpression<Int> {
        QueryFunction("length", value)
    }

    /// Returns the number of characters in an optional string
    ///
    /// PostgreSQL's `length(string)` function.
    public static func length(_ value: some QueryExpression<Swift.String?>) -> some QueryExpression<Int?> {
        QueryFunction("length", value)
    }

    /// Returns the number of characters in a string (alias for length)
    ///
    /// PostgreSQL's `char_length(string)` function.
    ///
    /// ```swift
    /// PostgreSQL.String.charLength($0.description)
    /// // SELECT char_length("users"."description") FROM "users"
    /// ```
    ///
    /// - Parameter value: The string expression
    /// - Returns: The number of characters in the string
    public static func charLength(_ value: some QueryExpression<Swift.String>) -> some QueryExpression<Int> {
        SQLQueryExpression(
            "char_length(\(value.queryFragment))",
            as: Int.self
        )
    }

    /// Returns the number of characters in an optional string
    ///
    /// PostgreSQL's `char_length(string)` function.
    public static func charLength(_ value: some QueryExpression<Swift.String?>) -> some QueryExpression<Int?> {
        SQLQueryExpression(
            "char_length(\(value.queryFragment))",
            as: Int?.self
        )
    }

    /// Returns the number of bits in a string
    ///
    /// PostgreSQL's `bit_length(string)` function.
    ///
    /// ```swift
    /// PostgreSQL.String.bitLength($0.data)
    /// // SELECT bit_length("users"."data") FROM "users"
    /// ```
    ///
    /// - Parameter value: The string expression
    /// - Returns: The number of bits in the string (8 × byte length)
    public static func bitLength(_ value: some QueryExpression<Swift.String>) -> some QueryExpression<Int> {
        SQLQueryExpression(
            "bit_length(\(value.queryFragment))",
            as: Int.self
        )
    }

    /// Returns the number of bits in an optional string
    ///
    /// PostgreSQL's `bit_length(string)` function.
    public static func bitLength(_ value: some QueryExpression<Swift.String?>) -> some QueryExpression<Int?> {
        SQLQueryExpression(
            "bit_length(\(value.queryFragment))",
            as: Int?.self
        )
    }

    /// Returns the number of bytes in a string
    ///
    /// PostgreSQL's `octet_length(string)` function.
    ///
    /// ```swift
    /// PostgreSQL.String.octetLength($0.data)
    /// // SELECT octet_length("users"."data") FROM "users"
    /// ```
    ///
    /// - Parameter value: The string expression
    /// - Returns: The number of bytes in the string
    ///
    /// > Note: For UTF-8 strings, byte count may differ from character count
    public static func octetLength(_ value: some QueryExpression<Swift.String>) -> some QueryExpression<Int> {
        QueryFunction("octet_length", value)
    }

    /// Returns the number of bytes in an optional string
    ///
    /// PostgreSQL's `octet_length(string)` function.
    public static func octetLength(_ value: some QueryExpression<Swift.String?>) -> some QueryExpression<Int?> {
        QueryFunction("octet_length", value)
    }
}

// MARK: - QueryExpression Extension (Fluent API)

extension QueryExpression where QueryValue: Collection {
    /// Returns the number of elements in a collection (string length, array length, etc.)
    ///
    /// PostgreSQL's `length()` function.
    ///
    /// ```swift
    /// Reminder.select { $0.title.length() }
    /// // SELECT length("reminders"."title") FROM "reminders"
    ///
    /// Asset.select { $0.bytes.length() }
    /// // SELECT length("assets"."bytes") FROM "assets"
    /// ```
    ///
    /// - Returns: An integer expression of the `length` function wrapping this expression.
    ///
    /// > Note: For strings, this returns character count. For byte length, use `octetLength()`
    public func length() -> some QueryExpression<Int> {
        QueryFunction("length", self)
    }
}

extension QueryExpression where QueryValue == Swift.String {
    /// Returns the number of characters in the string (alias for length)
    ///
    /// PostgreSQL's `char_length(string)` function.
    ///
    /// ```swift
    /// User.where { $0.description.charLength() < 100 }
    /// // SELECT … FROM "users" WHERE char_length("users"."description") < 100
    /// ```
    ///
    /// - Returns: The number of characters in the string
    public func charLength() -> some QueryExpression<Int> {
        PostgreSQL.String.charLength(self)
    }

    /// Returns the number of bits in the string
    ///
    /// PostgreSQL's `bit_length(string)` function.
    ///
    /// ```swift
    /// User.select { $0.data.bitLength() }
    /// // SELECT bit_length("users"."data") FROM "users"
    /// ```
    ///
    /// - Returns: The number of bits in the string (8 × byte length)
    public func bitLength() -> some QueryExpression<Int> {
        PostgreSQL.String.bitLength(self)
    }

    /// Returns the number of bytes in the string
    ///
    /// PostgreSQL's `octet_length()` function.
    ///
    /// ```swift
    /// User.select { $0.data.octetLength() }
    /// // SELECT octet_length("users"."data") FROM "users"
    /// ```
    ///
    /// - Returns: An integer expression of the `octet_length` function wrapping the given string.
    ///
    /// > Note: For UTF-8 strings, byte count may differ from character count
    public func octetLength() -> some QueryExpression<Int> {
        PostgreSQL.String.octetLength(self)
    }
}

extension QueryExpression where QueryValue == Swift.String? {
    /// Returns the number of characters in the string, or NULL if string is NULL
    ///
    /// PostgreSQL's `length(string)` function.
    ///
    /// ```swift
    /// User.where { $0.nickname.length() > 3 }
    /// // SELECT … FROM "users" WHERE length("users"."nickname") > 3
    /// ```
    public func length() -> some QueryExpression<Int?> {
        PostgreSQL.String.length(self)
    }

    /// Returns the number of characters in the string (alias for length)
    ///
    /// PostgreSQL's `char_length(string)` function.
    public func charLength() -> some QueryExpression<Int?> {
        PostgreSQL.String.charLength(self)
    }

    /// Returns the number of bits in the string
    ///
    /// PostgreSQL's `bit_length(string)` function.
    public func bitLength() -> some QueryExpression<Int?> {
        PostgreSQL.String.bitLength(self)
    }

    /// Returns the number of bytes in the string
    ///
    /// PostgreSQL's `octet_length(string)` function.
    public func octetLength() -> some QueryExpression<Int?> {
        PostgreSQL.String.octetLength(self)
    }
}
