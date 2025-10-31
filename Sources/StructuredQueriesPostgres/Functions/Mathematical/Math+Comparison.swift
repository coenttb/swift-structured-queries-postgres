import Foundation
import StructuredQueriesCore

// MARK: - Comparison Functions
//
// PostgreSQL Chapter 9.3, Table 9.5: Mathematical Functions
// https://www.postgresql.org/docs/current/functions-math.html
//
// Functions for comparing values: min, max, least, greatest

extension Math {
  /// Returns the smaller of two values
  ///
  /// PostgreSQL's `least()` function for two values.
  ///
  /// ```swift
  /// Math.min($0.price, $0.comparePrice)
  /// // SELECT least("products"."price", "products"."comparePrice")
  /// ```
  ///
  /// > Note: For finding minimum across multiple values, use `least()` function.
  public static func min<T: Comparable & QueryBindable>(
    _ a: some QueryExpression<T>,
    _ b: T
  ) -> some QueryExpression<T> {
    SQLQueryExpression("least(\(a.queryFragment), \(bind: b))", as: T.self)
  }

  /// Returns the smaller of two expression values
  ///
  /// PostgreSQL's `least()` function for two values.
  public static func min<T: Comparable & QueryBindable>(
    _ a: some QueryExpression<T>,
    _ b: some QueryExpression<T>
  ) -> some QueryExpression<T> {
    SQLQueryExpression("least(\(a.queryFragment), \(b.queryFragment))", as: T.self)
  }

  /// Returns the larger of two values
  ///
  /// PostgreSQL's `greatest()` function for two values.
  ///
  /// ```swift
  /// Math.max($0.price, $0.comparePrice)
  /// // SELECT greatest("products"."price", "products"."comparePrice")
  /// ```
  ///
  /// > Note: For finding maximum across multiple values, use `greatest()` function.
  public static func max<T: Comparable & QueryBindable>(
    _ a: some QueryExpression<T>,
    _ b: T
  ) -> some QueryExpression<T> {
    SQLQueryExpression("greatest(\(a.queryFragment), \(bind: b))", as: T.self)
  }

  /// Returns the larger of two expression values
  ///
  /// PostgreSQL's `greatest()` function for two values.
  public static func max<T: Comparable & QueryBindable>(
    _ a: some QueryExpression<T>,
    _ b: some QueryExpression<T>
  ) -> some QueryExpression<T> {
    SQLQueryExpression("greatest(\(a.queryFragment), \(b.queryFragment))", as: T.self)
  }
}

// MARK: - QueryExpression Extension (Fluent API)

extension QueryExpression where QueryValue: Comparable & QueryBindable {
  /// Returns the smaller of two values
  ///
  /// PostgreSQL's `least()` function for two values.
  ///
  /// ```swift
  /// Product.select { $0.price.min($0.comparePrice) }
  /// // SELECT least("products"."price", "products"."comparePrice") FROM "products"
  /// ```
  ///
  /// > Note: For finding minimum across multiple values, use `least()` function.
  /// > The `@_disfavoredOverload` attribute ensures Swift's stdlib `Sequence.min()` is preferred
  /// > for regular Swift collections, while this method is available for QueryExpressions.
  @_disfavoredOverload
  public func min(_ other: QueryValue) -> some QueryExpression<QueryValue> {
    Math.min(self, other)
  }

  /// Returns the smaller of two expression values
  ///
  /// PostgreSQL's `least()` function for two values.
  ///
  /// > Note: The `@_disfavoredOverload` attribute ensures Swift's stdlib `Sequence.min()` is preferred
  /// > for regular Swift collections, while this method is available for QueryExpressions.
  @_disfavoredOverload
  public func min(_ other: some QueryExpression<QueryValue>) -> some QueryExpression<QueryValue> {
    Math.min(self, other)
  }

  /// Returns the larger of two values
  ///
  /// PostgreSQL's `greatest()` function for two values.
  ///
  /// ```swift
  /// Product.select { $0.price.max($0.comparePrice) }
  /// // SELECT greatest("products"."price", "products"."comparePrice") FROM "products"
  /// ```
  ///
  /// > Note: For finding maximum across multiple values, use `greatest()` function.
  /// > The `@_disfavoredOverload` attribute ensures Swift's stdlib `Sequence.max()` is preferred
  /// > for regular Swift collections, while this method is available for QueryExpressions.
  @_disfavoredOverload
  public func max(_ other: QueryValue) -> some QueryExpression<QueryValue> {
    Math.max(self, other)
  }

  /// Returns the larger of two expression values
  ///
  /// PostgreSQL's `greatest()` function for two values.
  ///
  /// > Note: The `@_disfavoredOverload` attribute ensures Swift's stdlib `Sequence.max()` is preferred
  /// > for regular Swift collections, while this method is available for QueryExpressions.
  @_disfavoredOverload
  public func max(_ other: some QueryExpression<QueryValue>) -> some QueryExpression<QueryValue> {
    Math.max(self, other)
  }
}
