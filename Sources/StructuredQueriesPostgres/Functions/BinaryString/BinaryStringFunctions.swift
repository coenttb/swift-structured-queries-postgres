import Foundation
import StructuredQueriesCore

// MARK: - Binary String Functions
//
// PostgreSQL Chapter 9.5: Binary String Functions and Operators
// https://www.postgresql.org/docs/18/functions-binarystring.html
//
// Functions for manipulating binary data (bytea type and byte arrays).

extension QueryExpression where QueryValue == [UInt8] {
    /// Converts binary data to hexadecimal string representation
    ///
    /// PostgreSQL's `encode(bytes, 'hex')` function (also available as `hex()` for compatibility).
    ///
    /// ```swift
    /// Asset.select { $0.bytes.hex() }
    /// // SELECT hex("assets"."bytes") FROM "assets"
    /// ```
    ///
    /// - Returns: A string expression of the `hex` function wrapping this expression.
    ///
    /// > Note: SQLite equivalent: `hex()`. For PostgreSQL-specific encoding options (base64, escape),
    /// > see PostgreSQLBinaryFunctions.swift
    public func hex() -> some QueryExpression<String> {
        QueryFunction("hex", self)
    }
}
