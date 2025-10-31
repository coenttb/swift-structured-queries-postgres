import Foundation
import StructuredQueriesCore

// MARK: - PostgreSQL Comparison Functions
//
// PostgreSQL Chapter 9.2: Comparison Functions and Operators
// https://www.postgresql.org/docs/18/functions-comparison.html
//
// Functions for comparing values beyond basic operators.

// MARK: - GREATEST and LEAST

/// Returns the greatest (largest) value from two expressions
///
/// PostgreSQL's `GREATEST()` function.
///
/// ```swift
/// Product.select { greatest($0.price, $0.comparePrice) }
/// // SELECT GREATEST("products"."price", "products"."comparePrice") FROM "products"
/// ```
public func greatest<Value: Comparable & QueryBindable>(
  _ v1: some QueryExpression<Value>,
  _ v2: some QueryExpression<Value>
) -> some QueryExpression<Value?> {
  SQLQueryExpression(
    "GREATEST(\(v1.queryFragment), \(v2.queryFragment))",
    as: Value?.self
  )
}

/// Returns the greatest (largest) value from three expressions
public func greatest<Value: Comparable & QueryBindable>(
  _ v1: some QueryExpression<Value>,
  _ v2: some QueryExpression<Value>,
  _ v3: some QueryExpression<Value>
) -> some QueryExpression<Value?> {
  SQLQueryExpression(
    "GREATEST(\(v1.queryFragment), \(v2.queryFragment), \(v3.queryFragment))",
    as: Value?.self
  )
}

/// Returns the greatest (largest) value from four expressions
public func greatest<Value: Comparable & QueryBindable>(
  _ v1: some QueryExpression<Value>,
  _ v2: some QueryExpression<Value>,
  _ v3: some QueryExpression<Value>,
  _ v4: some QueryExpression<Value>
) -> some QueryExpression<Value?> {
  SQLQueryExpression(
    "GREATEST(\(v1.queryFragment), \(v2.queryFragment), \(v3.queryFragment), \(v4.queryFragment))",
    as: Value?.self
  )
}

/// Returns the greatest (largest) value from an array of literal values
///
/// PostgreSQL's `GREATEST()` function with literal values.
///
/// ```swift
/// let max = greatest(10, 20, 30, 5)
/// // GREATEST(10, 20, 30, 5)
/// ```
public func greatest<Value: Comparable & QueryBindable>(
  _ values: Value...
) -> some QueryExpression<Value?> {
  let fragments = values.map { "\(bind: $0)" }.joined(separator: ", ")
  return SQLQueryExpression(
    "GREATEST(\(fragments))",
    as: Value?.self
  )
}

/// Returns the least (smallest) value from two expressions
///
/// PostgreSQL's `LEAST()` function.
///
/// ```swift
/// Product.select { least($0.price, $0.salePrice) }
/// // SELECT LEAST("products"."price", "products"."salePrice") FROM "products"
/// ```
public func least<Value: Comparable & QueryBindable>(
  _ v1: some QueryExpression<Value>,
  _ v2: some QueryExpression<Value>
) -> some QueryExpression<Value?> {
  SQLQueryExpression(
    "LEAST(\(v1.queryFragment), \(v2.queryFragment))",
    as: Value?.self
  )
}

/// Returns the least (smallest) value from three expressions
public func least<Value: Comparable & QueryBindable>(
  _ v1: some QueryExpression<Value>,
  _ v2: some QueryExpression<Value>,
  _ v3: some QueryExpression<Value>
) -> some QueryExpression<Value?> {
  SQLQueryExpression(
    "LEAST(\(v1.queryFragment), \(v2.queryFragment), \(v3.queryFragment))",
    as: Value?.self
  )
}

/// Returns the least (smallest) value from four expressions
public func least<Value: Comparable & QueryBindable>(
  _ v1: some QueryExpression<Value>,
  _ v2: some QueryExpression<Value>,
  _ v3: some QueryExpression<Value>,
  _ v4: some QueryExpression<Value>
) -> some QueryExpression<Value?> {
  SQLQueryExpression(
    "LEAST(\(v1.queryFragment), \(v2.queryFragment), \(v3.queryFragment), \(v4.queryFragment))",
    as: Value?.self
  )
}

/// Returns the least (smallest) value from an array of literal values
///
/// PostgreSQL's `LEAST()` function with literal values.
///
/// ```swift
/// let min = least(10, 20, 5, 30)
/// // LEAST(10, 20, 5, 30)
/// ```
public func least<Value: Comparable & QueryBindable>(
  _ values: Value...
) -> some QueryExpression<Value?> {
  let fragments = values.map { "\(bind: $0)" }.joined(separator: ", ")
  return SQLQueryExpression(
    "LEAST(\(fragments))",
    as: Value?.self
  )
}

// MARK: - NUM_NONNULLS and NUM_NULLS

/// Returns the number of non-null arguments
///
/// PostgreSQL's `num_nonnulls()` function.
///
/// ```swift
/// User.select { numNonNulls($0.email, $0.phone) }
/// // SELECT num_nonnulls("users"."email", "users"."phone") FROM "users"
/// ```
public func numNonNulls<Value: QueryBindable>(
  _ v1: some QueryExpression<Value?>,
  _ v2: some QueryExpression<Value?>
) -> some QueryExpression<Int> {
  SQLQueryExpression(
    "num_nonnulls(\(v1.queryFragment), \(v2.queryFragment))",
    as: Int.self
  )
}

/// Returns the number of non-null arguments (3 arguments)
public func numNonNulls<Value: QueryBindable>(
  _ v1: some QueryExpression<Value?>,
  _ v2: some QueryExpression<Value?>,
  _ v3: some QueryExpression<Value?>
) -> some QueryExpression<Int> {
  SQLQueryExpression(
    "num_nonnulls(\(v1.queryFragment), \(v2.queryFragment), \(v3.queryFragment))",
    as: Int.self
  )
}

/// Returns the number of non-null arguments (4 arguments)
public func numNonNulls<Value: QueryBindable>(
  _ v1: some QueryExpression<Value?>,
  _ v2: some QueryExpression<Value?>,
  _ v3: some QueryExpression<Value?>,
  _ v4: some QueryExpression<Value?>
) -> some QueryExpression<Int> {
  SQLQueryExpression(
    "num_nonnulls(\(v1.queryFragment), \(v2.queryFragment), \(v3.queryFragment), \(v4.queryFragment))",
    as: Int.self
  )
}

/// Returns the number of null arguments
///
/// PostgreSQL's `num_nulls()` function.
///
/// ```swift
/// User.select { numNulls($0.email, $0.phone) }
/// // SELECT num_nulls("users"."email", "users"."phone") FROM "users"
/// ```
public func numNulls<Value: QueryBindable>(
  _ v1: some QueryExpression<Value?>,
  _ v2: some QueryExpression<Value?>
) -> some QueryExpression<Int> {
  SQLQueryExpression(
    "num_nulls(\(v1.queryFragment), \(v2.queryFragment))",
    as: Int.self
  )
}

/// Returns the number of null arguments (3 arguments)
public func numNulls<Value: QueryBindable>(
  _ v1: some QueryExpression<Value?>,
  _ v2: some QueryExpression<Value?>,
  _ v3: some QueryExpression<Value?>
) -> some QueryExpression<Int> {
  SQLQueryExpression(
    "num_nulls(\(v1.queryFragment), \(v2.queryFragment), \(v3.queryFragment))",
    as: Int.self
  )
}

/// Returns the number of null arguments (4 arguments)
public func numNulls<Value: QueryBindable>(
  _ v1: some QueryExpression<Value?>,
  _ v2: some QueryExpression<Value?>,
  _ v3: some QueryExpression<Value?>,
  _ v4: some QueryExpression<Value?>
) -> some QueryExpression<Int> {
  SQLQueryExpression(
    "num_nulls(\(v1.queryFragment), \(v2.queryFragment), \(v3.queryFragment), \(v4.queryFragment))",
    as: Int.self
  )
}

// MARK: - IS DISTINCT FROM / IS NOT DISTINCT FROM

extension QueryExpression where QueryValue: Equatable & QueryBindable {
  /// Tests if two values are distinct (treats NULL as a comparable value)
  ///
  /// PostgreSQL's `IS DISTINCT FROM` operator.
  ///
  /// ```swift
  /// User.where { $0.status.isDistinctFrom("active") }
  /// // WHERE "users"."status" IS DISTINCT FROM 'active'
  /// ```
  ///
  /// Unlike `!=`, this returns:
  /// - `true` if one value is NULL and the other isn't
  /// - `false` if both values are NULL
  /// - Same as `!=` for non-NULL values
  public func isDistinctFrom(_ other: QueryValue) -> some QueryExpression<Bool> {
    SQLQueryExpression(
      "(\(self.queryFragment) IS DISTINCT FROM \(bind: other))",
      as: Bool.self
    )
  }

  /// Tests if two expressions are distinct (treats NULL as a comparable value)
  ///
  /// PostgreSQL's `IS DISTINCT FROM` operator.
  ///
  /// ```swift
  /// User.where { $0.currentStatus.isDistinctFrom($0.previousStatus) }
  /// // WHERE "users"."currentStatus" IS DISTINCT FROM "users"."previousStatus"
  /// ```
  public func isDistinctFrom(_ other: some QueryExpression<QueryValue>) -> some QueryExpression<
    Bool
  > {
    SQLQueryExpression(
      "(\(self.queryFragment) IS DISTINCT FROM \(other.queryFragment))",
      as: Bool.self
    )
  }

  /// Tests if two values are not distinct (treats NULL as a comparable value)
  ///
  /// PostgreSQL's `IS NOT DISTINCT FROM` operator.
  ///
  /// ```swift
  /// User.where { $0.status.isNotDistinctFrom("active") }
  /// // WHERE "users"."status" IS NOT DISTINCT FROM 'active'
  /// ```
  ///
  /// Unlike `==`, this returns:
  /// - `false` if one value is NULL and the other isn't
  /// - `true` if both values are NULL
  /// - Same as `==` for non-NULL values
  ///
  /// > Note: Useful for NULL-safe equality comparisons
  public func isNotDistinctFrom(_ other: QueryValue) -> some QueryExpression<Bool> {
    SQLQueryExpression(
      "(\(self.queryFragment) IS NOT DISTINCT FROM \(bind: other))",
      as: Bool.self
    )
  }

  /// Tests if two expressions are not distinct (treats NULL as a comparable value)
  ///
  /// PostgreSQL's `IS NOT DISTINCT FROM` operator.
  public func isNotDistinctFrom(_ other: some QueryExpression<QueryValue>)
    -> some QueryExpression<Bool>
  {
    SQLQueryExpression(
      "(\(self.queryFragment) IS NOT DISTINCT FROM \(other.queryFragment))",
      as: Bool.self
    )
  }
}

// MARK: - NULLIF

/// Returns NULL if two values are equal, otherwise returns the first value
///
/// PostgreSQL's `NULLIF()` function.
///
/// ```swift
/// Product.select { nullif($0.salePrice, $0.regularPrice) }
/// // SELECT NULLIF("products"."salePrice", "products"."regularPrice") FROM "products"
/// ```
///
/// - Parameters:
///   - value1: First value
///   - value2: Value to compare against
/// - Returns: NULL if values are equal, otherwise value1
///
/// > Note: Useful for avoiding division by zero: `nullif($0.quantity, 0)`
public func nullif<Value: Equatable & QueryBindable>(
  _ value1: some QueryExpression<Value>,
  _ value2: some QueryExpression<Value>
) -> some QueryExpression<Value?> {
  SQLQueryExpression(
    "NULLIF(\(value1.queryFragment), \(value2.queryFragment))",
    as: Value?.self
  )
}

/// Returns NULL if value equals the specified value, otherwise returns the value
///
/// PostgreSQL's `NULLIF()` function with literal comparison.
///
/// ```swift
/// Stats.select { nullif($0.count, 0) }
/// // SELECT NULLIF("stats"."count", 0) FROM "stats"
/// ```
public func nullif<Value: Equatable & QueryBindable>(
  _ value: some QueryExpression<Value>,
  _ compareTo: Value
) -> some QueryExpression<Value?> {
  SQLQueryExpression(
    "NULLIF(\(value.queryFragment), \(bind: compareTo))",
    as: Value?.self
  )
}

extension QueryExpression where QueryValue: Equatable & QueryBindable {
  /// Returns NULL if this value equals the specified value, otherwise returns this value
  ///
  /// PostgreSQL's `NULLIF()` function.
  ///
  /// ```swift
  /// Product.select { $0.discount.nullif(0) }
  /// // SELECT NULLIF("products"."discount", 0) FROM "products"
  /// ```
  ///
  /// Useful for:
  /// - Avoiding division by zero
  /// - Converting sentinel values to NULL
  /// - Conditional NULL handling
  public func nullif(_ other: QueryValue) -> some QueryExpression<QueryValue?> {
    SQLQueryExpression(
      "NULLIF(\(self.queryFragment), \(bind: other))",
      as: QueryValue?.self
    )
  }

  /// Returns NULL if this value equals another expression, otherwise returns this value
  ///
  /// PostgreSQL's `NULLIF()` function.
  public func nullif(_ other: some QueryExpression<QueryValue>) -> some QueryExpression<
    QueryValue?
  > {
    SQLQueryExpression(
      "NULLIF(\(self.queryFragment), \(other.queryFragment))",
      as: QueryValue?.self
    )
  }
}
