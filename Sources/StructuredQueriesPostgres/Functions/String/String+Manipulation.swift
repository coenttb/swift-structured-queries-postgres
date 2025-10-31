import Foundation
import StructuredQueriesCore

// MARK: - String Manipulation Functions
//
// PostgreSQL Chapter 9.4: String Functions and Operators
// https://www.postgresql.org/docs/18/functions-string.html
//
// Functions for manipulating strings: replace(), translate(), overlay(), reverse(), repeat()

extension PostgreSQL.String {
  /// Replaces all occurrences of a substring with another substring
  ///
  /// PostgreSQL's `replace(string, from, to)` function.
  ///
  /// ```swift
  /// PostgreSQL.String.replace($0.name, "John", "Jane")
  /// // SELECT replace("users"."name", 'John', 'Jane') FROM "users"
  /// ```
  ///
  /// - Parameters:
  ///   - value: The string expression
  ///   - substring: The substring to find
  ///   - newSubstring: The replacement substring
  /// - Returns: The string with all occurrences replaced
  public static func replace(
    _ value: some QueryExpression<Swift.String>,
    _ substring: Swift.String,
    _ newSubstring: Swift.String
  ) -> some QueryExpression<Swift.String> {
    SQLQueryExpression(
      "replace(\(value.queryFragment), \(bind: substring), \(bind: newSubstring))",
      as: Swift.String.self
    )
  }

  /// Replaces occurrences of a substring with another substring (expression-based)
  ///
  /// PostgreSQL's `replace(string, from, to)` function.
  public static func replace(
    _ value: some QueryExpression<Swift.String>,
    _ other: some QueryExpression<Swift.String>,
    _ replacement: some QueryExpression<Swift.String>
  ) -> some QueryExpression<Swift.String> {
    QueryFunction("replace", value, other, replacement)
  }

  /// Replaces each character in the string that matches a character in the from set
  /// with the corresponding character in the to set
  ///
  /// PostgreSQL's `translate(string, from, to)` function.
  ///
  /// ```swift
  /// PostgreSQL.String.translate($0.phone, from: "()-", to: "")
  /// // SELECT translate("users"."phone", '()-', '') FROM "users"
  /// ```
  ///
  /// - Parameters:
  ///   - value: The string expression
  ///   - from: Characters to replace
  ///   - to: Replacement characters (positional)
  /// - Returns: The string with characters translated
  ///
  /// > Note: If `to` is shorter than `from`, characters in `from` with no corresponding
  /// > character in `to` are deleted from the result.
  public static func translate(
    _ value: some QueryExpression<Swift.String>,
    from: Swift.String,
    to: Swift.String
  ) -> some QueryExpression<Swift.String> {
    SQLQueryExpression(
      "translate(\(value.queryFragment), \(bind: from), \(bind: to))",
      as: Swift.String.self
    )
  }

  /// Replaces a substring with another substring
  ///
  /// PostgreSQL's `overlay(string placing string from int [for int])` function.
  ///
  /// ```swift
  /// PostgreSQL.String.overlay($0.email, placing: "***", from: 5, for: 3)
  /// // SELECT overlay("users"."email" placing '***' from 5 for 3) FROM "users"
  /// ```
  ///
  /// - Parameters:
  ///   - value: The string expression
  ///   - newSubstring: The string to insert
  ///   - position: The starting position (1-indexed)
  ///   - length: Number of characters to replace (optional, defaults to length of newSubstring)
  /// - Returns: The string with the specified portion replaced
  public static func overlay(
    _ value: some QueryExpression<Swift.String>,
    placing newSubstring: Swift.String,
    from position: Int,
    for length: Int? = nil
  ) -> some QueryExpression<Swift.String> {
    if let length {
      return SQLQueryExpression(
        "overlay(\(value.queryFragment) placing \(bind: newSubstring) from \(position) for \(length))",
        as: Swift.String.self
      )
    } else {
      return SQLQueryExpression(
        "overlay(\(value.queryFragment) placing \(bind: newSubstring) from \(position))",
        as: Swift.String.self
      )
    }
  }

  /// Reverses the order of characters in a string
  ///
  /// PostgreSQL's `reverse(string)` function.
  ///
  /// ```swift
  /// PostgreSQL.String.reverse($0.name)
  /// // SELECT reverse("users"."name") FROM "users"
  /// ```
  ///
  /// - Parameter value: The string expression
  /// - Returns: The string with characters in reverse order
  public static func reverse(_ value: some QueryExpression<Swift.String>) -> some QueryExpression<
    Swift.String
  > {
    SQLQueryExpression(
      "reverse(\(value.queryFragment))",
      as: Swift.String.self
    )
  }

  /// Repeats the string a specified number of times
  ///
  /// PostgreSQL's `repeat(string, n)` function.
  ///
  /// ```swift
  /// PostgreSQL.String.repeat($0.separator, 3)
  /// // SELECT repeat("users"."separator", 3) FROM "users"
  /// ```
  ///
  /// - Parameters:
  ///   - value: The string expression
  ///   - times: Number of times to repeat the string
  /// - Returns: The string repeated n times
  public static func `repeat`(
    _ value: some QueryExpression<Swift.String>,
    _ times: Int
  ) -> some QueryExpression<Swift.String> {
    SQLQueryExpression(
      "repeat(\(value.queryFragment), \(times))",
      as: Swift.String.self
    )
  }
}

// MARK: - QueryExpression Extension (Fluent API)

extension QueryExpression where QueryValue == Swift.String {
  /// Replaces all occurrences of a substring with another substring
  ///
  /// PostgreSQL's `replace(string, from, to)` function.
  ///
  /// ```swift
  /// User.select { $0.name.replacing("John", with: "Jane") }
  /// // SELECT replace("users"."name", 'John', 'Jane') FROM "users"
  /// ```
  ///
  /// - Parameters:
  ///   - substring: The substring to find
  ///   - newSubstring: The replacement substring
  /// - Returns: The string with all occurrences replaced
  public func replacing(_ substring: Swift.String, with newSubstring: Swift.String)
    -> some QueryExpression<Swift.String>
  {
    PostgreSQL.String.replace(self, substring, newSubstring)
  }

  /// Replaces occurrences of a substring with another substring (expression-based)
  ///
  /// PostgreSQL's `replace()` function.
  ///
  /// ```swift
  /// User.select { $0.name.replace($0.oldText, $0.newText) }
  /// // SELECT replace("users"."name", "users"."oldText", "users"."newText") FROM "users"
  /// ```
  ///
  /// - Parameters:
  ///   - other: The substring to be replaced.
  ///   - replacement: The replacement string.
  /// - Returns: An expression of the `replace` function wrapping the given string, a substring to
  ///   replace, and the replacement.
  public func replace(
    _ other: some QueryExpression<QueryValue>,
    _ replacement: some QueryExpression<QueryValue>
  ) -> some QueryExpression<QueryValue> {
    PostgreSQL.String.replace(self, other, replacement)
  }

  /// Replaces each character in the string that matches a character in the from set
  /// with the corresponding character in the to set
  ///
  /// PostgreSQL's `translate(string, from, to)` function.
  ///
  /// ```swift
  /// User.select { $0.phone.translate(from: "()-", to: "") }
  /// // SELECT translate("users"."phone", '()-', '') FROM "users"
  /// ```
  ///
  /// - Parameters:
  ///   - from: Characters to replace
  ///   - to: Replacement characters (positional)
  /// - Returns: The string with characters translated
  ///
  /// > Note: If `to` is shorter than `from`, characters in `from` with no corresponding
  /// > character in `to` are deleted from the result.
  public func translate(from: Swift.String, to: Swift.String) -> some QueryExpression<Swift.String>
  {
    PostgreSQL.String.translate(self, from: from, to: to)
  }

  /// Replaces a substring with another substring
  ///
  /// PostgreSQL's `overlay(string placing string from int [for int])` function.
  ///
  /// ```swift
  /// User.select { $0.email.overlay(placing: "***", from: 5, for: 3) }
  /// // SELECT overlay("users"."email" placing '***' from 5 for 3) FROM "users"
  /// ```
  ///
  /// - Parameters:
  ///   - newSubstring: The string to insert
  ///   - position: The starting position (1-indexed)
  ///   - length: Number of characters to replace (optional, defaults to length of newSubstring)
  /// - Returns: The string with the specified portion replaced
  public func overlay(
    placing newSubstring: Swift.String,
    from position: Int,
    for length: Int? = nil
  ) -> some QueryExpression<Swift.String> {
    PostgreSQL.String.overlay(self, placing: newSubstring, from: position, for: length)
  }

  /// Reverses the order of characters in a string
  ///
  /// PostgreSQL's `reverse(string)` function.
  ///
  /// ```swift
  /// User.select { $0.name.reversed() }
  /// // SELECT reverse("users"."name") FROM "users"
  /// ```
  ///
  /// - Returns: The string with characters in reverse order
  ///
  /// > Note: The `@_disfavoredOverload` attribute ensures Swift's stdlib `String.reversed()` is preferred
  /// > for regular Swift strings, while this method is available for QueryExpressions.
  @_disfavoredOverload
  public func reversed() -> some QueryExpression<Swift.String> {
    PostgreSQL.String.reverse(self)
  }

  /// Repeats the string a specified number of times
  ///
  /// PostgreSQL's `repeat(string, n)` function.
  ///
  /// ```swift
  /// User.select { $0.separator.repeated(3) }
  /// // SELECT repeat("users"."separator", 3) FROM "users"
  /// ```
  ///
  /// - Parameter times: Number of times to repeat the string
  /// - Returns: The string repeated n times
  public func repeated(_ times: Int) -> some QueryExpression<Swift.String> {
    PostgreSQL.String.repeat(self, times)
  }
}
