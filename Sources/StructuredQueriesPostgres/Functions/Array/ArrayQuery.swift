import Foundation
import StructuredQueriesCore

// MARK: - PostgreSQL Array Query Functions
//
// PostgreSQL Chapter 9.19: Array Functions and Operators
// https://www.postgresql.org/docs/18/functions-array.html
//
// Functions for querying array properties and searching arrays.

extension QueryExpression where QueryValue: Collection, QueryValue.Element: QueryBindable {
    /// Returns the length (number of elements) of an array
    ///
    /// PostgreSQL's `array_length(anyarray, int)` function.
    /// Note: PostgreSQL arrays are 1-indexed, and dimension parameter is always 1 for 1D arrays.
    ///
    /// ```swift
    /// Post.where { $0.tags.arrayLength() > 3 }
    /// // SELECT … FROM "posts" WHERE array_length("posts"."tags", 1) > 3
    /// ```
    ///
    /// - Returns: The number of elements in the array, or NULL if array is NULL
    public func arrayLength() -> some QueryExpression<Int?> {
        SQLQueryExpression(
            "array_length(\(self.queryFragment), 1)",
            as: Int?.self
        )
    }

    /// Returns the total number of elements in an array
    ///
    /// PostgreSQL's `cardinality(anyarray)` function.
    /// Unlike array_length, this returns 0 for empty arrays and works with multi-dimensional arrays.
    ///
    /// ```swift
    /// Post.where { $0.tags.cardinality() > 0 }
    /// // SELECT … FROM "posts" WHERE cardinality("posts"."tags") > 0
    /// ```
    ///
    /// - Returns: The total number of elements, or NULL if array is NULL
    public func cardinality() -> some QueryExpression<Int?> {
        SQLQueryExpression(
            "cardinality(\(self.queryFragment))",
            as: Int?.self
        )
    }

    /// Returns the subscript of the first occurrence of an element in an array
    ///
    /// PostgreSQL's `array_position(anyarray, anyelement)` function.
    /// Note: PostgreSQL arrays are 1-indexed, returns NULL if element not found.
    ///
    /// ```swift
    /// Post.select { $0.tags.arrayPosition("swift") }
    /// // SELECT array_position("posts"."tags", 'swift') FROM "posts"
    /// ```
    ///
    /// - Parameter element: The element to search for
    /// - Returns: The 1-based index of the element, or NULL if not found
    public func arrayPosition(_ element: QueryValue.Element) -> some QueryExpression<Int?> {
        SQLQueryExpression(
            "array_position(\(self.queryFragment), \(bind: element))",
            as: Int?.self
        )
    }

    /// Returns the subscript of the first occurrence of an element in an array, starting from a position
    ///
    /// PostgreSQL's `array_position(anyarray, anyelement, int)` function.
    ///
    /// ```swift
    /// Post.select { $0.tags.arrayPosition("swift", startingFrom: 2) }
    /// // SELECT array_position("posts"."tags", 'swift', 2) FROM "posts"
    /// ```
    ///
    /// - Parameters:
    ///   - element: The element to search for
    ///   - start: The 1-based index to start searching from
    /// - Returns: The 1-based index of the element, or NULL if not found
    public func arrayPosition(_ element: QueryValue.Element, startingFrom start: Int)
        -> some QueryExpression<Int?>
    {
        SQLQueryExpression(
            "array_position(\(self.queryFragment), \(bind: element), \(start))",
            as: Int?.self
        )
    }

    /// Returns an array of subscripts of all occurrences of an element
    ///
    /// PostgreSQL's `array_positions(anyarray, anyelement)` function.
    ///
    /// ```swift
    /// Post.select { $0.tags.arrayPositions("swift") }
    /// // SELECT array_positions("posts"."tags", 'swift') FROM "posts"
    /// ```
    ///
    /// - Parameter element: The element to search for
    /// - Returns: An array of 1-based indices where the element occurs
    public func arrayPositions(_ element: QueryValue.Element) -> some QueryExpression<[Int]> {
        SQLQueryExpression(
            "array_positions(\(self.queryFragment), \(bind: element))",
            as: [Int].self
        )
    }

    /// Returns the lower bound of an array dimension
    ///
    /// PostgreSQL's `array_lower(anyarray, int)` function.
    /// For standard arrays, this is always 1.
    ///
    /// ```swift
    /// Post.select { $0.tags.arrayLower() }
    /// // SELECT array_lower("posts"."tags", 1) FROM "posts"
    /// ```
    ///
    /// - Returns: The lower bound (typically 1) of the array
    public func arrayLower() -> some QueryExpression<Int?> {
        SQLQueryExpression(
            "array_lower(\(self.queryFragment), 1)",
            as: Int?.self
        )
    }

    /// Returns the upper bound of an array dimension
    ///
    /// PostgreSQL's `array_upper(anyarray, int)` function.
    /// For standard arrays, this equals the array length.
    ///
    /// ```swift
    /// Post.select { $0.tags.arrayUpper() }
    /// // SELECT array_upper("posts"."tags", 1) FROM "posts"
    /// ```
    ///
    /// - Returns: The upper bound (length) of the array
    public func arrayUpper() -> some QueryExpression<Int?> {
        SQLQueryExpression(
            "array_upper(\(self.queryFragment), 1)",
            as: Int?.self
        )
    }

    /// Returns the number of dimensions of an array
    ///
    /// PostgreSQL's `array_ndims(anyarray)` function.
    /// Most arrays are 1-dimensional.
    ///
    /// ```swift
    /// Post.select { $0.tags.arrayNdims() }
    /// // SELECT array_ndims("posts"."tags") FROM "posts"
    /// ```
    ///
    /// - Returns: The number of dimensions (typically 1)
    public func arrayNdims() -> some QueryExpression<Int?> {
        SQLQueryExpression(
            "array_ndims(\(self.queryFragment))",
            as: Int?.self
        )
    }
}

/// Expands an array into a set of rows
///
/// PostgreSQL's `unnest(anyarray)` function.
/// Converts an array into a table of values (set-returning function).
///
/// ```swift
/// // Used in FROM clause or lateral joins
/// let unnested = unnest(Post.column(\.tags))
/// // SELECT * FROM unnest(ARRAY['swift', 'postgres'])
/// ```
///
/// > Note: This is a set-returning function, typically used in FROM clauses or lateral joins.
/// > Direct usage in SELECT may require additional query construction.
///
/// - Parameter array: The array expression to unnest
/// - Returns: A query expression representing the unnested rows
public func unnest<Element>(
    _ array: some QueryExpression<[Element]>
) -> some QueryExpression<Element> where Element: QueryBindable {
    SQLQueryExpression(
        "unnest(\(array.queryFragment))",
        as: Element.self
    )
}

/// Expands multiple arrays into a set of rows (in parallel)
///
/// PostgreSQL's `unnest(anyarray, anyarray, ...)` function with multiple arrays.
/// Each array is expanded in parallel, producing rows with elements from each array.
///
/// ```swift
/// // Used in FROM clause
/// let unnested = unnestArrays(tags, categories)
/// // SELECT * FROM unnest(tags_array, categories_array)
/// ```
///
/// > Note: This is a set-returning function, typically used in FROM clauses.
///
/// - Parameters:
///   - array1: First array to unnest
///   - array2: Second array to unnest
/// - Returns: A query expression representing the unnested rows
public func unnestArrays<Element1, Element2>(
    _ array1: some QueryExpression<[Element1]>,
    _ array2: some QueryExpression<[Element2]>
) -> SQLQueryExpression<(Element1, Element2)>
where Element1: QueryBindable, Element2: QueryBindable {
    SQLQueryExpression(
        "unnest(\(array1.queryFragment), \(array2.queryFragment))",
        as: (Element1, Element2).self
    )
}
