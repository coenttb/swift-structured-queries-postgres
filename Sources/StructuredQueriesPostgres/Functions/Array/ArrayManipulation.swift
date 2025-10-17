import Foundation
import StructuredQueriesCore

// MARK: - PostgreSQL Array Manipulation Functions
//
// PostgreSQL Chapter 9.19: Array Functions and Operators
// https://www.postgresql.org/docs/18/functions-array.html
//
// Functions for modifying array contents.

// MARK: - Swifty Array Manipulation Methods

extension QueryExpression where QueryValue: Collection, QueryValue.Element: QueryBindable {
    /// Removes all occurrences of an element from an array
    ///
    /// PostgreSQL's `array_remove(anyarray, anyelement)` function.
    ///
    /// ```swift
    /// Post.select { $0.tags.removing("deprecated") }
    /// // SELECT array_remove("posts"."tags", 'deprecated') FROM "posts"
    /// ```
    ///
    /// - Parameter element: The element to remove
    /// - Returns: A new array with all occurrences of the element removed
    public func removing(_ element: QueryValue.Element) -> some QueryExpression<QueryValue> {
        SQLQueryExpression(
            "array_remove(\(self.queryFragment), \(bind: element))",
            as: QueryValue.self
        )
    }

    /// Replaces all occurrences of an element in an array with another element
    ///
    /// PostgreSQL's `array_replace(anyarray, anyelement, anyelement)` function.
    ///
    /// ```swift
    /// Post.select { $0.tags.replacing("old-tag", with: "new-tag") }
    /// // SELECT array_replace("posts"."tags", 'old-tag', 'new-tag') FROM "posts"
    /// ```
    ///
    /// - Parameters:
    ///   - element: The element to replace
    ///   - replacement: The replacement element
    /// - Returns: A new array with all occurrences replaced
    public func replacing(_ element: QueryValue.Element, with replacement: QueryValue.Element)
        -> some QueryExpression<QueryValue>
    {
        SQLQueryExpression(
            "array_replace(\(self.queryFragment), \(bind: element), \(bind: replacement))",
            as: QueryValue.self
        )
    }

    /// Converts an array to a string with a delimiter
    ///
    /// PostgreSQL's `array_to_string(anyarray, text)` function.
    ///
    /// ```swift
    /// Post.select { $0.tags.joined(separator: ", ") }
    /// // SELECT array_to_string("posts"."tags", ', ') FROM "posts"
    /// ```
    ///
    /// - Parameter separator: The string to use between array elements
    /// - Returns: A string with array elements joined by the separator
    @_disfavoredOverload
    public func joined(separator: String) -> some QueryExpression<String> {
        SQLQueryExpression(
            "array_to_string(\(self.queryFragment), \(bind: separator))",
            as: String.self
        )
    }

    /// Converts an array to a string with a separator and NULL replacement
    ///
    /// PostgreSQL's `array_to_string(anyarray, text, text)` function.
    ///
    /// ```swift
    /// Post.select { $0.tags.joined(separator: ", ", nullReplacement: "[none]") }
    /// // SELECT array_to_string("posts"."tags", ', ', '[none]') FROM "posts"
    /// ```
    ///
    /// - Parameters:
    ///   - separator: The string to use between array elements
    ///   - nullReplacement: The string to use for NULL values
    /// - Returns: A string with array elements joined by the separator
    @_disfavoredOverload
    public func joined(separator: String, nullReplacement: String) -> some QueryExpression<String> {
        SQLQueryExpression(
            "array_to_string(\(self.queryFragment), \(bind: separator), \(bind: nullReplacement))",
            as: String.self
        )
    }

    /// Returns a text representation of an array's dimensions
    ///
    /// PostgreSQL's `array_dims(anyarray)` function.
    ///
    /// ```swift
    /// Post.select { $0.tags.dimensions }
    /// // SELECT array_dims("posts"."tags") FROM "posts"
    /// // Result: "[1:5]" for an array with 5 elements
    /// ```
    ///
    /// - Returns: A text representation of the array dimensions
    public var dimensions: some QueryExpression<String?> {
        SQLQueryExpression(
            "array_dims(\(self.queryFragment))",
            as: String?.self
        )
    }

    /// Converts an array to JSON
    ///
    /// PostgreSQL's `array_to_json(anyarray)` function.
    ///
    /// ```swift
    /// Post.select { $0.tags.toJSON() }
    /// // SELECT array_to_json("posts"."tags") FROM "posts"
    /// ```
    ///
    /// - Returns: A JSON representation of the array
    public func toJSON() -> some QueryExpression<Data> {
        SQLQueryExpression(
            "array_to_json(\(self.queryFragment))",
            as: Data.self
        )
    }

    /// Converts an array to pretty-printed JSON
    ///
    /// PostgreSQL's `array_to_json(anyarray, boolean)` function.
    ///
    /// ```swift
    /// Post.select { $0.tags.toJSON(prettyPrint: true) }
    /// // SELECT array_to_json("posts"."tags", true) FROM "posts"
    /// ```
    ///
    /// - Parameter prettyPrint: Whether to pretty-print the JSON
    /// - Returns: A JSON representation of the array
    public func toJSON(prettyPrint: Bool) -> some QueryExpression<Data> {
        SQLQueryExpression(
            "array_to_json(\(self.queryFragment), \(prettyPrint))",
            as: Data.self
        )
    }
}

// MARK: - String to Array Conversion

extension QueryExpression where QueryValue == String {
    /// Converts this string to an array by splitting on a delimiter
    ///
    /// PostgreSQL's `string_to_array(text, text)` function.
    ///
    /// ```swift
    /// User.select { $0.commaSeparatedTags.split(separator: ",") }
    /// // SELECT string_to_array("users"."commaSeparatedTags", ',') FROM "users"
    /// ```
    ///
    /// - Parameter separator: The delimiter to split on
    /// - Returns: An array of strings
    public func split(separator: String) -> some QueryExpression<[String]> {
        SQLQueryExpression(
            "string_to_array(\(self.queryFragment), \(bind: separator))",
            as: [String].self
        )
    }

    /// Converts this string to an array by splitting on a delimiter, treating NULL strings specially
    ///
    /// PostgreSQL's `string_to_array(text, text, text)` function.
    ///
    /// ```swift
    /// User.select { $0.tags.split(separator: ",", nullString: "NULL") }
    /// // SELECT string_to_array("users"."tags", ',', 'NULL') FROM "users"
    /// ```
    ///
    /// - Parameters:
    ///   - separator: The delimiter to split on
    ///   - nullString: String value that should be converted to NULL in the result
    /// - Returns: An array of strings with NULL values where nullString was found
    public func split(separator: String, nullString: String) -> some QueryExpression<[String]> {
        SQLQueryExpression(
            "string_to_array(\(self.queryFragment), \(bind: separator), \(bind: nullString))",
            as: [String].self
        )
    }
}

// MARK: - Free Functions

/// Converts a string to an array by splitting on a delimiter
///
/// PostgreSQL's `string_to_array(text, text)` function.
///
/// ```swift
/// User.select { split($0.commaSeparatedTags, separator: ",") }
/// // SELECT string_to_array("users"."commaSeparatedTags", ',') FROM "users"
/// ```
public func split(
    _ string: some QueryExpression<String>,
    separator: String
) -> some QueryExpression<[String]> {
    SQLQueryExpression(
        "string_to_array(\(string.queryFragment), \(bind: separator))",
        as: [String].self
    )
}

/// Converts a string to an array by splitting on a delimiter, treating NULL strings specially
///
/// PostgreSQL's `string_to_array(text, text, text)` function.
///
/// ```swift
/// User.select { split($0.tags, separator: ",", nullString: "NULL") }
/// // SELECT string_to_array("users"."tags", ',', 'NULL') FROM "users"
/// ```
public func split(
    _ string: some QueryExpression<String>,
    separator: String,
    nullString: String
) -> some QueryExpression<[String]> {
    SQLQueryExpression(
        "string_to_array(\(string.queryFragment), \(bind: separator), \(bind: nullString))",
        as: [String].self
    )
}

// MARK: - Array Filling and Generation

/// Creates an array filled with a value
///
/// PostgreSQL's `array_fill(anyelement, int[])` function.
///
/// ```swift
/// let filledArray = fill(value: 0, count: 5)
/// // SELECT array_fill(0, ARRAY[5])
/// // Result: [0, 0, 0, 0, 0]
/// ```
///
/// - Parameters:
///   - value: The value to fill the array with
///   - count: Number of elements
/// - Returns: An array filled with the specified value
public func fill<Element>(
    value: Element,
    count: Int
) -> some QueryExpression<[Element]> where Element: QueryBindable {
    return SQLQueryExpression(
        "array_fill(\(bind: value), ARRAY[\(count)])",
        as: [Element].self
    )
}

/// Creates an array filled with a value, with custom dimensions
///
/// PostgreSQL's `array_fill(anyelement, int[])` function.
///
/// ```swift
/// let filledArray = fill(value: 0, lengths: [5, 3])
/// // SELECT array_fill(0, ARRAY[5, 3])
/// ```
///
/// - Parameters:
///   - value: The value to fill the array with
///   - lengths: Array dimensions
/// - Returns: An array filled with the specified value
public func fill<Element>(
    value: Element,
    lengths: [Int]
) -> some QueryExpression<[Element]> where Element: QueryBindable {
    let lengthsList = lengths.map(String.init).joined(separator: ", ")
    return SQLQueryExpression(
        "array_fill(\(bind: value), ARRAY[\(raw: lengthsList)])",
        as: [Element].self
    )
}

/// Creates an array filled with a value, with lower bounds
///
/// PostgreSQL's `array_fill(anyelement, int[], int[])` function.
///
/// ```swift
/// let filledArray = fill(value: 0, lengths: [5], lowerBounds: [1])
/// // SELECT array_fill(0, ARRAY[5], ARRAY[1])
/// ```
///
/// - Parameters:
///   - value: The value to fill the array with
///   - lengths: Array dimensions
///   - lowerBounds: Lower bound for each dimension (typically [1])
/// - Returns: An array filled with the specified value
public func fill<Element>(
    value: Element,
    lengths: [Int],
    lowerBounds: [Int]
) -> some QueryExpression<[Element]> where Element: QueryBindable {
    // Disambiguate: use Swift standard library's joined(), not our QueryExpression extension
    let lengthsList: String = lengths.map(String.init).joined(separator: ", ")
    let boundsList: String = lowerBounds.map(String.init).joined(separator: ", ")
    return SQLQueryExpression(
        "array_fill(\(bind: value), ARRAY[\(raw: lengthsList)], ARRAY[\(raw: boundsList)])",
        as: [Element].self
    )
}
