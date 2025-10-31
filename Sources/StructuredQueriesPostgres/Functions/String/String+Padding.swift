import Foundation
import StructuredQueriesCore

// MARK: - String Padding Functions
//
// PostgreSQL Chapter 9.4: String Functions and Operators
// https://www.postgresql.org/docs/18/functions-string.html
//
// Functions for padding strings: lpad(), rpad()

extension PostgreSQL.String {
  /// Pads the string on the left with spaces (or specified characters) to reach the specified length
  ///
  /// PostgreSQL's `lpad(string, length [, fill])` function.
  ///
  /// ```swift
  /// PostgreSQL.String.lpad($0.id, to: 10, with: "0")
  /// // SELECT lpad("users"."id", 10, '0') FROM "users"
  /// ```
  ///
  /// - Parameters:
  ///   - value: The string expression
  ///   - length: Target length
  ///   - fill: Fill string (defaults to space)
  /// - Returns: The padded string
  public static func lpad(
    _ value: some QueryExpression<Swift.String>,
    to length: Int,
    with fill: Swift.String = " "
  ) -> some QueryExpression<Swift.String> {
    SQLQueryExpression(
      "lpad(\(value.queryFragment), \(length), \(bind: fill))",
      as: Swift.String.self
    )
  }

  /// Pads the string on the right with spaces (or specified characters) to reach the specified length
  ///
  /// PostgreSQL's `rpad(string, length [, fill])` function.
  ///
  /// ```swift
  /// PostgreSQL.String.rpad($0.name, to: 20, with: ".")
  /// // SELECT rpad("users"."name", 20, '.') FROM "users"
  /// ```
  ///
  /// - Parameters:
  ///   - value: The string expression
  ///   - length: Target length
  ///   - fill: Fill string (defaults to space)
  /// - Returns: The padded string
  public static func rpad(
    _ value: some QueryExpression<Swift.String>,
    to length: Int,
    with fill: Swift.String = " "
  ) -> some QueryExpression<Swift.String> {
    SQLQueryExpression(
      "rpad(\(value.queryFragment), \(length), \(bind: fill))",
      as: Swift.String.self
    )
  }
}

// MARK: - QueryExpression Extension (Fluent API)

extension QueryExpression where QueryValue == Swift.String {
  /// Pads the string on the left with spaces (or specified characters) to reach the specified length
  ///
  /// PostgreSQL's `lpad(string, length [, fill])` function.
  ///
  /// ```swift
  /// User.select { $0.id.lpad(to: 10, with: "0") }
  /// // SELECT lpad("users"."id", 10, '0') FROM "users"
  /// ```
  ///
  /// - Parameters:
  ///   - length: Target length
  ///   - fill: Fill string (defaults to space)
  /// - Returns: The padded string
  public func lpad(to length: Int, with fill: Swift.String = " ") -> some QueryExpression<
    Swift.String
  > {
    PostgreSQL.String.lpad(self, to: length, with: fill)
  }

  /// Pads the string on the right with spaces (or specified characters) to reach the specified length
  ///
  /// PostgreSQL's `rpad(string, length [, fill])` function.
  ///
  /// ```swift
  /// User.select { $0.name.rpad(to: 20, with: ".") }
  /// // SELECT rpad("users"."name", 20, '.') FROM "users"
  /// ```
  ///
  /// - Parameters:
  ///   - length: Target length
  ///   - fill: Fill string (defaults to space)
  /// - Returns: The padded string
  public func rpad(to length: Int, with fill: Swift.String = " ") -> some QueryExpression<
    Swift.String
  > {
    PostgreSQL.String.rpad(self, to: length, with: fill)
  }
}
