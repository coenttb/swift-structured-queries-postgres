import Foundation
import StructuredQueriesCore

// MARK: - Number Theory Functions
//
// PostgreSQL Chapter 9.3, Table 9.5: Mathematical Functions
// https://www.postgresql.org/docs/current/functions-math.html
//
// Functions for number theory: GCD, LCM, factorial, and scale operations.

extension Math {
  /// Returns the greatest common divisor
  ///
  /// PostgreSQL's `gcd()` function.
  ///
  /// ```swift
  /// Math.gcd($0.a, $0.b)
  /// // SELECT gcd("numbers"."a", "numbers"."b")
  /// ```
  public static func gcd<T: Numeric & QueryBindable>(
    _ a: some QueryExpression<T>,
    _ b: T
  ) -> some QueryExpression<T> {
    SQLQueryExpression("gcd(\(a.queryFragment), \(bind: b))", as: T.self)
  }

  /// Returns the greatest common divisor with an expression
  ///
  /// PostgreSQL's `gcd()` function.
  public static func gcd<T: Numeric & QueryBindable>(
    _ a: some QueryExpression<T>,
    _ b: some QueryExpression<T>
  ) -> some QueryExpression<T> {
    SQLQueryExpression("gcd(\(a.queryFragment), \(b.queryFragment))", as: T.self)
  }

  /// Returns the least common multiple
  ///
  /// PostgreSQL's `lcm()` function.
  ///
  /// ```swift
  /// Math.lcm($0.a, $0.b)
  /// // SELECT lcm("numbers"."a", "numbers"."b")
  /// ```
  public static func lcm<T: Numeric & QueryBindable>(
    _ a: some QueryExpression<T>,
    _ b: T
  ) -> some QueryExpression<T> {
    SQLQueryExpression("lcm(\(a.queryFragment), \(bind: b))", as: T.self)
  }

  /// Returns the least common multiple with an expression
  ///
  /// PostgreSQL's `lcm()` function.
  public static func lcm<T: Numeric & QueryBindable>(
    _ a: some QueryExpression<T>,
    _ b: some QueryExpression<T>
  ) -> some QueryExpression<T> {
    SQLQueryExpression("lcm(\(a.queryFragment), \(b.queryFragment))", as: T.self)
  }

  /// Returns the factorial
  ///
  /// PostgreSQL's `factorial()` function.
  ///
  /// ```swift
  /// Math.factorial($0.value)
  /// // SELECT factorial("numbers"."value")
  /// ```
  ///
  /// > Note: PostgreSQL also supports the `!` postfix operator for factorial,
  /// > but this function syntax is more explicit.
  public static func factorial(_ value: some QueryExpression<Int>) -> some QueryExpression<Int> {
    SQLQueryExpression("factorial(\(value.queryFragment))", as: Int.self)
  }

  /// Returns the minimum scale (number of decimal digits) needed to represent the value
  ///
  /// PostgreSQL's `min_scale()` function.
  ///
  /// ```swift
  /// Math.minScale($0.value)
  /// // SELECT min_scale("decimals"."value")
  /// ```
  public static func minScale<T: Numeric & QueryBindable>(
    _ value: some QueryExpression<T>
  ) -> some QueryExpression<Int> {
    SQLQueryExpression("min_scale(\(value.queryFragment))", as: Int.self)
  }

  /// Reduces the scale by removing trailing zeroes
  ///
  /// PostgreSQL's `trim_scale()` function.
  ///
  /// ```swift
  /// Math.trimScale($0.value)
  /// // SELECT trim_scale("decimals"."value")
  /// ```
  public static func trimScale<T: Numeric & QueryBindable>(
    _ value: some QueryExpression<T>
  ) -> some QueryExpression<T> {
    SQLQueryExpression("trim_scale(\(value.queryFragment))", as: T.self)
  }
}

// MARK: - QueryExpression Extension (Fluent API)

extension QueryExpression where QueryValue: Numeric & QueryBindable {
  /// Returns the greatest common divisor
  ///
  /// PostgreSQL's `gcd()` function.
  ///
  /// ```swift
  /// Number.select { $0.a.gcd($0.b) }
  /// // SELECT gcd("numbers"."a", "numbers"."b") FROM "numbers"
  /// ```
  public func gcd(_ other: QueryValue) -> some QueryExpression<QueryValue> {
    Math.gcd(self, other)
  }

  /// Returns the greatest common divisor with an expression
  ///
  /// PostgreSQL's `gcd()` function.
  public func gcd(_ other: some QueryExpression<QueryValue>) -> some QueryExpression<QueryValue> {
    Math.gcd(self, other)
  }

  /// Returns the least common multiple
  ///
  /// PostgreSQL's `lcm()` function.
  ///
  /// ```swift
  /// Number.select { $0.a.lcm($0.b) }
  /// // SELECT lcm("numbers"."a", "numbers"."b") FROM "numbers"
  /// ```
  public func lcm(_ other: QueryValue) -> some QueryExpression<QueryValue> {
    Math.lcm(self, other)
  }

  /// Returns the least common multiple with an expression
  ///
  /// PostgreSQL's `lcm()` function.
  public func lcm(_ other: some QueryExpression<QueryValue>) -> some QueryExpression<QueryValue> {
    Math.lcm(self, other)
  }

  /// Returns the minimum scale (number of decimal digits) needed to represent the value
  ///
  /// PostgreSQL's `min_scale()` function.
  ///
  /// ```swift
  /// Decimal.select { $0.value.minScale() }
  /// // SELECT min_scale("decimals"."value") FROM "decimals"
  /// ```
  public func minScale() -> some QueryExpression<Int> {
    Math.minScale(self)
  }

  /// Reduces the scale by removing trailing zeroes
  ///
  /// PostgreSQL's `trim_scale()` function.
  ///
  /// ```swift
  /// Decimal.select { $0.value.trimScale() }
  /// // SELECT trim_scale("decimals"."value") FROM "decimals"
  /// ```
  public func trimScale() -> some QueryExpression<QueryValue> {
    Math.trimScale(self)
  }
}

extension QueryExpression where QueryValue == Int {
  /// Returns the factorial
  ///
  /// PostgreSQL's `factorial()` function.
  ///
  /// ```swift
  /// Number.select { $0.value.factorial() }
  /// // SELECT factorial("numbers"."value") FROM "numbers"
  /// ```
  ///
  /// > Note: PostgreSQL also supports the `!` postfix operator for factorial,
  /// > but this function syntax is more explicit.
  public func factorial() -> some QueryExpression<Int> {
    Math.factorial(self)
  }
}
