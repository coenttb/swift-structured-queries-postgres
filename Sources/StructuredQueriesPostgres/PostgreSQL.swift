import Foundation
import StructuredQueriesCore

// MARK: - PostgreSQL Namespace
//
// Top-level namespace for PostgreSQL-specific functions that would conflict
// with Swift standard library types.
//
// ## Usage
//
// ```swift
// // String functions (avoids conflict with Swift.String)
// PostgreSQL.String.upper($0.name)
//
// // Array functions (avoids conflict with Swift.Array)
// PostgreSQL.Array.contains($0.tags, "swift")
// ```
//
// ## Note
//
// Other PostgreSQL namespaces that don't conflict remain at the top level:
// - `Math` (no conflict)
// - `Window` (no conflict)
// - `Conditional` (no conflict)
// - `TextSearch` (no conflict)

/// Top-level namespace for PostgreSQL functions that would conflict with Swift stdlib
///
/// This enum cannot be instantiated - it serves purely as a namespace.
public enum PostgreSQL {}
