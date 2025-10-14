import Foundation
import StructuredQueriesCore

// MARK: - PostgreSQL String Conversion Functions
//
// PostgreSQL Chapter 9.4: String Functions and Operators
// https://www.postgresql.org/docs/18/functions-string.html
//
// Functions for converting string case and measuring string properties.

extension QueryExpression where QueryValue == String {
    // MARK: - Case Conversion

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
    public func uppercased() -> some QueryExpression<String> {
        SQLQueryExpression(
            "upper(\(self.queryFragment))",
            as: String.self
        )
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
    public func lowercased() -> some QueryExpression<String> {
        SQLQueryExpression(
            "lower(\(self.queryFragment))",
            as: String.self
        )
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
    public func initcap() -> some QueryExpression<String> {
        SQLQueryExpression(
            "initcap(\(self.queryFragment))",
            as: String.self
        )
    }

    // MARK: - String Length and Size

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
    ///
    /// > Note: `length()` is already defined in ScalarFunctions.swift for all Collections
    public func charLength() -> some QueryExpression<Int> {
        SQLQueryExpression(
            "char_length(\(self.queryFragment))",
            as: Int.self
        )
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
    ///
    /// > Note: `octetLength()` is already defined in ScalarFunctions.swift
    public func bitLength() -> some QueryExpression<Int> {
        SQLQueryExpression(
            "bit_length(\(self.queryFragment))",
            as: Int.self
        )
    }

    // MARK: - String Splitting

    /// Splits the string on delimiter and returns the nth field (1-indexed)
    ///
    /// PostgreSQL's `split_part(string, delimiter, n)` function.
    ///
    /// ```swift
    /// User.select { $0.fullPath.splitPart(delimiter: "/", field: 3) }
    /// // SELECT split_part("users"."fullPath", '/', 3) FROM "users"
    /// // "/home/user/file.txt" -> "file.txt" (field 3)
    /// ```
    ///
    /// - Parameters:
    ///   - delimiter: The delimiter to split on
    ///   - field: The field number to return (1-indexed)
    /// - Returns: The nth field from the split string
    ///
    /// > Note: Returns empty string if n is out of range. Fields are 1-indexed.
    public func splitPart(delimiter: String, field: Int) -> some QueryExpression<String> {
        SQLQueryExpression(
            "split_part(\(self.queryFragment), \(bind: delimiter), \(field))",
            as: String.self
        )
    }

    // MARK: - Character Conversion

    /// Returns the character with the given code
    ///
    /// PostgreSQL's `chr(int)` function.
    ///
    /// ```swift
    /// // As a static function
    /// let char = String.chr(65)
    /// // SELECT chr(65)  -- Returns 'A'
    /// ```
    ///
    /// - Parameter code: ASCII/Unicode code point
    /// - Returns: The character corresponding to the code
    public static func chr(_ code: Int) -> some QueryExpression<String> {
        SQLQueryExpression(
            "chr(\(code))",
            as: String.self
        )
    }

    // MARK: - MD5 Hash

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
    public func md5() -> some QueryExpression<String> {
        SQLQueryExpression(
            "md5(\(self.queryFragment))",
            as: String.self
        )
    }
}

// MARK: - Optional String Extensions

extension QueryExpression where QueryValue == String? {
    /// Returns the number of characters in the string, or NULL if string is NULL
    ///
    /// PostgreSQL's `length(string)` function.
    ///
    /// ```swift
    /// User.where { $0.nickname.length() > 3 }
    /// // SELECT … FROM "users" WHERE length("users"."nickname") > 3
    /// ```
    public func length() -> some QueryExpression<Int?> {
        SQLQueryExpression(
            "length(\(self.queryFragment))",
            as: Int?.self
        )
    }

    /// Converts the string to uppercase, or NULL if string is NULL
    ///
    /// PostgreSQL's `upper(string)` function.
    public func uppercased() -> some QueryExpression<String?> {
        SQLQueryExpression(
            "upper(\(self.queryFragment))",
            as: String?.self
        )
    }

    /// Converts the string to lowercase, or NULL if string is NULL
    ///
    /// PostgreSQL's `lower(string)` function.
    public func lowercased() -> some QueryExpression<String?> {
        SQLQueryExpression(
            "lower(\(self.queryFragment))",
            as: String?.self
        )
    }
}
