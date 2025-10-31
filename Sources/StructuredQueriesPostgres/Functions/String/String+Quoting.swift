import Foundation
import StructuredQueriesCore

// MARK: - String Quoting Functions
//
// PostgreSQL Chapter 9.4: String Functions and Operators
// https://www.postgresql.org/docs/18/functions-string.html
//
// Functions for quoting strings: quote(), quote_literal(), quote_ident()

extension PostgreSQL.String {
  /// Quotes a string value (wraps in single quotes and escapes internal quotes)
  ///
  /// PostgreSQL's `quote_literal()` function (mapped as `quote` for compatibility).
  ///
  /// ```swift
  /// PostgreSQL.String.quote($0.comment)
  /// // SELECT quote("users"."comment") FROM "users"
  /// ```
  ///
  /// - Parameter value: The string expression to quote
  /// - Returns: An expression wrapped with the `quote` function.
  ///
  /// > Note: For PostgreSQL-specific `quote_literal` and `quote_ident`, see `quoteLiteral()` and `quoteIdent()`
  public static func quote(_ value: some QueryExpression<Swift.String>) -> some QueryExpression<
    Swift.String
  > {
    QueryFunction("quote", value)
  }

  /// Quotes an optional string value
  ///
  /// PostgreSQL's `quote_literal()` function (mapped as `quote` for compatibility).
  public static func quote(_ value: some QueryExpression<Swift.String?>) -> some QueryExpression<
    Swift.String?
  > {
    QueryFunction("quote", value)
  }

  /// Quotes a string for safe SQL inclusion
  ///
  /// PostgreSQL's `QUOTE_LITERAL(string)` function.
  ///
  /// Escapes single quotes and wraps the string in single quotes, making it safe to include in SQL.
  ///
  /// ```swift
  /// PostgreSQL.String.quoteLiteral($0.comment)
  /// // SELECT QUOTE_LITERAL("users"."comment") FROM "users"
  /// ```
  ///
  /// - Parameter value: The string expression to quote
  /// - Returns: The quoted and escaped string
  ///
  /// > Note: SQLite equivalent: `QUOTE`
  public static func quoteLiteral(_ value: some QueryExpression<Swift.String>)
    -> some QueryExpression<Swift.String>
  {
    SQLQueryExpression(
      "QUOTE_LITERAL(\(value.queryFragment))",
      as: Swift.String.self
    )
  }

  /// Quotes an identifier for safe SQL inclusion
  ///
  /// PostgreSQL's `QUOTE_IDENT(string)` function.
  ///
  /// Wraps the identifier in double quotes, making it safe to use as a table or column name.
  ///
  /// ```swift
  /// PostgreSQL.String.quoteIdent($0.tableName)
  /// // SELECT QUOTE_IDENT("config"."tableName") FROM "config"
  /// ```
  ///
  /// - Parameter value: The string expression representing an identifier
  /// - Returns: The quoted identifier
  public static func quoteIdent(_ value: some QueryExpression<Swift.String>)
    -> some QueryExpression<Swift.String>
  {
    SQLQueryExpression(
      "QUOTE_IDENT(\(value.queryFragment))",
      as: Swift.String.self
    )
  }
}

// MARK: - QueryExpression Extension (Fluent API)

extension QueryExpression where QueryValue: _OptionalPromotable<Swift.String?> {
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
  /// > Note: For PostgreSQL-specific `quote_literal` and `quote_ident`, see `quoteLiteral()` and `quoteIdent()`
  public func quote() -> some QueryExpression<QueryValue> {
    QueryFunction("quote", self)
  }
}

extension QueryExpression where QueryValue == Swift.String {
  /// Quotes a string for safe SQL inclusion
  ///
  /// PostgreSQL's `QUOTE_LITERAL(string)` function.
  ///
  /// Escapes single quotes and wraps the string in single quotes, making it safe to include in SQL.
  ///
  /// ```swift
  /// User.select { $0.comment.quoteLiteral() }
  /// // SELECT QUOTE_LITERAL("users"."comment") FROM "users"
  /// ```
  ///
  /// - Returns: The quoted and escaped string
  ///
  /// > Note: SQLite equivalent: `QUOTE`
  public func quoteLiteral() -> some QueryExpression<Swift.String> {
    PostgreSQL.String.quoteLiteral(self)
  }

  /// Quotes an identifier for safe SQL inclusion
  ///
  /// PostgreSQL's `QUOTE_IDENT(string)` function.
  ///
  /// Wraps the identifier in double quotes, making it safe to use as a table or column name.
  ///
  /// ```swift
  /// Config.select { $0.tableName.quoteIdent() }
  /// // SELECT QUOTE_IDENT("config"."tableName") FROM "config"
  /// ```
  ///
  /// - Returns: The quoted identifier
  public func quoteIdent() -> some QueryExpression<Swift.String> {
    PostgreSQL.String.quoteIdent(self)
  }
}
