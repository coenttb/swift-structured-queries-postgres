import Foundation
import StructuredQueriesCore

// MARK: - PostgreSQL Binary String Functions

extension QueryExpression where QueryValue == [UInt8] {
    /// PostgreSQL's `ENCODE` function - encodes binary data to hex string
    ///
    /// ```swift
    /// Image.select { $0.data.encodeHex() }
    /// // SELECT ENCODE("images"."data", 'hex') FROM "images"
    /// ```
    ///
    /// > Note: SQLite equivalent: `HEX`
    public func encodeHex() -> some QueryExpression<String> {
        SQLQueryExpression("ENCODE(\(self.queryFragment), 'hex')", as: String.self)
    }

    /// PostgreSQL's `ENCODE` function with custom encoding format
    ///
    /// Supported formats include:
    /// - `"hex"` - Hexadecimal encoding
    /// - `"base64"` - Base64 encoding
    /// - `"escape"` - PostgreSQL escape format
    ///
    /// ```swift
    /// Image.select { $0.data.encode("base64") }
    /// // SELECT ENCODE("images"."data", 'base64') FROM "images"
    /// ```
    ///
    /// - Parameter format: The encoding format to use
    /// - Returns: A string expression with the encoded data
    public func encode(_ format: String) -> some QueryExpression<String> {
        SQLQueryExpression("ENCODE(\(self.queryFragment), \(bind: format))", as: String.self)
    }
}

extension QueryExpression where QueryValue == String {
    /// PostgreSQL's `DECODE` function - decodes hex string to binary data
    ///
    /// ```swift
    /// Setting.select { $0.hexValue.decodeHex() }
    /// // SELECT DECODE("settings"."hexValue", 'hex') FROM "settings"
    /// ```
    ///
    /// > Note: SQLite equivalent: `UNHEX`
    public func decodeHex() -> some QueryExpression<[UInt8]> {
        SQLQueryExpression("DECODE(\(self.queryFragment), 'hex')", as: [UInt8].self)
    }
}
