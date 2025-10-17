import Foundation
import StructuredQueriesCore

// MARK: - Ranking Window Functions

/// PostgreSQL `ROW_NUMBER()` window function
///
/// Assigns a unique sequential number to each row within the window partition.
///
/// ```swift
/// User.select {
///     let createdAt = $0.createdAt
///     return ($0, rowNumber().over { $0.order(by: createdAt) })
/// }
/// // SELECT *, ROW_NUMBER() OVER (ORDER BY "created_at")
/// ```
///
/// - Returns: An integer expression with the row number
public func rowNumber() -> Window.Function<Int> {
    Window.Function(functionName: "ROW_NUMBER", arguments: [])
}

/// PostgreSQL `RANK()` window function
///
/// Assigns a rank to each row within the partition, with gaps for tied values.
/// Tied rows receive the same rank, and the next rank skips numbers.
///
/// ```swift
/// // Leaderboard with gaps for ties
/// Score.select {
///     let points = $0.points
///     return ($0, rank().over { $0.order(by: points.desc()) })
/// }
/// // Ranks: 1, 2, 2, 4, 5 (gap at 3)
/// ```
///
/// - Returns: A rank expression (bigint)
public func rank() -> Window.Function<Int> {
    Window.Function(functionName: "RANK", arguments: [])
}

/// PostgreSQL `DENSE_RANK()` window function
///
/// Assigns a rank to each row within the partition, without gaps for tied values.
/// Tied rows receive the same rank, and the next rank continues sequentially.
///
/// ```swift
/// // Leaderboard without gaps
/// Score.select {
///     let points = $0.points
///     return ($0, denseRank().over { $0.order(by: points.desc()) })
/// }
/// // Ranks: 1, 2, 2, 3, 4 (no gap)
/// ```
///
/// - Returns: A dense rank expression (bigint)
public func denseRank() -> Window.Function<Int> {
    Window.Function(functionName: "DENSE_RANK", arguments: [])
}

/// PostgreSQL `PERCENT_RANK()` window function
///
/// Calculates the relative rank of the current row: `(rank - 1) / (total rows - 1)`.
/// Returns a value between 0 and 1.
///
/// ```swift
/// Score.select {
///     let points = $0.points
///     return ($0, percentRank().over { $0.order(by: points.desc()) })
/// }
/// // Returns: 0.0, 0.25, 0.5, 0.75, 1.0
/// ```
///
/// - Returns: A double precision expression
public func percentRank() -> Window.Function<Double> {
    Window.Function(functionName: "PERCENT_RANK", arguments: [])
}

/// PostgreSQL `CUME_DIST()` window function
///
/// Calculates the cumulative distribution: (number of partition rows ≤ current row) / (total partition rows).
/// Returns a value between 0 and 1.
///
/// ```swift
/// Score.select {
///     let points = $0.points
///     return ($0, cumeDist().over { $0.order(by: points.desc()) })
/// }
/// ```
///
/// - Returns: A double precision expression
public func cumeDist() -> Window.Function<Double> {
    Window.Function(functionName: "CUME_DIST", arguments: [])
}

/// PostgreSQL `NTILE(n)` window function
///
/// Divides the partition into `n` buckets and assigns each row a bucket number (1 to n).
/// Useful for creating percentiles or quartiles.
///
/// ```swift
/// // Divide into quartiles
/// User.select {
///     let age = $0.age
///     return ($0, ntile(4).over { $0.order(by: age) })
/// }
/// // Returns: 1, 1, 2, 2, 3, 3, 4, 4
/// ```
///
/// - Parameter buckets: Number of buckets (must be positive)
/// - Returns: An integer expression (1 to n)
public func ntile(_ buckets: Int) -> Window.Function<Int> {
    precondition(buckets > 0, "ntile buckets must be positive")
    return Window.Function(
        functionName: "NTILE",
        arguments: [QueryFragment(stringLiteral: "\(buckets)")]
    )
}

// MARK: - Namespace Convenience

extension Window {
    /// PostgreSQL `ROW_NUMBER()` window function
    ///
    /// Assigns a unique sequential number to each row within the window partition.
    ///
    /// - Returns: An integer expression with the row number
    /// - SeeAlso: `rowNumber()` global function
    public static func rowNumber() -> Function<Int> {
        StructuredQueriesPostgres.rowNumber()
    }

    /// PostgreSQL `RANK()` window function
    ///
    /// Assigns a rank to each row within the partition, with gaps for tied values.
    ///
    /// - Returns: A rank expression (bigint)
    /// - SeeAlso: `rank()` global function
    public static func rank() -> Function<Int> {
        StructuredQueriesPostgres.rank()
    }

    /// PostgreSQL `DENSE_RANK()` window function
    ///
    /// Assigns a rank to each row within the partition, without gaps for tied values.
    ///
    /// - Returns: A dense rank expression (bigint)
    /// - SeeAlso: `denseRank()` global function
    public static func denseRank() -> Function<Int> {
        StructuredQueriesPostgres.denseRank()
    }

    /// PostgreSQL `PERCENT_RANK()` window function
    ///
    /// Calculates the relative rank of the current row: `(rank - 1) / (total rows - 1)`.
    ///
    /// - Returns: A double precision expression
    /// - SeeAlso: `percentRank()` global function
    public static func percentRank() -> Function<Double> {
        StructuredQueriesPostgres.percentRank()
    }

    /// PostgreSQL `CUME_DIST()` window function
    ///
    /// Calculates the cumulative distribution.
    ///
    /// - Returns: A double precision expression
    /// - SeeAlso: `cumeDist()` global function
    public static func cumeDist() -> Function<Double> {
        StructuredQueriesPostgres.cumeDist()
    }

    /// PostgreSQL `NTILE(n)` window function
    ///
    /// Divides the partition into `n` buckets.
    ///
    /// - Parameter buckets: Number of buckets (must be positive)
    /// - Returns: An integer expression (1 to n)
    /// - SeeAlso: `ntile(_:)` global function
    public static func ntile(_ buckets: Int) -> Function<Int> {
        StructuredQueriesPostgres.ntile(buckets)
    }
}
