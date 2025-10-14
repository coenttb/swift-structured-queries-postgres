import Foundation
import StructuredQueriesCore

// MARK: - PostgreSQL Array Construction Functions
//
// PostgreSQL Chapter 9.19: Array Functions and Operators
// https://www.postgresql.org/docs/18/functions-array.html
//
// Array construction and concatenation functions for building and modifying arrays.

/// Appends an element to the end of an array
///
/// PostgreSQL's `array_append(anyarray, anyelement)` function.
///
/// ```swift
/// Post.select { $0.tags.arrayAppend("swift") }
/// // SELECT array_append("posts"."tags", 'swift') FROM "posts"
/// ```
///
/// - Parameter element: The element to append to the array
/// - Returns: A new array with the element appended
public func arrayAppend<Element>(
    _ array: some QueryExpression<[Element]>,
    _ element: Element
) -> some QueryExpression<[Element]> where Element: QueryBindable {
    SQLQueryExpression(
        "array_append(\(array.queryFragment), \(bind: element))",
        as: [Element].self
    )
}

/// Appends an element to the end of an array (method syntax)
extension QueryExpression where QueryValue: Collection, QueryValue.Element: QueryBindable {
    /// Appends an element to the end of an array
    ///
    /// ```swift
    /// Post.select { $0.tags.arrayAppend("swift") }
    /// // SELECT array_append("posts"."tags", 'swift') FROM "posts"
    /// ```
    public func arrayAppend(_ element: QueryValue.Element) -> some QueryExpression<QueryValue> {
        SQLQueryExpression(
            "array_append(\(self.queryFragment), \(bind: element))",
            as: QueryValue.self
        )
    }
}

/// Prepends an element to the beginning of an array
///
/// PostgreSQL's `array_prepend(anyelement, anyarray)` function.
///
/// ```swift
/// Post.select { $0.tags.arrayPrepend("featured") }
/// // SELECT array_prepend('featured', "posts"."tags") FROM "posts"
/// ```
///
/// - Parameter element: The element to prepend to the array
/// - Returns: A new array with the element prepended
public func arrayPrepend<Element>(
    _ element: Element,
    _ array: some QueryExpression<[Element]>
) -> some QueryExpression<[Element]> where Element: QueryBindable {
    SQLQueryExpression(
        "array_prepend(\(bind: element), \(array.queryFragment))",
        as: [Element].self
    )
}

/// Prepends an element to the beginning of an array (method syntax)
extension QueryExpression where QueryValue: Collection, QueryValue.Element: QueryBindable {
    /// Prepends an element to the beginning of an array
    ///
    /// ```swift
    /// Post.select { $0.tags.arrayPrepend("featured") }
    /// // SELECT array_prepend('featured', "posts"."tags") FROM "posts"
    /// ```
    public func arrayPrepend(_ element: QueryValue.Element) -> some QueryExpression<QueryValue> {
        SQLQueryExpression(
            "array_prepend(\(bind: element), \(self.queryFragment))",
            as: QueryValue.self
        )
    }
}

/// Concatenates two arrays
///
/// PostgreSQL's `array_cat(anyarray, anyarray)` function.
///
/// ```swift
/// Post.select { $0.tags.arrayCat(["swift", "postgres"]) }
/// // SELECT array_cat("posts"."tags", ARRAY['swift', 'postgres']) FROM "posts"
/// ```
///
/// - Parameter other: The array to concatenate
/// - Returns: A new array containing elements from both arrays
public func arrayCat<Element>(
    _ array1: some QueryExpression<[Element]>,
    _ array2: some QueryExpression<[Element]>
) -> some QueryExpression<[Element]> where Element: QueryBindable {
    SQLQueryExpression(
        "array_cat(\(array1.queryFragment), \(array2.queryFragment))",
        as: [Element].self
    )
}

/// Concatenates two arrays (method syntax)
extension QueryExpression where QueryValue: Collection, QueryValue.Element: QueryBindable {
    /// Concatenates another array to this array
    ///
    /// ```swift
    /// Post.select { $0.tags.arrayCat(["swift", "postgres"]) }
    /// // SELECT array_cat("posts"."tags", ARRAY['swift', 'postgres']) FROM "posts"
    /// ```
    public func arrayCat(_ other: [QueryValue.Element]) -> some QueryExpression<QueryValue> {
        let arrayLiteral = "ARRAY[\(other.map { "'\($0)'" }.joined(separator: ", "))]"
        return SQLQueryExpression(
            "array_cat(\(self.queryFragment), \(raw: arrayLiteral))",
            as: QueryValue.self
        )
    }

    /// Concatenates another array expression to this array
    ///
    /// ```swift
    /// Post.select { $0.tags.arrayCat($0.categories) }
    /// // SELECT array_cat("posts"."tags", "posts"."categories") FROM "posts"
    /// ```
    public func arrayCat(_ other: some QueryExpression<QueryValue>) -> some QueryExpression<
        QueryValue
    > {
        SQLQueryExpression(
            "array_cat(\(self.queryFragment), \(other.queryFragment))",
            as: QueryValue.self
        )
    }
}

/// Creates an array from the given elements
///
/// PostgreSQL's ARRAY constructor syntax.
///
/// ```swift
/// let tags = arrayFrom(["swift", "postgres", "server"])
/// Post.insert { Post.Draft(title: "Hello", tags: tags) }
/// // INSERT INTO "posts" ("title", "tags") VALUES ('Hello', ARRAY['swift', 'postgres', 'server'])
/// ```
///
/// - Parameter elements: The elements to create an array from
/// - Returns: An array expression
public func arrayFrom<Element>(
    _ elements: [Element]
) -> some QueryExpression<[Element]> where Element: QueryBindable {
    let arrayLiteral = QueryFragment(
        "ARRAY[\(raw: elements.map { "'\($0)'" }.joined(separator: ", "))]")
    return SQLQueryExpression(arrayLiteral, as: [Element].self)
}

/// Creates an empty array of the specified element type
///
/// PostgreSQL's empty ARRAY constructor.
///
/// ```swift
/// Post.insert { Post.Draft(title: "Hello", tags: emptyArray(String.self)) }
/// // INSERT INTO "posts" ("title", "tags") VALUES ('Hello', ARRAY[]::text[])
/// ```
///
/// - Parameter elementType: The type of elements in the array
/// - Returns: An empty array expression
public func emptyArray<Element>(
    _ elementType: Element.Type
) -> some QueryExpression<[Element]> where Element: QueryBindable {
    // PostgreSQL requires type cast for empty arrays
    let pgType = postgresTypeName(for: elementType)
    return SQLQueryExpression("ARRAY[]::\(raw: pgType)[]", as: [Element].self)
}

// Helper to map Swift types to PostgreSQL type names
private func postgresTypeName<T>(for type: T.Type) -> String {
    switch type {
    case is String.Type, is String?.Type:
        return "text"
    case is Int.Type, is Int?.Type:
        return "integer"
    case is Int64.Type, is Int64?.Type:
        return "bigint"
    case is Double.Type, is Double?.Type:
        return "double precision"
    case is Float.Type, is Float?.Type:
        return "real"
    case is Bool.Type, is Bool?.Type:
        return "boolean"
    case is UUID.Type, is UUID?.Type:
        return "uuid"
    case is Date.Type, is Date?.Type:
        return "timestamp"
    case is Data.Type, is Data?.Type:
        return "bytea"
    default:
        return "text"  // Fallback to text
    }
}
