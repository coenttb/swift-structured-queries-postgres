import Foundation
import StructuredQueriesCore

// MARK: - PostgreSQL Array Operators
//
// PostgreSQL Chapter 9.19: Array Functions and Operators
// https://www.postgresql.org/docs/18/functions-array.html
//
// Operators for array comparison, containment, and concatenation.

extension QueryExpression where QueryValue: Collection, QueryValue.Element: QueryBindable {
    // MARK: - Containment Operators

    /// Tests whether an array contains another array (all elements)
    ///
    /// PostgreSQL's `@>` operator.
    ///
    /// ```swift
    /// Post.where { $0.tags.contains(["swift", "postgres"]) }
    /// // SELECT … FROM "posts" WHERE "posts"."tags" @> ARRAY['swift', 'postgres']
    /// ```
    ///
    /// - Parameter other: The array to test for containment
    /// - Returns: True if the array contains all elements from the other array
    ///
    /// - Warning: **Empty array behavior** (vacuous truth):
    ///   - `contains([])` matches **ALL non-NULL rows** (every set contains the empty set)
    ///   - `NULL` arrays return `NULL` (not `TRUE` or `FALSE`)
    ///   - Example: `ARRAY[1,2,3] @> ARRAY[] → TRUE`, `NULL @> ARRAY[] → NULL`
    ///   - This follows PostgreSQL's mathematical set containment semantics
    public func contains(_ other: [QueryValue.Element]) -> some QueryExpression<Bool> {
        var fragment: QueryFragment = "(\(self.queryFragment) @> ARRAY["
        fragment.append(other.map { "\(bind: $0)" }.joined(separator: ", "))
        fragment.append("])")
        return SQLQueryExpression(fragment, as: Bool.self)
    }

    /// Tests whether an array contains another array expression
    ///
    /// PostgreSQL's `@>` operator.
    ///
    /// ```swift
    /// Post.where { $0.tags.contains($0.requiredTags) }
    /// // SELECT … FROM "posts" WHERE "posts"."tags" @> "posts"."requiredTags"
    /// ```
    public func contains(_ other: some QueryExpression<QueryValue>) -> some QueryExpression<Bool> {
        SQLQueryExpression(
            "(\(self.queryFragment) @> \(other.queryFragment))",
            as: Bool.self
        )
    }

    /// Tests whether an array is contained by another array
    ///
    /// PostgreSQL's `<@` operator.
    ///
    /// ```swift
    /// Post.where { $0.tags.isContainedBy(["swift", "postgres", "server", "web"]) }
    /// // SELECT … FROM "posts" WHERE "posts"."tags" <@ ARRAY['swift', 'postgres', 'server', 'web']
    /// ```
    ///
    /// - Parameter other: The array to test against
    /// - Returns: True if all elements of this array are in the other array
    public func isContainedBy(_ other: [QueryValue.Element]) -> some QueryExpression<Bool> {
        var fragment: QueryFragment = "(\(self.queryFragment) <@ ARRAY["
        fragment.append(other.map { "\(bind: $0)" }.joined(separator: ", "))
        fragment.append("])")
        return SQLQueryExpression(fragment, as: Bool.self)
    }

    /// Tests whether an array is contained by another array expression
    ///
    /// PostgreSQL's `<@` operator.
    ///
    /// ```swift
    /// Post.where { $0.tags.isContainedBy($0.allowedTags) }
    /// // SELECT … FROM "posts" WHERE "posts"."tags" <@ "posts"."allowedTags"
    /// ```
    public func isContainedBy(_ other: some QueryExpression<QueryValue>) -> some QueryExpression<
        Bool
    > {
        SQLQueryExpression(
            "(\(self.queryFragment) <@ \(other.queryFragment))",
            as: Bool.self
        )
    }

    /// Tests whether arrays have any elements in common (overlap)
    ///
    /// PostgreSQL's `&&` operator.
    ///
    /// ```swift
    /// Post.where { $0.tags.overlaps(["swift", "rust"]) }
    /// // SELECT … FROM "posts" WHERE "posts"."tags" && ARRAY['swift', 'rust']
    /// ```
    ///
    /// - Parameter other: The array to test for overlap
    /// - Returns: True if the arrays have at least one common element
    public func overlaps(_ other: [QueryValue.Element]) -> some QueryExpression<Bool> {
        var fragment: QueryFragment = "(\(self.queryFragment) && ARRAY["
        fragment.append(other.map { "\(bind: $0)" }.joined(separator: ", "))
        fragment.append("])")
        return SQLQueryExpression(fragment, as: Bool.self)
    }

    /// Tests whether arrays have any elements in common with another array expression
    ///
    /// PostgreSQL's `&&` operator.
    ///
    /// ```swift
    /// Post.where { $0.tags.overlaps($0.featuredTags) }
    /// // SELECT … FROM "posts" WHERE "posts"."tags" && "posts"."featuredTags"
    /// ```
    public func overlaps(_ other: some QueryExpression<QueryValue>) -> some QueryExpression<Bool> {
        SQLQueryExpression(
            "(\(self.queryFragment) && \(other.queryFragment))",
            as: Bool.self
        )
    }

    // MARK: - Array Concatenation Operator

    /// Concatenates arrays using the `||` operator
    ///
    /// PostgreSQL's `||` operator for arrays.
    ///
    /// ```swift
    /// Post.select { $0.tags.arrayConcat(["new-tag"]) }
    /// // SELECT ("posts"."tags" || ARRAY['new-tag']) FROM "posts"
    /// ```
    ///
    /// - Parameter other: The array to concatenate
    /// - Returns: A new array with elements from both arrays
    public func arrayConcat(_ other: [QueryValue.Element]) -> some QueryExpression<QueryValue> {
        var fragment: QueryFragment = "(\(self.queryFragment) || ARRAY["
        fragment.append(other.map { "\(bind: $0)" }.joined(separator: ", "))
        fragment.append("])")
        return SQLQueryExpression(fragment, as: QueryValue.self)
    }

    /// Concatenates arrays using the `||` operator with an expression
    ///
    /// PostgreSQL's `||` operator for arrays.
    ///
    /// ```swift
    /// Post.select { $0.tags.arrayConcat($0.extraTags) }
    /// // SELECT ("posts"."tags" || "posts"."extraTags") FROM "posts"
    /// ```
    public func arrayConcat(_ other: some QueryExpression<QueryValue>) -> some QueryExpression<
        QueryValue
    > {
        SQLQueryExpression(
            "(\(self.queryFragment) || \(other.queryFragment))",
            as: QueryValue.self
        )
    }

    /// Concatenates a single element to an array using the `||` operator
    ///
    /// PostgreSQL's `||` operator (array || element).
    ///
    /// ```swift
    /// Post.select { $0.tags.arrayConcat("new-tag") }
    /// // SELECT ("posts"."tags" || 'new-tag') FROM "posts"
    /// ```
    ///
    /// - Parameter element: The element to append
    /// - Returns: A new array with the element appended
    public func arrayConcat(_ element: QueryValue.Element) -> some QueryExpression<QueryValue> {
        SQLQueryExpression(
            "(\(self.queryFragment) || \(bind: element))",
            as: QueryValue.self
        )
    }
}

// MARK: - Element || Array Operator

/// Prepends an element to an array using the `||` operator
///
/// PostgreSQL's `||` operator (element || array).
///
/// ```swift
/// let prependedTags = "featured".prependToArray($0.tags)
/// // SELECT ('featured' || "posts"."tags") FROM "posts"
/// ```
///
/// > Note: This is less common than array operators. Consider using `arrayPrepend()` instead.
///
/// - Parameters:
///   - element: The element to prepend
///   - array: The array to prepend to
/// - Returns: A new array with the element prepended
public func prependToArray<Element>(
    _ element: Element,
    _ array: some QueryExpression<[Element]>
) -> some QueryExpression<[Element]> where Element: QueryBindable {
    SQLQueryExpression(
        "(\(bind: element) || \(array.queryFragment))",
        as: [Element].self
    )
}

// MARK: - Array Equality Operators

extension QueryExpression
where QueryValue: Collection, QueryValue.Element: QueryBindable & Equatable {
    /// Tests whether two arrays are equal
    ///
    /// PostgreSQL's `=` operator for arrays.
    ///
    /// ```swift
    /// Post.where { $0.tags.arrayEquals(["swift", "postgres"]) }
    /// // SELECT … FROM "posts" WHERE "posts"."tags" = ARRAY['swift', 'postgres']
    /// ```
    ///
    /// - Parameter other: The array to compare against
    /// - Returns: True if the arrays are equal
    public func arrayEquals(_ other: [QueryValue.Element]) -> some QueryExpression<Bool> {
        var fragment: QueryFragment = "(\(self.queryFragment) = ARRAY["
        fragment.append(other.map { "\(bind: $0)" }.joined(separator: ", "))
        fragment.append("])")
        return SQLQueryExpression(fragment, as: Bool.self)
    }

    /// Tests whether two array expressions are equal
    ///
    /// PostgreSQL's `=` operator for arrays.
    ///
    /// ```swift
    /// Post.where { $0.tags.arrayEquals($0.previousTags) }
    /// // SELECT … FROM "posts" WHERE "posts"."tags" = "posts"."previousTags"
    /// ```
    public func arrayEquals(_ other: some QueryExpression<QueryValue>) -> some QueryExpression<Bool>
    {
        SQLQueryExpression(
            "(\(self.queryFragment) = \(other.queryFragment))",
            as: Bool.self
        )
    }

    /// Tests whether two arrays are not equal
    ///
    /// PostgreSQL's `<>` operator for arrays.
    ///
    /// ```swift
    /// Post.where { $0.tags.arrayNotEquals(["default"]) }
    /// // SELECT … FROM "posts" WHERE "posts"."tags" <> ARRAY['default']
    /// ```
    public func arrayNotEquals(_ other: [QueryValue.Element]) -> some QueryExpression<Bool> {
        var fragment: QueryFragment = "(\(self.queryFragment) <> ARRAY["
        fragment.append(other.map { "\(bind: $0)" }.joined(separator: ", "))
        fragment.append("])")
        return SQLQueryExpression(fragment, as: Bool.self)
    }
}

// MARK: - Array Comparison Operators

extension QueryExpression
where QueryValue: Collection, QueryValue.Element: QueryBindable & Comparable {
    /// Tests whether an array is less than another
    ///
    /// PostgreSQL's `<` operator for arrays (lexicographic comparison).
    ///
    /// ```swift
    /// Post.where { $0.tags.arrayLessThan(["zzz"]) }
    /// // SELECT … FROM "posts" WHERE "posts"."tags" < ARRAY['zzz']
    /// ```
    public func arrayLessThan(_ other: [QueryValue.Element]) -> some QueryExpression<Bool> {
        var fragment: QueryFragment = "(\(self.queryFragment) < ARRAY["
        fragment.append(other.map { "\(bind: $0)" }.joined(separator: ", "))
        fragment.append("])")
        return SQLQueryExpression(fragment, as: Bool.self)
    }

    /// Tests whether an array is greater than another
    ///
    /// PostgreSQL's `>` operator for arrays (lexicographic comparison).
    ///
    /// ```swift
    /// Post.where { $0.tags.arrayGreaterThan(["aaa"]) }
    /// // SELECT … FROM "posts" WHERE "posts"."tags" > ARRAY['aaa']
    /// ```
    public func arrayGreaterThan(_ other: [QueryValue.Element]) -> some QueryExpression<Bool> {
        var fragment: QueryFragment = "(\(self.queryFragment) > ARRAY["
        fragment.append(other.map { "\(bind: $0)" }.joined(separator: ", "))
        fragment.append("])")
        return SQLQueryExpression(fragment, as: Bool.self)
    }
}
