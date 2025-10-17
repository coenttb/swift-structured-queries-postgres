import Foundation
import StructuredQueriesCore

// MARK: - PostgreSQL Window Functions
//
// PostgreSQL Chapter 9.22: Window Functions
// https://www.postgresql.org/docs/current/functions-window.html
//
// Window functions perform calculations across sets of rows related to the current row.

/// Namespace for PostgreSQL window function types and operations
///
/// Window functions perform calculations across sets of rows that are related to the current row.
/// Unlike aggregate functions, window functions do not collapse rows into a single output row.
///
/// ## Usage
///
/// ```swift
/// // Use global constructors for ergonomics
/// User.select {
///     ($0, rowNumber().over { $0.order(by: $0.createdAt) })
/// }
///
/// // Or use namespace explicitly
/// User.select {
///     ($0, Window.rowNumber().over { $0.order(by: $0.createdAt) })
/// }
/// ```
///
/// ## Common Window Functions
///
/// - Ranking: `rowNumber()`, `rank()`, `denseRank()`, `percentRank()`, `cumeDist()`, `ntile(n)`
/// - Value access: `.lag()`, `.lead()`, `.firstValue()`, `.lastValue()`, `.nthValue(n)`
public enum Window {}
