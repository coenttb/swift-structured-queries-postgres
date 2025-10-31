import Foundation
import StructuredQueriesCore

// MARK: - Division Functions
//
// PostgreSQL Chapter 9.3, Table 9.5: Mathematical Functions
// https://www.postgresql.org/docs/current/functions-math.html
//
// Functions for modulo and integer division operations.

extension Math {
  /// Returns the remainder of division (modulo)
  ///
  /// PostgreSQL's `mod()` function or `%` operator.
  ///
  /// ```swift
  /// Math.mod($0.value, 10)
  /// // SELECT mod("numbers"."value", 10)
  /// ```
  ///
  /// - Parameters:
  ///   - dividend: The value to divide
  ///   - divisor: The divisor
  /// - Returns: The remainder after division
  public static func mod<T: Numeric & QueryBindable>(
    _ dividend: some QueryExpression<T>,
    _ divisor: T
  ) -> some QueryExpression<T> {
    SQLQueryExpression("mod(\(dividend.queryFragment), \(bind: divisor))", as: T.self)
  }

  /// Returns the remainder of division using an expression
  ///
  /// PostgreSQL's `mod()` function.
  ///
  /// ```swift
  /// Math.mod($0.value, $0.divisor)
  /// // SELECT mod("numbers"."value", "numbers"."divisor")
  /// ```
  public static func mod<T: Numeric & QueryBindable>(
    _ dividend: some QueryExpression<T>,
    _ divisor: some QueryExpression<T>
  ) -> some QueryExpression<T> {
    SQLQueryExpression(
      "mod(\(dividend.queryFragment), \(divisor.queryFragment))",
      as: T.self
    )
  }

  /// Returns the integer quotient (truncates toward zero)
  ///
  /// PostgreSQL's `div()` function.
  ///
  /// ```swift
  /// Math.div($0.value, 10)
  /// // SELECT div("numbers"."value", 10)
  /// ```
  ///
  /// - Parameters:
  ///   - dividend: The value to divide
  ///   - divisor: The divisor
  /// - Returns: The integer quotient
  public static func div<T: Numeric & QueryBindable>(
    _ dividend: some QueryExpression<T>,
    _ divisor: T
  ) -> some QueryExpression<T> {
    SQLQueryExpression("div(\(dividend.queryFragment), \(bind: divisor))", as: T.self)
  }
}

// MARK: - QueryExpression Extension (Fluent API)

extension QueryExpression where QueryValue: Numeric & QueryBindable {
  /// Returns the remainder of division (modulo)
  ///
  /// PostgreSQL's `mod()` function or `%` operator.
  ///
  /// ```swift
  /// Number.select { $0.value.mod(10) }
  /// // SELECT mod("numbers"."value", 10) FROM "numbers"
  /// ```
  ///
  /// - Parameter divisor: The divisor
  /// - Returns: The remainder after division
  public func mod(_ divisor: QueryValue) -> some QueryExpression<QueryValue> {
    Math.mod(self, divisor)
  }

  /// Returns the remainder of division using an expression
  ///
  /// PostgreSQL's `mod()` function.
  ///
  /// ```swift
  /// Number.select { $0.value.mod($0.divisor) }
  /// // SELECT mod("numbers"."value", "numbers"."divisor") FROM "numbers"
  /// ```
  public func mod(_ divisor: some QueryExpression<QueryValue>) -> some QueryExpression<QueryValue> {
    Math.mod(self, divisor)
  }

  /// Returns the integer quotient (truncates toward zero)
  ///
  /// PostgreSQL's `div()` function.
  ///
  /// ```swift
  /// Number.select { $0.value.div(10) }
  /// // SELECT div("numbers"."value", 10) FROM "numbers"
  /// ```
  ///
  /// - Parameter divisor: The divisor
  /// - Returns: The integer quotient
  public func div(_ divisor: QueryValue) -> some QueryExpression<QueryValue> {
    Math.div(self, divisor)
  }
}
