import Foundation
import StructuredQueriesCore

// MARK: - Basic String Functions
//
// PostgreSQL Chapter 9.4: String Functions and Operators
// https://www.postgresql.org/docs/18/functions-string.html
//
// Fundamental string manipulation functions that work across all SQL databases.
// These were originally in ScalarFunctions.swift but moved here to align with PostgreSQL documentation.

// MARK: - Length Functions

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

    @available(
        *,
        deprecated,
        message: "Use 'count()' for SQL's 'count' aggregate function, or 'length()'"
    )
    public var count: some QueryExpression<Int> {
        length()
    }
}

extension QueryExpression where QueryValue == String {
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
        QueryFunction("octet_length", self)
    }
}

// MARK: - Case Conversion

extension QueryExpression where QueryValue: _OptionalPromotable<String?> {
    /// Converts the string to lowercase
    ///
    /// PostgreSQL's `lower()` function.
    ///
    /// ```swift
    /// User.select { $0.email.lower() }
    /// // SELECT lower("users"."email") FROM "users"
    /// ```
    ///
    /// - Returns: An expression wrapped with the `lower` function.
    public func lower() -> some QueryExpression<QueryValue> {
        QueryFunction("lower", self)
    }

    /// Converts the string to uppercase
    ///
    /// PostgreSQL's `upper()` function.
    ///
    /// ```swift
    /// User.select { $0.name.upper() }
    /// // SELECT upper("users"."name") FROM "users"
    /// ```
    ///
    /// - Returns: An expression wrapped with the `upper` function.
    public func upper() -> some QueryExpression<QueryValue> {
        QueryFunction("upper", self)
    }
}

// MARK: - Trimming Functions

extension QueryExpression where QueryValue == String {
    /// Removes characters from the beginning of a string
    ///
    /// PostgreSQL's `ltrim()` function.
    ///
    /// ```swift
    /// User.select { $0.code.ltrim() }
    /// // SELECT ltrim("users"."code") FROM "users"
    ///
    /// User.select { $0.code.ltrim($0.prefix) }
    /// // SELECT ltrim("users"."code", "users"."prefix") FROM "users"
    /// ```
    ///
    /// - Parameter characters: Characters to trim (defaults to whitespace)
    /// - Returns: An expression wrapped with the `ltrim` function.
    public func ltrim(
        _ characters: (some QueryExpression<QueryValue>)? = QueryValue?.none
    ) -> some QueryExpression<QueryValue> {
        if let characters {
            return QueryFunction("ltrim", self, characters)
        } else {
            return QueryFunction("ltrim", self)
        }
    }

    /// Removes characters from the end of a string
    ///
    /// PostgreSQL's `rtrim()` function.
    ///
    /// ```swift
    /// User.select { $0.description.rtrim() }
    /// // SELECT rtrim("users"."description") FROM "users"
    /// ```
    ///
    /// - Parameter characters: Characters to trim (defaults to whitespace)
    /// - Returns: An expression wrapped with the `rtrim` function.
    public func rtrim(
        _ characters: (some QueryExpression<QueryValue>)? = QueryValue?.none
    ) -> some QueryExpression<QueryValue> {
        if let characters {
            return QueryFunction("rtrim", self, characters)
        } else {
            return QueryFunction("rtrim", self)
        }
    }

    /// Removes characters from both ends of a string
    ///
    /// PostgreSQL's `trim()` function (via btrim).
    ///
    /// ```swift
    /// User.select { $0.name.trim() }
    /// // SELECT trim("users"."name") FROM "users"
    ///
    /// User.select { $0.name.trim($0.unwantedChars) }
    /// // SELECT trim("users"."name", "users"."unwantedChars") FROM "users"
    /// ```
    ///
    /// - Parameter characters: Characters to trim (defaults to whitespace)
    /// - Returns: An expression wrapped with the `trim` function.
    public func trim(
        _ characters: (some QueryExpression<QueryValue>)? = QueryValue?.none
    ) -> some QueryExpression<QueryValue> {
        if let characters {
            return QueryFunction("trim", self, characters)
        } else {
            return QueryFunction("trim", self)
        }
    }
}

// MARK: - Substring and Replacement

extension QueryExpression where QueryValue == String {
    /// Replaces occurrences of a substring with another substring
    ///
    /// PostgreSQL's `replace()` function.
    ///
    /// ```swift
    /// User.select { $0.name.replace($0.oldText, $0.newText) }
    /// // SELECT replace("users"."name", "users"."oldText", "users"."newText") FROM "users"
    /// ```
    ///
    /// - Parameters:
    ///   - other: The substring to be replaced.
    ///   - replacement: The replacement string.
    /// - Returns: An expression of the `replace` function wrapping the given string, a substring to
    ///   replace, and the replacement.
    public func replace(
        _ other: some QueryExpression<QueryValue>,
        _ replacement: some QueryExpression<QueryValue>
    ) -> some QueryExpression<QueryValue> {
        QueryFunction("replace", self, other, replacement)
    }

    /// Extracts a substring starting at the specified position
    ///
    /// PostgreSQL's `substr()` function.
    ///
    /// ```swift
    /// User.select { $0.name.substr(1, 5) }
    /// // SELECT substr("users"."name", 1, 5) FROM "users"
    ///
    /// User.select { $0.name.substr(10) }
    /// // SELECT substr("users"."name", 10) FROM "users"
    /// ```
    ///
    /// - Parameters:
    ///   - offset: The starting position (1-indexed)
    ///   - length: The length of the substring (optional)
    /// - Returns: An expression of the `substr` function wrapping the given string, an offset, and
    ///   length.
    ///
    /// > Note: PostgreSQL also has `substring()` with different syntax. See PostgreSQLStringFunctions.swift
    public func substr(
        _ offset: some QueryExpression<Int>,
        _ length: (some QueryExpression<Int>)? = Int?.none
    ) -> some QueryExpression<QueryValue> {
        if let length {
            return QueryFunction("substr", self, offset, length)
        } else {
            return QueryFunction("substr", self, offset)
        }
    }
}

// MARK: - Quoting

extension QueryExpression where QueryValue: _OptionalPromotable<String?> {
    /// Quotes a string value (wraps in single quotes and escapes internal quotes)
    ///
    /// PostgreSQL's `quote_literal()` function (mapped as `quote` for compatibility).
    ///
    /// ```swift
    /// User.select { $0.comment.quote() }
    /// // SELECT quote("users"."comment") FROM "users"
    /// ```
    ///
    /// - Returns: An expression wrapped with the `quote` function.
    ///
    /// > Note: For PostgreSQL-specific `quote_literal` and `quote_ident`, see PostgreSQLStringFunctions.swift
    public func quote() -> some QueryExpression<QueryValue> {
        QueryFunction("quote", self)
    }
}
