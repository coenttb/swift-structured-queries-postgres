import Foundation
import StructuredQueriesCore

// MARK: - PostgreSQL STRING_AGG Function

extension QueryExpression where QueryValue == String {
  /// PostgreSQL's `STRING_AGG` function - aggregates string values with a separator
  ///
  /// Concatenates non-null values from a group into a single string, with values separated by
  /// the specified delimiter.
  ///
  /// ```swift
  /// Tag.select { $0.name.stringAgg(", ") }
  /// // SELECT STRING_AGG("tags"."name", ', ') FROM "tags"
  ///
  /// Tag.select { $0.name.stringAgg(", ", order: $0.name) }
  /// // SELECT STRING_AGG("tags"."name", ', ' ORDER BY "tags"."name") FROM "tags"
  /// ```
  ///
  /// > Note: SQLite equivalent: `GROUP_CONCAT`
  ///
  /// - Parameters:
  ///   - separator: The delimiter to place between values (default: ",")
  ///   - order: Optional ordering expression for the aggregated values
  ///   - filter: Optional filter condition (FILTER WHERE clause)
  /// - Returns: An optional string with all values concatenated, or NULL if no values
  public func stringAgg(
    _ separator: String = ",",
    order: (any QueryExpression)? = nil,
    filter: (some QueryExpression<Bool>)? = Bool?.none
  ) -> some QueryExpression<String?> {
    AggregateFunction<String?>(
      "STRING_AGG",
      [queryFragment, "\(bind: separator)"],
      order: order?.queryFragment,
      filter: filter?.queryFragment
    )
  }

  /// PostgreSQL's `STRING_AGG` function with `DISTINCT` modifier
  ///
  /// Aggregates only distinct (unique) values.
  ///
  /// ```swift
  /// Tag.select { $0.category.stringAgg(distinct: true, separator: ", ") }
  /// // SELECT STRING_AGG(DISTINCT "tags"."category", ', ') FROM "tags"
  /// ```
  ///
  /// - Parameters:
  ///   - isDistinct: Whether to aggregate only distinct values
  ///   - separator: The delimiter to place between values (default: ",")
  ///   - order: Optional ordering expression for the aggregated values
  ///   - filter: Optional filter condition (FILTER WHERE clause)
  /// - Returns: An optional string with all distinct values concatenated, or NULL if no values
  public func stringAgg(
    distinct isDistinct: Bool,
    separator: String = ",",
    order: (any QueryExpression)? = nil,
    filter: (some QueryExpression<Bool>)? = Bool?.none
  ) -> some QueryExpression<String?> {
    AggregateFunction<String?>(
      "STRING_AGG",
      isDistinct: isDistinct,
      [queryFragment, "\(bind: separator)"],
      order: order?.queryFragment,
      filter: filter?.queryFragment
    )
  }
}

extension QueryExpression {
  /// Generic `STRING_AGG` for any expression type (will be cast to text)
  ///
  /// Automatically casts non-string expressions to TEXT before aggregating.
  ///
  /// ```swift
  /// User.select { $0.id.stringAgg(", ") }
  /// // SELECT STRING_AGG(CAST("users"."id" AS TEXT), ', ') FROM "users"
  /// ```
  ///
  /// - Parameters:
  ///   - separator: The delimiter to place between values (default: ",")
  ///   - order: Optional ordering expression for the aggregated values
  ///   - filter: Optional filter condition (FILTER WHERE clause)
  /// - Returns: An optional string with all values concatenated as text, or NULL if no values
  public func stringAgg(
    _ separator: String = ",",
    order: (any QueryExpression)? = nil,
    filter: (some QueryExpression<Bool>)? = Bool?.none
  ) -> some QueryExpression<String?> {
    AggregateFunction<String?>(
      "STRING_AGG",
      ["CAST(\(queryFragment) AS TEXT)", "\(bind: separator)"],
      order: order?.queryFragment,
      filter: filter?.queryFragment
    )
  }
}

// MARK: - Legacy TableColumn API (deprecated in favor of QueryExpression)

extension TableColumn {
  /// PostgreSQL STRING_AGG function - concatenates strings with a separator
  ///
  /// > Warning: This is a legacy API. Use `QueryExpression.stringAgg(_:order:filter:)` instead
  /// for full DISTINCT, ORDER BY, and FILTER support.
  ///
  /// ```swift
  /// User.select { $0.name.stringAgg(", ") }
  /// // SELECT string_agg("users"."name", ', ') FROM "users"
  /// ```
  @available(
    *, deprecated,
    message:
      "Use QueryExpression.stringAgg(_:order:filter:) instead for DISTINCT, ORDER BY, and FILTER support"
  )
  public func stringAgg(_ separator: String) -> some QueryExpression<String?> {
    AggregateFunction<String?>(
      "string_agg",
      [queryFragment, "\(bind: separator)"]
    )
  }
}
