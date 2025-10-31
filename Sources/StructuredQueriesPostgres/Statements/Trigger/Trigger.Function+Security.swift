import Foundation

extension String {
  /// Escapes single quotes for use in PostgreSQL string literals.
  ///
  /// PostgreSQL uses single quotes to delimit string literals. To include a literal
  /// single quote within a string, it must be escaped by doubling it ('').
  ///
  /// ## Example
  ///
  /// ```swift
  /// let message = "Can't delete"
  /// let escaped = message.escapedForPostgreSQL()
  /// // escaped = "Can''t delete"
  /// // SQL: RAISE EXCEPTION 'Can''t delete';
  /// ```
  ///
  /// This prevents SQL injection when embedding user-provided strings in PL/pgSQL code.
  ///
  /// - Returns: A string with all single quotes doubled for PostgreSQL safety.
  package func escapedForPostgreSQL() -> String {
    replacingOccurrences(of: "'", with: "''")
  }
}
