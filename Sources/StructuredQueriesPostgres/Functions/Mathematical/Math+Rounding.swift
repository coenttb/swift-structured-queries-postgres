import Foundation
import StructuredQueriesCore

// MARK: - Rounding Functions
//
// PostgreSQL Chapter 9.3, Table 9.5: Mathematical Functions
// https://www.postgresql.org/docs/current/functions-math.html
//
// Functions for rounding and truncating numeric values.

extension Math {
  /// Returns the smallest integer greater than or equal to the value (ceiling)
  ///
  /// PostgreSQL's `ceil()` function.
  ///
  /// ```swift
  /// Math.ceil($0.value)
  /// // SELECT ceil("measurements"."value")
  /// ```
  public static func ceil<T: Numeric & QueryBindable>(
    _ value: some QueryExpression<T>
  ) -> some QueryExpression<T> {
    SQLQueryExpression("ceil(\(value.queryFragment))", as: T.self)
  }

  /// Returns the smallest integer greater than or equal to the value (ceiling)
  ///
  /// PostgreSQL's `ceiling()` function (alias for ceil).
  ///
  /// ```swift
  /// Math.ceiling($0.value)
  /// // SELECT ceiling("measurements"."value")
  /// ```
  public static func ceiling<T: Numeric & QueryBindable>(
    _ value: some QueryExpression<T>
  ) -> some QueryExpression<T> {
    SQLQueryExpression("ceiling(\(value.queryFragment))", as: T.self)
  }

  /// Returns the largest integer less than or equal to the value (floor)
  ///
  /// PostgreSQL's `floor()` function.
  ///
  /// ```swift
  /// Math.floor($0.value)
  /// // SELECT floor("measurements"."value")
  /// ```
  public static func floor<T: Numeric & QueryBindable>(
    _ value: some QueryExpression<T>
  ) -> some QueryExpression<T> {
    SQLQueryExpression("floor(\(value.queryFragment))", as: T.self)
  }

  /// Rounds to the nearest integer
  ///
  /// PostgreSQL's `round()` function.
  ///
  /// ```swift
  /// Math.round($0.value)
  /// // SELECT round("measurements"."value")
  /// ```
  public static func round<T: Numeric & QueryBindable>(
    _ value: some QueryExpression<T>
  ) -> some QueryExpression<T> {
    SQLQueryExpression("round(\(value.queryFragment))", as: T.self)
  }

  /// Rounds to a specified number of decimal places
  ///
  /// PostgreSQL's `round(numeric, int)` function.
  ///
  /// ```swift
  /// Math.round($0.price, decimalPlaces: 2)
  /// // SELECT round("products"."price", 2)
  /// ```
  ///
  /// - Parameters:
  ///   - value: The value to round
  ///   - decimalPlaces: Number of decimal places to round to
  public static func round<T: Numeric & QueryBindable>(
    _ value: some QueryExpression<T>,
    decimalPlaces: Int
  ) -> some QueryExpression<T> {
    SQLQueryExpression("round(\(value.queryFragment), \(decimalPlaces))", as: T.self)
  }

  /// Truncates to integer (toward zero)
  ///
  /// PostgreSQL's `trunc()` function.
  ///
  /// ```swift
  /// Math.trunc($0.value)
  /// // SELECT trunc("measurements"."value")
  /// ```
  public static func trunc<T: Numeric & QueryBindable>(
    _ value: some QueryExpression<T>
  ) -> some QueryExpression<T> {
    SQLQueryExpression("trunc(\(value.queryFragment))", as: T.self)
  }

  /// Truncates to a specified number of decimal places
  ///
  /// PostgreSQL's `trunc(numeric, int)` function.
  ///
  /// ```swift
  /// Math.trunc($0.price, decimalPlaces: 2)
  /// // SELECT trunc("products"."price", 2)
  /// ```
  ///
  /// - Parameters:
  ///   - value: The value to truncate
  ///   - decimalPlaces: Number of decimal places to truncate to
  public static func trunc<T: Numeric & QueryBindable>(
    _ value: some QueryExpression<T>,
    decimalPlaces: Int
  ) -> some QueryExpression<T> {
    SQLQueryExpression("trunc(\(value.queryFragment), \(decimalPlaces))", as: T.self)
  }
}

// MARK: - QueryExpression Extension (Fluent API)

extension QueryExpression where QueryValue: Numeric & QueryBindable {
  /// Returns the smallest integer greater than or equal to the value (ceiling)
  ///
  /// PostgreSQL's `ceil()` / `ceiling()` function.
  ///
  /// ```swift
  /// Measurement.select { $0.value.ceil() }
  /// // SELECT ceil("measurements"."value") FROM "measurements"
  /// ```
  public func ceil() -> some QueryExpression<QueryValue> {
    Math.ceil(self)
  }

  /// Returns the smallest integer greater than or equal to the value (ceiling)
  ///
  /// PostgreSQL's `ceiling()` function (alias for ceil).
  ///
  /// ```swift
  /// Measurement.select { $0.value.ceiling() }
  /// // SELECT ceiling("measurements"."value") FROM "measurements"
  /// ```
  public func ceiling() -> some QueryExpression<QueryValue> {
    Math.ceiling(self)
  }

  /// Returns the largest integer less than or equal to the value (floor)
  ///
  /// PostgreSQL's `floor()` function.
  ///
  /// ```swift
  /// Measurement.select { $0.value.floor() }
  /// // SELECT floor("measurements"."value") FROM "measurements"
  /// ```
  public func floor() -> some QueryExpression<QueryValue> {
    Math.floor(self)
  }

  /// Rounds to the nearest integer
  ///
  /// PostgreSQL's `round()` function.
  ///
  /// ```swift
  /// Measurement.select { $0.value.round() }
  /// // SELECT round("measurements"."value") FROM "measurements"
  /// ```
  public func round() -> some QueryExpression<QueryValue> {
    Math.round(self)
  }

  /// Rounds to a specified number of decimal places
  ///
  /// PostgreSQL's `round(numeric, int)` function.
  ///
  /// ```swift
  /// Product.select { $0.price.round(decimalPlaces: 2) }
  /// // SELECT round("products"."price", 2) FROM "products"
  /// ```
  ///
  /// - Parameter decimalPlaces: Number of decimal places to round to
  public func round(decimalPlaces: Int) -> some QueryExpression<QueryValue> {
    Math.round(self, decimalPlaces: decimalPlaces)
  }

  /// Truncates to integer (toward zero)
  ///
  /// PostgreSQL's `trunc()` function.
  ///
  /// ```swift
  /// Measurement.select { $0.value.trunc() }
  /// // SELECT trunc("measurements"."value") FROM "measurements"
  /// ```
  public func trunc() -> some QueryExpression<QueryValue> {
    Math.trunc(self)
  }

  /// Truncates to a specified number of decimal places
  ///
  /// PostgreSQL's `trunc(numeric, int)` function.
  ///
  /// ```swift
  /// Product.select { $0.price.trunc(decimalPlaces: 2) }
  /// // SELECT trunc("products"."price", 2) FROM "products"
  /// ```
  ///
  /// - Parameter decimalPlaces: Number of decimal places to truncate to
  public func trunc(decimalPlaces: Int) -> some QueryExpression<QueryValue> {
    Math.trunc(self, decimalPlaces: decimalPlaces)
  }
}
