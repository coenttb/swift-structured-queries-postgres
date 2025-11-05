import Foundation
import StructuredQueriesCore

// MARK: - Sign Functions
//
// PostgreSQL Chapter 9.3, Table 9.5: Mathematical Functions
// https://www.postgresql.org/docs/current/functions-math.html
//
// Functions for absolute value and sign determination.

extension Math {
    /// Returns the absolute value
    ///
    /// PostgreSQL's `abs()` function.
    ///
    /// ```swift
    /// Math.abs($0.amount)
    /// // SELECT abs("transactions"."amount")
    /// ```
    public static func abs<T: Numeric & QueryBindable>(
        _ value: some QueryExpression<T>
    ) -> some QueryExpression<T> {
        SQLQueryExpression("abs(\(value.queryFragment))", as: T.self)
    }

    /// Returns the sign of the value (-1, 0, or +1)
    ///
    /// PostgreSQL's `sign()` function.
    ///
    /// ```swift
    /// Math.sign($0.amount)
    /// // SELECT sign("transactions"."amount")
    /// ```
    ///
    /// - Returns: -1 for negative, 0 for zero, +1 for positive
    public static func sign<T: Numeric & QueryBindable>(
        _ value: some QueryExpression<T>
    ) -> some QueryExpression<T> {
        SQLQueryExpression("sign(\(value.queryFragment))", as: T.self)
    }
}

// MARK: - QueryExpression Extension (Fluent API)

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
        Math.abs(self)
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
        Math.sign(self)
    }
}
