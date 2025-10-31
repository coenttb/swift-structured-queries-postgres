import Foundation
import StructuredQueriesCore

// MARK: - String Extraction Functions
//
// PostgreSQL Chapter 9.4: String Functions and Operators
// https://www.postgresql.org/docs/18/functions-string.html
//
// Functions for extracting parts of strings: substring(), substr(), left(), right(), split_part()

extension PostgreSQL.String {
  /// Extracts a substring using PostgreSQL's SUBSTRING syntax
  ///
  /// PostgreSQL's `SUBSTRING(string FROM start [FOR length])` function.
  ///
  /// ```swift
  /// PostgreSQL.String.substring($0.name, from: 1, for: 5)
  /// // SELECT SUBSTRING("users"."name" FROM 1 FOR 5) FROM "users"
  /// ```
  ///
  /// - Parameters:
  ///   - value: The string expression
  ///   - start: The starting position (1-indexed)
  ///   - length: The length of the substring (optional)
  /// - Returns: The extracted substring
  public static func substring(
    _ value: some QueryExpression<Swift.String>,
    from start: Int,
    for length: Int? = nil
  ) -> some QueryExpression<Swift.String> {
    if let length {
      return SQLQueryExpression(
        "SUBSTRING(\(value.queryFragment) FROM \(start) FOR \(length))",
        as: Swift.String.self
      )
    } else {
      return SQLQueryExpression(
        "SUBSTRING(\(value.queryFragment) FROM \(start))",
        as: Swift.String.self
      )
    }
  }

  /// Extracts a substring starting at the specified position
  ///
  /// PostgreSQL's `substr(string, start [, length])` function.
  ///
  /// ```swift
  /// PostgreSQL.String.substr($0.name, 1, 5)
  /// // SELECT substr("users"."name", 1, 5) FROM "users"
  /// ```
  ///
  /// - Parameters:
  ///   - value: The string expression
  ///   - offset: The starting position (1-indexed)
  ///   - length: The length of the substring (optional)
  /// - Returns: The extracted substring
  ///
  /// > Note: `substr` is an alias for `substring` with different syntax
  public static func substr(
    _ value: some QueryExpression<Swift.String>,
    _ offset: Int,
    _ length: Int? = nil
  ) -> some QueryExpression<Swift.String> {
    if let length {
      return QueryFunction("substr", value, offset, length)
    } else {
      return QueryFunction("substr", value, offset)
    }
  }

  /// Extracts a substring using an expression for the offset
  ///
  /// PostgreSQL's `substr(string, start [, length])` function.
  public static func substr(
    _ value: some QueryExpression<Swift.String>,
    _ offset: some QueryExpression<Int>,
    _ length: (some QueryExpression<Int>)? = Int?.none
  ) -> some QueryExpression<Swift.String> {
    if let length {
      return QueryFunction("substr", value, offset, length)
    } else {
      return QueryFunction("substr", value, offset)
    }
  }

  /// Returns the first n characters from a string (left part)
  ///
  /// PostgreSQL's `left(string, n)` function.
  ///
  /// ```swift
  /// PostgreSQL.String.left($0.name, 5)
  /// // SELECT left("users"."name", 5) FROM "users"
  /// ```
  ///
  /// - Parameters:
  ///   - value: The string expression
  ///   - n: Number of characters to extract from the left
  /// - Returns: The leftmost n characters
  public static func left(
    _ value: some QueryExpression<Swift.String>,
    _ n: Int
  ) -> some QueryExpression<Swift.String> {
    SQLQueryExpression(
      "left(\(value.queryFragment), \(n))",
      as: Swift.String.self
    )
  }

  /// Returns the last n characters from a string (right part)
  ///
  /// PostgreSQL's `right(string, n)` function.
  ///
  /// ```swift
  /// PostgreSQL.String.right($0.phone, 4)
  /// // SELECT right("users"."phone", 4) FROM "users"
  /// ```
  ///
  /// - Parameters:
  ///   - value: The string expression
  ///   - n: Number of characters to extract from the right
  /// - Returns: The rightmost n characters
  public static func right(
    _ value: some QueryExpression<Swift.String>,
    _ n: Int
  ) -> some QueryExpression<Swift.String> {
    SQLQueryExpression(
      "right(\(value.queryFragment), \(n))",
      as: Swift.String.self
    )
  }

  /// Splits the string on delimiter and returns the nth field (1-indexed)
  ///
  /// PostgreSQL's `split_part(string, delimiter, n)` function.
  ///
  /// ```swift
  /// PostgreSQL.String.splitPart($0.fullPath, delimiter: "/", field: 3)
  /// // SELECT split_part("users"."fullPath", '/', 3) FROM "users"
  /// // "/home/user/file.txt" -> "file.txt" (field 3)
  /// ```
  ///
  /// - Parameters:
  ///   - value: The string expression
  ///   - delimiter: The delimiter to split on
  ///   - field: The field number to return (1-indexed)
  /// - Returns: The nth field from the split string
  ///
  /// > Note: Returns empty string if n is out of range. Fields are 1-indexed.
  public static func splitPart(
    _ value: some QueryExpression<Swift.String>,
    delimiter: Swift.String,
    field: Int
  ) -> some QueryExpression<Swift.String> {
    SQLQueryExpression(
      "split_part(\(value.queryFragment), \(bind: delimiter), \(field))",
      as: Swift.String.self
    )
  }
}

// MARK: - QueryExpression Extension (Fluent API)

extension QueryExpression where QueryValue == Swift.String {
  /// Extracts a substring using PostgreSQL's SUBSTRING syntax
  ///
  /// PostgreSQL's `SUBSTRING(string FROM start [FOR length])` function.
  ///
  /// ```swift
  /// User.select { $0.name.substring(from: 1, for: 5) }
  /// // SELECT SUBSTRING("users"."name" FROM 1 FOR 5) FROM "users"
  ///
  /// User.select { $0.name.substring(from: 10) }
  /// // SELECT SUBSTRING("users"."name" FROM 10) FROM "users"
  /// ```
  ///
  /// - Parameters:
  ///   - start: The starting position (1-indexed)
  ///   - length: The length of the substring (optional)
  /// - Returns: The extracted substring
  public func substring(from start: Int, for length: Int? = nil) -> some QueryExpression<
    Swift.String
  > {
    PostgreSQL.String.substring(self, from: start, for: length)
  }

  /// Extracts a substring starting at the specified position
  ///
  /// PostgreSQL's `substr(string, start [, length])` function.
  ///
  /// ```swift
  /// User.select { $0.name.substr(1, 5) }
  /// // SELECT substr("users"."name", 1, 5) FROM "users"
  ///
  /// User.select { $0.name.substr(10) }
  /// // SELECT substr("users"."name", 10) FROM "users"
  /// ```
  ///
  /// - Parameters:
  ///   - offset: The starting position (1-indexed)
  ///   - length: The length of the substring (optional)
  /// - Returns: An expression of the `substr` function wrapping the given string, an offset, and
  ///   length.
  ///
  /// > Note: PostgreSQL also has `substring()` with different syntax. See `substring(from:for:)`
  public func substr(
    _ offset: some QueryExpression<Int>,
    _ length: (some QueryExpression<Int>)? = Int?.none
  ) -> some QueryExpression<QueryValue> {
    PostgreSQL.String.substr(self, offset, length)
  }

  /// Returns the first n characters from a string (left part)
  ///
  /// PostgreSQL's `left(string, n)` function.
  ///
  /// ```swift
  /// User.select { $0.name.left(5) }
  /// // SELECT left("users"."name", 5) FROM "users"
  /// ```
  ///
  /// - Parameter n: Number of characters to extract from the left
  /// - Returns: The leftmost n characters
  public func left(_ n: Int) -> some QueryExpression<Swift.String> {
    PostgreSQL.String.left(self, n)
  }

  /// Returns the last n characters from a string (right part)
  ///
  /// PostgreSQL's `right(string, n)` function.
  ///
  /// ```swift
  /// User.select { $0.phone.right(4) }
  /// // SELECT right("users"."phone", 4) FROM "users"
  /// ```
  ///
  /// - Parameter n: Number of characters to extract from the right
  /// - Returns: The rightmost n characters
  public func right(_ n: Int) -> some QueryExpression<Swift.String> {
    PostgreSQL.String.right(self, n)
  }

  /// Splits the string on delimiter and returns the nth field (1-indexed)
  ///
  /// PostgreSQL's `split_part(string, delimiter, n)` function.
  ///
  /// ```swift
  /// User.select { $0.fullPath.splitPart(delimiter: "/", field: 3) }
  /// // SELECT split_part("users"."fullPath", '/', 3) FROM "users"
  /// // "/home/user/file.txt" -> "file.txt" (field 3)
  /// ```
  ///
  /// - Parameters:
  ///   - delimiter: The delimiter to split on
  ///   - field: The field number to return (1-indexed)
  /// - Returns: The nth field from the split string
  ///
  /// > Note: Returns empty string if n is out of range. Fields are 1-indexed.
  public func splitPart(delimiter: Swift.String, field: Int) -> some QueryExpression<Swift.String> {
    PostgreSQL.String.splitPart(self, delimiter: delimiter, field: field)
  }
}
