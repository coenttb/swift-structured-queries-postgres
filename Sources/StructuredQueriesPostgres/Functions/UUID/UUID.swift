import Foundation
import StructuredQueriesCore

// MARK: - PostgreSQL UUID Functions Namespace
//
// PostgreSQL Chapter 9.14: UUID Functions
// https://www.postgresql.org/docs/18/functions-uuid.html
//
// ## Organization (Matches PostgreSQL Chapter 9.14)
//
// - **Generation**: random()/v4(), timeOrdered()/v7(), timeOrdered(shift:)
// - **Extraction**: extractVersion(), extractTimestamp()
//
// ## Dual API Pattern
//
// UUID functions support two calling styles:
//
// **Namespace style (generation only):**
// ```swift
// PostgreSQL.UUID.random()
// PostgreSQL.UUID.timeOrdered()
// PostgreSQL.UUID.timeOrdered(shift: "-1 hour")
// ```
//
// **Method style (extraction):**
// ```swift
// $0.id.extractVersion()
// $0.id.extractTimestamp()
// ```
//
// **Static properties (generation - most common):**
// ```swift
// User.insert { User.Draft(id: .random, name: "Alice") }
// Event.insert { Event.Draft(id: .timeOrdered, title: "Login") }
// ```
//
// All styles compile to identical SQL. Choose based on context and readability.

extension PostgreSQL {
    /// Namespace for PostgreSQL UUID functions
    ///
    /// This enum cannot be instantiated - it serves purely as a namespace.
    public enum UUID {}
}
