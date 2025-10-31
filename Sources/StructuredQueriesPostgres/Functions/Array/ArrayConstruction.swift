import Foundation
import StructuredQueriesCore

// MARK: - PostgreSQL Array Construction Functions
//
// PostgreSQL Chapter 9.19: Array Functions and Operators
// https://www.postgresql.org/docs/18/functions-array.html
//
// Array construction and concatenation functions for building and modifying arrays.

// MARK: - Extension Methods (Swifty API)

extension QueryExpression where QueryValue: Collection, QueryValue.Element: QueryBindable {
  /// Appends an element to the end of an array
  ///
  /// PostgreSQL's `array_append(anyarray, anyelement)` function.
  ///
  /// ```swift
  /// Post.select { $0.tags.appending("swift") }
  /// // SELECT array_append("posts"."tags", 'swift') FROM "posts"
  /// ```
  ///
  /// - Parameter element: The element to append to the array
  /// - Returns: A new array with the element appended
  public func appending(_ element: QueryValue.Element) -> some QueryExpression<QueryValue> {
    SQLQueryExpression(
      "array_append(\(self.queryFragment), \(bind: element))",
      as: QueryValue.self
    )
  }

  /// Prepends an element to the beginning of an array
  ///
  /// PostgreSQL's `array_prepend(anyelement, anyarray)` function.
  ///
  /// ```swift
  /// Post.select { $0.tags.prepending("featured") }
  /// // SELECT array_prepend('featured', "posts"."tags") FROM "posts"
  /// ```
  ///
  /// - Parameter element: The element to prepend to the array
  /// - Returns: A new array with the element prepended
  public func prepending(_ element: QueryValue.Element) -> some QueryExpression<QueryValue> {
    SQLQueryExpression(
      "array_prepend(\(bind: element), \(self.queryFragment))",
      as: QueryValue.self
    )
  }

  /// Concatenates another array to this array
  ///
  /// PostgreSQL's `array_cat(anyarray, anyarray)` function.
  ///
  /// ```swift
  /// Post.select { $0.tags.concatenating($0.categories) }
  /// // SELECT array_cat("posts"."tags", "posts"."categories") FROM "posts"
  /// ```
  ///
  /// - Parameter other: The array to concatenate
  /// - Returns: A new array containing elements from both arrays
  public func concatenating(_ other: some QueryExpression<QueryValue>) -> some QueryExpression<
    QueryValue
  > {
    SQLQueryExpression(
      "array_cat(\(self.queryFragment), \(other.queryFragment))",
      as: QueryValue.self
    )
  }

  /// Concatenates a Swift array literal to this array
  ///
  /// PostgreSQL's `array_cat(anyarray, anyarray)` function with literal array.
  ///
  /// ```swift
  /// Post.select { $0.tags.concatenating(["swift", "postgres"]) }
  /// // SELECT array_cat("posts"."tags", ARRAY['swift', 'postgres']) FROM "posts"
  /// ```
  ///
  /// - Parameter elements: The elements to concatenate
  /// - Returns: A new array containing elements from both arrays
  public func concatenating(_ elements: [QueryValue.Element]) -> some QueryExpression<QueryValue> {
    // Build array using proper binding for each element
    var fragments: [QueryFragment] = []
    for element in elements {
      fragments.append("\(bind: element)")
    }
    let arrayLiteral = "ARRAY[\(fragments.joined(separator: ", "))]"
    return SQLQueryExpression(
      "array_cat(\(self.queryFragment), \(raw: arrayLiteral))",
      as: QueryValue.self
    )
  }
}

// MARK: - Free Functions (For composing without receiver)

/// Appends an element to the end of an array
///
/// PostgreSQL's `array_append(anyarray, anyelement)` function.
///
/// ```swift
/// User.select { append($0.tags, "swift") }
/// // SELECT array_append("users"."tags", 'swift') FROM "users"
/// ```
public func append<Element>(
  _ array: some QueryExpression<[Element]>,
  _ element: Element
) -> some QueryExpression<[Element]> where Element: QueryBindable {
  SQLQueryExpression(
    "array_append(\(array.queryFragment), \(bind: element))",
    as: [Element].self
  )
}

/// Prepends an element to the beginning of an array
///
/// PostgreSQL's `array_prepend(anyelement, anyarray)` function.
///
/// ```swift
/// User.select { prepend("featured", to: $0.tags) }
/// // SELECT array_prepend('featured', "users"."tags") FROM "users"
/// ```
public func prepend<Element>(
  _ element: Element,
  to array: some QueryExpression<[Element]>
) -> some QueryExpression<[Element]> where Element: QueryBindable {
  SQLQueryExpression(
    "array_prepend(\(bind: element), \(array.queryFragment))",
    as: [Element].self
  )
}

/// Concatenates two arrays
///
/// PostgreSQL's `array_cat(anyarray, anyarray)` function.
///
/// ```swift
/// User.select { concatenate($0.tags, $0.categories) }
/// // SELECT array_cat("users"."tags", "users"."categories") FROM "users"
/// ```
public func concatenate<Element>(
  _ array1: some QueryExpression<[Element]>,
  _ array2: some QueryExpression<[Element]>
) -> some QueryExpression<[Element]> where Element: QueryBindable {
  SQLQueryExpression(
    "array_cat(\(array1.queryFragment), \(array2.queryFragment))",
    as: [Element].self
  )
}

// MARK: - Array Constructors

/// Creates an array from the given elements
///
/// PostgreSQL's ARRAY constructor syntax.
///
/// ```swift
/// let tags = array(["swift", "postgres", "server"])
/// Post.insert { Post.Draft(title: "Hello", tags: tags) }
/// // INSERT INTO "posts" ("title", "tags") VALUES ('Hello', ARRAY['swift', 'postgres', 'server'])
/// ```
///
/// - Parameter elements: The elements to create an array from
/// - Returns: An array expression
public func array<Element>(
  _ elements: [Element]
) -> some QueryExpression<[Element]> where Element: QueryBindable {
  // Build array using proper binding for each element
  var fragments: [QueryFragment] = []
  for element in elements {
    fragments.append("\(bind: element)")
  }
  let arrayLiteral = QueryFragment("ARRAY[\(fragments.joined(separator: ", "))]")
  return SQLQueryExpression(arrayLiteral, as: [Element].self)
}

/// Creates an empty array of the specified element type
///
/// PostgreSQL's empty ARRAY constructor.
///
/// ```swift
/// Post.insert { Post.Draft(title: "Hello", tags: emptyArray(of: String.self)) }
/// // INSERT INTO "posts" ("title", "tags") VALUES ('Hello', ARRAY[]::text[])
/// ```
///
/// - Parameter elementType: The type of elements in the array
/// - Returns: An empty array expression
public func emptyArray<Element>(
  of elementType: Element.Type
) -> some QueryExpression<[Element]> where Element: PostgreSQLType {
  // Use PostgreSQLType protocol for type-safe type name resolution
  return SQLQueryExpression(
    "ARRAY[]::\(raw: Element.typeName)[]",
    as: [Element].self
  )
}
