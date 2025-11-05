import Foundation
import StructuredQueriesCore

// MARK: - Random Functions
//
// PostgreSQL Chapter 9.3, Table 9.6: Random Functions
// https://www.postgresql.org/docs/current/functions-math.html
//
// Functions for generating pseudo-random numbers.

extension Math {
    /// Returns a random value between 0.0 and 1.0
    ///
    /// PostgreSQL's `random()` function.
    ///
    /// ```swift
    /// Post.select { Math.random() }
    /// // SELECT random() FROM "posts"
    /// ```
    ///
    /// > Note: This generates a new random value for each row.
    public static func random() -> some QueryExpression<Double> {
        SQLQueryExpression("random()", as: Double.self)
    }

    /// Sets the seed for subsequent `random()` calls
    ///
    /// PostgreSQL's `setseed()` function.
    ///
    /// ```swift
    /// Math.setseed(0.5)
    /// // SELECT setseed(0.5)
    /// ```
    ///
    /// - Parameter seed: A value between -1.0 and 1.0
    ///
    /// > Note: This affects the session's random number generator state.
    /// > Useful for reproducible test data.
    public static func setseed(_ seed: Double) -> some QueryExpression<Void> {
        SQLQueryExpression("setseed(\(bind: seed))", as: Void.self)
    }
}

// MARK: - Global Functions (For Convenience)

/// Returns a random value between 0.0 and 1.0
///
/// PostgreSQL's `random()` function.
///
/// ```swift
/// Post.select { random() }
/// // SELECT random() FROM "posts"
/// ```
///
/// > Note: This generates a new random value for each row.
public func random() -> some QueryExpression<Double> {
    Math.random()
}

/// Sets the seed for subsequent `random()` calls
///
/// PostgreSQL's `setseed()` function.
///
/// ```swift
/// // Set seed for reproducible random sequences
/// setseed(0.5)
/// // SELECT setseed(0.5)
/// ```
///
/// - Parameter seed: A value between -1.0 and 1.0
///
/// > Note: This affects the session's random number generator state.
/// > Useful for reproducible test data.
public func setseed(_ seed: Double) -> some QueryExpression<Void> {
    Math.setseed(seed)
}
