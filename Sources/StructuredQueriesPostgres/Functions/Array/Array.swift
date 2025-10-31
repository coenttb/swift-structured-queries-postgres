import Foundation
import StructuredQueriesCore

// MARK: - PostgreSQL Array Functions Namespace
//
// PostgreSQL Chapter 9.19: Array Functions and Operators
// https://www.postgresql.org/docs/18/functions-array.html
//
// ## Organization (Matches PostgreSQL Chapter 9.19)
//
// - **Construction**: array(), emptyArray(), append(), prepend(), concatenate()
// - **Operators**: @>, <@, &&, ||, =, <>, <, >
// - **Manipulation**: removing(), replacing(), joined(), toJSON()
// - **Query**: arrayLength(), cardinality(), arrayPosition(), unnest()
//
// ## Dual API Pattern
//
// All array functions support two calling styles:
//
// **Namespace style:**
// ```swift
// PostgreSQL.Array.contains($0.tags, ["swift"])
// PostgreSQL.Array.append($0.tags, "new-tag")
// ```
//
// **Method style (fluent):**
// ```swift
// $0.tags.contains(["swift"])
// $0.tags.appending("new-tag")
// ```
//
// Both compile to identical SQL. Choose based on context and readability.

extension PostgreSQL {
  /// Namespace for PostgreSQL array functions
  ///
  /// This enum cannot be instantiated - it serves purely as a namespace.
  public enum Array {}
}
