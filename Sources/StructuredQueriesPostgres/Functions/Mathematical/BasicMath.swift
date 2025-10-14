import Foundation
import StructuredQueriesCore

// MARK: - PostgreSQL Basic Mathematical Functions
//
// PostgreSQL Chapter 9.3: Mathematical Functions and Operators
// https://www.postgresql.org/docs/18/functions-math.html
//
// Basic mathematical functions for rounding, absolute values, and sign operations.

extension QueryExpression where QueryValue: Numeric & QueryBindable {
    /// Returns the absolute value
    ///
    /// PostgreSQL's `abs()` function.
    ///
    /// ```swift
    /// Transaction.select { $0.amount.abs() }
    /// // SELECT abs("transactions"."amount") FROM "transactions"
    /// ```
    public func abs() -> some QueryExpression<QueryValue> {
        SQLQueryExpression(
            "abs(\(self.queryFragment))",
            as: QueryValue.self
        )
    }

    /// Returns the smallest integer greater than or equal to the value (ceiling)
    ///
    /// PostgreSQL's `ceil()` / `ceiling()` function.
    ///
    /// ```swift
    /// Measurement.select { $0.value.ceil() }
    /// // SELECT ceil("measurements"."value") FROM "measurements"
    /// ```
    public func ceil() -> some QueryExpression<QueryValue> {
        SQLQueryExpression(
            "ceil(\(self.queryFragment))",
            as: QueryValue.self
        )
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
        SQLQueryExpression(
            "ceiling(\(self.queryFragment))",
            as: QueryValue.self
        )
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
        SQLQueryExpression(
            "floor(\(self.queryFragment))",
            as: QueryValue.self
        )
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
        SQLQueryExpression(
            "round(\(self.queryFragment))",
            as: QueryValue.self
        )
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
        SQLQueryExpression(
            "round(\(self.queryFragment), \(decimalPlaces))",
            as: QueryValue.self
        )
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
        SQLQueryExpression(
            "trunc(\(self.queryFragment))",
            as: QueryValue.self
        )
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
        SQLQueryExpression(
            "trunc(\(self.queryFragment), \(decimalPlaces))",
            as: QueryValue.self
        )
    }

    /// Returns the sign of the value (-1, 0, or +1)
    ///
    /// PostgreSQL's `sign()` function.
    ///
    /// ```swift
    /// Transaction.select { $0.amount.sign() }
    /// // SELECT sign("transactions"."amount") FROM "transactions"
    /// ```
    ///
    /// - Returns: -1 for negative, 0 for zero, +1 for positive
    public func sign() -> some QueryExpression<QueryValue> {
        SQLQueryExpression(
            "sign(\(self.queryFragment))",
            as: QueryValue.self
        )
    }
}

// MARK: - Modulo Operation

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
        SQLQueryExpression(
            "mod(\(self.queryFragment), \(bind: divisor))",
            as: QueryValue.self
        )
    }

    /// Returns the remainder of division using an expression
    ///
    /// PostgreSQL's `mod()` function.
    ///
    /// ```swift
    /// Number.select { $0.value.mod($0.divisor) }
    /// // SELECT mod("numbers"."value", "numbers"."divisor") FROM "numbers"
    /// ```
    public func mod(_ divisor: some QueryExpression<QueryValue>) -> some QueryExpression<QueryValue>
    {
        SQLQueryExpression(
            "mod(\(self.queryFragment), \(divisor.queryFragment))",
            as: QueryValue.self
        )
    }
}

// MARK: - Division Operations

extension QueryExpression where QueryValue: Numeric & QueryBindable {
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
        SQLQueryExpression(
            "div(\(self.queryFragment), \(bind: divisor))",
            as: QueryValue.self
        )
    }
}

// MARK: - Greatest Common Divisor and Least Common Multiple

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
        SQLQueryExpression(
            "gcd(\(self.queryFragment), \(bind: other))",
            as: QueryValue.self
        )
    }

    /// Returns the greatest common divisor with an expression
    ///
    /// PostgreSQL's `gcd()` function.
    public func gcd(_ other: some QueryExpression<QueryValue>) -> some QueryExpression<QueryValue> {
        SQLQueryExpression(
            "gcd(\(self.queryFragment), \(other.queryFragment))",
            as: QueryValue.self
        )
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
        SQLQueryExpression(
            "lcm(\(self.queryFragment), \(bind: other))",
            as: QueryValue.self
        )
    }

    /// Returns the least common multiple with an expression
    ///
    /// PostgreSQL's `lcm()` function.
    public func lcm(_ other: some QueryExpression<QueryValue>) -> some QueryExpression<QueryValue> {
        SQLQueryExpression(
            "lcm(\(self.queryFragment), \(other.queryFragment))",
            as: QueryValue.self
        )
    }
}

// MARK: - Min/Max of Two Values

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
    public func min(_ other: QueryValue) -> some QueryExpression<QueryValue> {
        SQLQueryExpression(
            "least(\(self.queryFragment), \(bind: other))",
            as: QueryValue.self
        )
    }

    /// Returns the smaller of two expression values
    ///
    /// PostgreSQL's `least()` function for two values.
    public func min(_ other: some QueryExpression<QueryValue>) -> some QueryExpression<QueryValue> {
        SQLQueryExpression(
            "least(\(self.queryFragment), \(other.queryFragment))",
            as: QueryValue.self
        )
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
    public func max(_ other: QueryValue) -> some QueryExpression<QueryValue> {
        SQLQueryExpression(
            "greatest(\(self.queryFragment), \(bind: other))",
            as: QueryValue.self
        )
    }

    /// Returns the larger of two expression values
    ///
    /// PostgreSQL's `greatest()` function for two values.
    public func max(_ other: some QueryExpression<QueryValue>) -> some QueryExpression<QueryValue> {
        SQLQueryExpression(
            "greatest(\(self.queryFragment), \(other.queryFragment))",
            as: QueryValue.self
        )
    }
}
