import Foundation
import StructuredQueriesCore

// MARK: - JSONB.Creation (Table 9.49)

extension JSONB {
  /// JSON Creation Functions from PostgreSQL Table 9.49
  ///
  /// Provides type-safe wrappers for PostgreSQL's JSON/JSONB creation functions:
  /// - `to_json()` / `to_jsonb()` - Convert SQL values to JSON
  /// - `array_to_json()` - Convert arrays to JSON
  /// - `row_to_json()` - Convert table rows to JSON objects
  /// - `json_object()` - Build JSON objects from key-value arrays
  /// - `jsonb_build_array()` - Build JSONB arrays from values
  ///
  /// See [PostgreSQL Documentation - Table 9.49](https://www.postgresql.org/docs/current/functions-json.html)
  public enum Creation {}
}

// MARK: - JSONB.Creation Static Methods

extension JSONB.Creation {
  /// Convert PostgreSQL array to JSON array
  ///
  /// PostgreSQL's `array_to_json()` function converts a PostgreSQL array into a JSON array.
  ///
  /// ```swift
  /// User.select { JSONB.Conversion.arrayToJson($0.tags) }
  /// // SELECT array_to_json("users"."tags") FROM "users"
  /// ```
  ///
  /// **Example:**
  /// ```swift
  /// // PostgreSQL array: {"swift", "postgres", "vapor"}
  /// // JSON result: ["swift", "postgres", "vapor"]
  /// ```
  ///
  /// - Parameter array: Query expression representing a PostgreSQL array
  /// - Returns: JSON array representation
  public static func arrayToJson<T: QueryExpression>(_ array: T) -> some QueryExpression<Data> {
    QueryFunction("array_to_json", array)
  }

  /// Convert table row to JSON
  ///
  /// PostgreSQL's `row_to_json()` function converts a table row into a JSON object.
  ///
  /// **PostgreSQL Documentation**: Table 9.49
  ///
  /// ```swift
  /// User.select { _ in JSONB.Creation.rowToJson(User.self) }
  /// // SELECT row_to_json("users".*) FROM "users"
  /// ```
  ///
  /// **Example output:**
  /// ```json
  /// {
  ///   "id": 1,
  ///   "name": "Alice",
  ///   "email": "alice@example.com",
  ///   "created_at": "2024-01-15T10:30:00Z"
  /// }
  /// ```
  ///
  /// **Use cases:**
  /// - Exporting entire rows as JSON
  /// - Building API responses
  /// - Creating JSON exports
  ///
  /// - Parameter table: The table type to convert
  /// - Returns: JSON object representing the row
  public static func rowToJson<T: Table>(_ table: T.Type) -> some QueryExpression<Data> {
    var fragment: QueryFragment = "row_to_json("
    if let schemaName = T.schemaName {
      fragment.append("\(quote: schemaName).")
    }
    fragment.append("\(quote: T.tableName).*)")
    return SQLQueryExpression(fragment, as: Data.self)
  }

  /// Create JSON object from text arrays
  ///
  /// PostgreSQL's `json_object()` function creates a JSON object from two text arrays:
  /// one containing keys and another containing values.
  ///
  /// **PostgreSQL Documentation**: Table 9.49
  ///
  /// ```swift
  /// JSONB.Creation.object(
  ///     keys: ["name", "email", "age"],
  ///     values: ["Alice", "alice@example.com", "25"]
  /// )
  /// // json_object('{name,email,age}', '{Alice,alice@example.com,25}')
  /// ```
  ///
  /// **Example output:**
  /// ```json
  /// {
  ///   "name": "Alice",
  ///   "email": "alice@example.com",
  ///   "age": "25"
  /// }
  /// ```
  ///
  /// **Note:** Keys and values arrays must have the same length, or PostgreSQL will error.
  ///
  /// - Parameters:
  ///   - keys: Array of key names
  ///   - values: Array of corresponding values (must be same length as keys)
  /// - Returns: JSON object with the specified key-value pairs
  public static func object(keys: [String], values: [String]) -> some QueryExpression<Data> {
    JSONObjectFromArrays(keys: keys, values: values)
  }

  /// Build JSONB array from values
  ///
  /// PostgreSQL's `jsonb_build_array()` function constructs a JSONB array from the given values.
  ///
  /// **PostgreSQL Documentation**: Table 9.49
  ///
  /// ```swift
  /// User.select { JSONB.Creation.buildArray($0.name, $0.email, $0.age) }
  /// // SELECT jsonb_build_array("name", "email", "age") FROM "users"
  /// ```
  ///
  /// **Example output:**
  /// ```json
  /// ["Alice", "alice@example.com", 25]
  /// ```
  ///
  /// **Use cases:**
  /// - Creating dynamic JSONB arrays in queries
  /// - Aggregating multiple columns into a single array
  /// - Building JSON responses
  ///
  /// - Parameter values: Variable number of query expressions to include in the array
  /// - Returns: JSONB array containing all values
  public static func buildArray(_ values: any QueryExpression...) -> some QueryExpression<Data> {
    JSONBuildArray(values: values, format: .jsonb)
  }

  /// Build JSON array from values (text format)
  ///
  /// PostgreSQL's `json_build_array()` function constructs a JSON array from the given values.
  ///
  /// **PostgreSQL Documentation**: Table 9.49
  ///
  /// ```swift
  /// User.select { JSONB.Creation.buildJsonArray($0.name, $0.email) }
  /// // SELECT json_build_array("name", "email") FROM "users"
  /// ```
  ///
  /// **Note**: For most use cases, prefer `buildArray()` (jsonb variant) for better performance.
  ///
  /// - Parameter values: Variable number of query expressions to include in the array
  /// - Returns: JSON array containing all values (text format)
  public static func buildJsonArray(_ values: any QueryExpression...) -> some QueryExpression<
    Data
  > {
    JSONBuildArray(values: values, format: .json)
  }
}

// MARK: - JSONB.Creation Implementation Types

extension JSONB.Creation {
  fileprivate struct JSONBuildArray: QueryExpression {
    typealias QueryValue = Data

    let values: [any QueryExpression]
    let format: JSONFormat

    enum JSONFormat: String {
      case json
      case jsonb
    }

    var queryFragment: QueryFragment {
      var fragment: QueryFragment = "\(raw: format.rawValue)_build_array("

      for (index, value) in values.enumerated() {
        if index > 0 {
          fragment.append(", ")
        }
        fragment.append(value.queryFragment)
      }

      fragment.append(")")
      return fragment
    }
  }

  fileprivate struct JSONObjectFromArrays: QueryExpression {
    typealias QueryValue = Data

    let keys: [String]
    let values: [String]

    var queryFragment: QueryFragment {
      let keysArray = "'{" + keys.joined(separator: ",") + "}'"
      let valuesArray = "'{" + values.joined(separator: ",") + "}'"
      return "json_object(\(raw: keysArray), \(raw: valuesArray))"
    }
  }
}

// MARK: - QueryExpression Conversion Extensions

extension QueryExpression {
  /// Convert SQL value to JSONB
  ///
  /// PostgreSQL's `to_jsonb()` function converts any SQL value into its JSONB representation.
  ///
  /// ```swift
  /// User.select { $0.age.toJsonb() }
  /// // SELECT to_jsonb("users"."age") FROM "users"
  /// ```
  ///
  /// **Common use cases:**
  /// - Converting scalar values to JSONB
  /// - Converting arrays to JSONB arrays
  /// - Converting composite types to JSONB objects
  ///
  /// **Example:**
  /// ```swift
  /// User.select { ($0.name, $0.email.toJsonb()) }
  /// // Returns JSONB representation of email
  /// ```
  ///
  /// - Returns: JSONB representation of the value
  public func toJsonb() -> some QueryExpression<Data> {
    QueryFunction("to_jsonb", self)
  }

  /// Convert SQL value to JSON (text format)
  ///
  /// Similar to `toJsonb()` but returns JSON in text format instead of binary JSONB.
  ///
  /// **Note:** For most use cases, prefer `toJsonb()` as JSONB provides better
  /// performance and indexing capabilities.
  ///
  /// ```swift
  /// User.select { $0.age.toJson() }
  /// // SELECT to_json("users"."age") FROM "users"
  /// ```
  ///
  /// - Returns: JSON representation of the value (as text)
  public func toJson() -> some QueryExpression<Data> {
    QueryFunction("to_json", self)
  }
}
