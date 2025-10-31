import Foundation
import StructuredQueriesCore

// MARK: - String Position Functions
//
// PostgreSQL Chapter 9.4: String Functions and Operators
// https://www.postgresql.org/docs/18/functions-string.html
//
// Functions for finding substring positions: POSITION, STRPOS

extension PostgreSQL.String {
  /// Finds the position of a substring
  ///
  /// PostgreSQL's `POSITION(substring IN string)` function.
  ///
  /// Returns the position (1-indexed) of the first occurrence of substring, or 0 if not found.
  ///
  /// ```swift
  /// PostgreSQL.String.position(of: "buy", in: $0.title)
  /// // SELECT POSITION('buy' IN "reminders"."title") FROM "reminders"
  /// ```
  ///
  /// - Parameters:
  ///   - substring: The substring to find
  ///   - value: The string expression to search in
  /// - Returns: The position (1-indexed) or 0 if not found
  ///
  /// > Note: SQLite equivalent: `INSTR`
  public static func position(
    of substring: Swift.String,
    in value: some QueryExpression<Swift.String>
  ) -> some QueryExpression<Int> {
    SQLQueryExpression(
      "POSITION(\(bind: substring) IN \(value.queryFragment))",
      as: Int.self
    )
  }

  /// Finds the position of a substring using STRPOS
  ///
  /// PostgreSQL's `STRPOS(string, substring)` function - alternative to POSITION.
  ///
  /// Returns the position (1-indexed) of the first occurrence of substring, or 0 if not found.
  ///
  /// ```swift
  /// PostgreSQL.String.strpos($0.title, "buy")
  /// // SELECT STRPOS("reminders"."title", 'buy') FROM "reminders"
  /// ```
  ///
  /// - Parameters:
  ///   - value: The string expression to search in
  ///   - substring: The substring to find
  /// - Returns: The position (1-indexed) or 0 if not found
  public static func strpos(
    _ value: some QueryExpression<Swift.String>,
    _ substring: Swift.String
  ) -> some QueryExpression<Int> {
    SQLQueryExpression(
      "STRPOS(\(value.queryFragment), \(bind: substring))",
      as: Int.self
    )
  }
}

// MARK: - QueryExpression Extension (Fluent API)

extension QueryExpression where QueryValue == Swift.String {
  /// Finds the position of a substring using POSITION
  ///
  /// PostgreSQL's `POSITION(substring IN string)` function.
  ///
  /// Returns the position (1-indexed) of the first occurrence of substring, or 0 if not found.
  ///
  /// ```swift
  /// Reminder.where { $0.title.position(of: "buy") > 0 }
  /// // SELECT … FROM "reminders" WHERE POSITION('buy' IN "reminders"."title") > 0
  /// ```
  ///
  /// - Parameter substring: The substring to find
  /// - Returns: The position (1-indexed) or 0 if not found
  ///
  /// > Note: SQLite equivalent: `INSTR`
  public func position(of substring: Swift.String) -> some QueryExpression<Int> {
    PostgreSQL.String.position(of: substring, in: self)
  }

  /// Finds the position of a substring using STRPOS
  ///
  /// PostgreSQL's `STRPOS(string, substring)` function - alternative to POSITION.
  ///
  /// Returns the position (1-indexed) of the first occurrence of substring, or 0 if not found.
  ///
  /// ```swift
  /// Reminder.where { $0.title.strpos("buy") > 0 }
  /// // SELECT … FROM "reminders" WHERE STRPOS("reminders"."title", 'buy') > 0
  /// ```
  ///
  /// - Parameter substring: The substring to find
  /// - Returns: The position (1-indexed) or 0 if not found
  public func strpos(_ substring: Swift.String) -> some QueryExpression<Int> {
    PostgreSQL.String.strpos(self, substring)
  }
}
