import Foundation
import StructuredQueriesCore

// MARK: - PostgreSQL Set Returning Functions
//
// PostgreSQL Chapter 9.26: Set Returning Functions
// https://www.postgresql.org/docs/18/functions-srf.html
//
// Functions that generate sets of rows, useful for generating test data, sequences, and more.

// MARK: - GENERATE_SERIES

/// Generates a series of integer values from start to stop (inclusive)
///
/// PostgreSQL's `generate_series(start, stop)` function.
///
/// ```swift
/// // Used in FROM clause or lateral joins
/// let series = generateSeries(1, 10)
/// // SELECT * FROM generate_series(1, 10)
/// ```
///
/// - Parameters:
///   - start: Starting value
///   - stop: Ending value (inclusive)
/// - Returns: A set of integer values
///
/// > Note: This is a set-returning function, typically used in FROM clauses.
public func generateSeries(_ start: Int, _ stop: Int) -> SQLQueryExpression<Int> {
  SQLQueryExpression(
    "generate_series(\(start), \(stop))",
    as: Int.self
  )
}

/// Generates a series of integer values from start to stop with a step
///
/// PostgreSQL's `generate_series(start, stop, step)` function.
///
/// ```swift
/// let series = generateSeries(0, 100, step: 10)
/// // SELECT * FROM generate_series(0, 100, 10)
/// // Result: 0, 10, 20, 30, ..., 100
/// ```
///
/// - Parameters:
///   - start: Starting value
///   - stop: Ending value (inclusive)
///   - step: Step value (can be negative for descending series)
/// - Returns: A set of integer values
public func generateSeries(_ start: Int, _ stop: Int, step: Int) -> SQLQueryExpression<Int> {
  SQLQueryExpression(
    "generate_series(\(start), \(stop), \(step))",
    as: Int.self
  )
}

/// Generates a series of timestamp values from start to stop with a step interval
///
/// PostgreSQL's `generate_series(start timestamp, stop timestamp, step interval)` function.
///
/// ```swift
/// let series = generateSeries(
///     Date(timeIntervalSince1970: 0),
///     Date(),
///     interval: "1 day"
/// )
/// // SELECT * FROM generate_series('2024-01-01', '2024-01-31', '1 day'::interval)
/// ```
///
/// - Parameters:
///   - start: Starting timestamp
///   - stop: Ending timestamp
///   - interval: Step interval as PostgreSQL interval string (e.g., "1 day", "1 hour", "1 month")
/// - Returns: A set of timestamp values
///
/// Common intervals:
/// - `"1 second"` - One second
/// - `"1 minute"` - One minute
/// - `"1 hour"` - One hour
/// - `"1 day"` - One day
/// - `"1 week"` - One week
/// - `"1 month"` - One month
/// - `"1 year"` - One year
public func generateSeriesTimestamp(_ start: Date, _ stop: Date, interval: String)
  -> SQLQueryExpression<Date>
{
  SQLQueryExpression(
    "generate_series(\(bind: start), \(bind: stop), '\(raw: interval)'::interval)",
    as: Date.self
  )
}

// MARK: - GENERATE_SUBSCRIPTS

/// Generates a series of subscripts (indices) for an array dimension
///
/// PostgreSQL's `generate_subscripts(array, dim)` function.
///
/// ```swift
/// // Generate indices for an array column
/// let indices = generateSubscripts($0.tags, dimension: 1)
/// // SELECT generate_subscripts("posts"."tags", 1) FROM "posts"
/// ```
///
/// - Parameters:
///   - array: Array expression
///   - dimension: Array dimension (1 for 1D arrays)
/// - Returns: A set of integer indices
///
/// > Note: Useful for iterating over array elements in queries
public func generateSubscripts<Element>(
  _ array: some QueryExpression<[Element]>,
  dimension: Int = 1
) -> SQLQueryExpression<Int> where Element: QueryBindable {
  SQLQueryExpression(
    "generate_subscripts(\(array.queryFragment), \(dimension))",
    as: Int.self
  )
}

/// Generates a series of subscripts for an array dimension in reverse order
///
/// PostgreSQL's `generate_subscripts(array, dim, reverse)` function.
///
/// ```swift
/// let indices = generateSubscripts($0.tags, dimension: 1, reverse: true)
/// // SELECT generate_subscripts("posts"."tags", 1, true) FROM "posts"
/// ```
public func generateSubscripts<Element>(
  _ array: some QueryExpression<[Element]>,
  dimension: Int = 1,
  reverse: Bool
) -> SQLQueryExpression<Int> where Element: QueryBindable {
  SQLQueryExpression(
    "generate_subscripts(\(array.queryFragment), \(dimension), \(reverse))",
    as: Int.self
  )
}

// MARK: - JSON Set Returning Functions

/// Expands a JSON array into a set of JSON values
///
/// PostgreSQL's `json_array_elements(json)` function.
///
/// ```swift
/// // Expand JSON array elements
/// let elements = jsonArrayElements($0.jsonData)
/// // SELECT json_array_elements("data"."jsonData") FROM "data"
/// ```
///
/// - Parameter json: JSON expression containing an array
/// - Returns: A set of JSON values
///
/// > Note: This is a set-returning function for use in FROM clauses
public func jsonArrayElements(_ json: some QueryExpression<Data>) -> SQLQueryExpression<Data> {
  SQLQueryExpression(
    "json_array_elements(\(json.queryFragment))",
    as: Data.self
  )
}

/// Expands a JSON array into a set of text values
///
/// PostgreSQL's `json_array_elements_text(json)` function.
///
/// ```swift
/// let elements = jsonArrayElementsText($0.jsonArray)
/// // SELECT json_array_elements_text("data"."jsonArray") FROM "data"
/// ```
///
/// - Parameter json: JSON expression containing an array
/// - Returns: A set of text values
public func jsonArrayElementsText(_ json: some QueryExpression<Data>) -> SQLQueryExpression<String>
{
  SQLQueryExpression(
    "json_array_elements_text(\(json.queryFragment))",
    as: String.self
  )
}

/// Expands a JSONB array into a set of JSONB values
///
/// PostgreSQL's `jsonb_array_elements(jsonb)` function.
///
/// ```swift
/// let elements = jsonbArrayElements($0.jsonbData)
/// // SELECT jsonb_array_elements("data"."jsonbData") FROM "data"
/// ```
public func jsonbArrayElements(_ jsonb: some QueryExpression<Data>) -> SQLQueryExpression<Data> {
  SQLQueryExpression(
    "jsonb_array_elements(\(jsonb.queryFragment))",
    as: Data.self
  )
}

/// Expands a JSONB array into a set of text values
///
/// PostgreSQL's `jsonb_array_elements_text(jsonb)` function.
///
/// ```swift
/// let elements = jsonbArrayElementsText($0.jsonbArray)
/// // SELECT jsonb_array_elements_text("data"."jsonbArray") FROM "data"
/// ```
public func jsonbArrayElementsText(_ jsonb: some QueryExpression<Data>) -> SQLQueryExpression<
  String
> {
  SQLQueryExpression(
    "jsonb_array_elements_text(\(jsonb.queryFragment))",
    as: String.self
  )
}

// MARK: - REGEXP_MATCHES (Set Returning)

extension QueryExpression where QueryValue == String {
  /// Returns all captured substrings from a regular expression match
  ///
  /// PostgreSQL's `regexp_matches(text, pattern, flags)` set-returning function.
  ///
  /// ```swift
  /// Text.select { $0.content.regexpMatches("[0-9]+", flags: "g") }
  /// // SELECT regexp_matches("texts"."content", '[0-9]+', 'g') FROM "texts"
  /// ```
  ///
  /// - Parameters:
  ///   - pattern: Regular expression pattern
  ///   - flags: Optional flags ('g' for global, 'i' for case-insensitive, etc.)
  /// - Returns: A set of text arrays containing captured groups
  ///
  /// Common flags:
  /// - `"g"` - Global (return all matches, not just first)
  /// - `"i"` - Case-insensitive
  /// - `"m"` - Multi-line mode
  /// - `"n"` - Newline-sensitive
  ///
  /// > Note: Returns a set of rows, each containing an array of captured groups
  public func regexpMatches(_ pattern: String, flags: String = "g") -> some QueryExpression<
    [String]
  > {
    SQLQueryExpression(
      "regexp_matches(\(self.queryFragment), \(bind: pattern), \(bind: flags))",
      as: [String].self
    )
  }
}

// MARK: - REGEXP_SPLIT_TO_TABLE

extension QueryExpression where QueryValue == String {
  /// Splits a string using a regular expression pattern and returns rows
  ///
  /// PostgreSQL's `regexp_split_to_table(text, pattern)` function.
  ///
  /// ```swift
  /// Text.select { $0.csv.regexpSplitToTable(",\\s*") }
  /// // SELECT regexp_split_to_table("texts"."csv", ',\s*') FROM "texts"
  /// ```
  ///
  /// - Parameters:
  ///   - pattern: Regular expression pattern to split on
  ///   - flags: Optional flags ('i' for case-insensitive, etc.)
  /// - Returns: A set of text values
  ///
  /// > Note: This is a set-returning function that returns one row per split element
  public func regexpSplitToTable(_ pattern: String, flags: String? = nil) -> some QueryExpression<
    String
  > {
    if let flags {
      return SQLQueryExpression(
        "regexp_split_to_table(\(self.queryFragment), \(bind: pattern), \(bind: flags))",
        as: String.self
      )
    } else {
      return SQLQueryExpression(
        "regexp_split_to_table(\(self.queryFragment), \(bind: pattern))",
        as: String.self
      )
    }
  }
}
