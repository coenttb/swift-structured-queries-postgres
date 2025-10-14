import Foundation
import StructuredQueriesCore

// MARK: - PostgreSQL String Aggregation Functions

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
        filter: (some QueryExpression<Bool>)? = nil
    ) -> some QueryExpression<String?> {
        var fragment: QueryFragment = "STRING_AGG("
        fragment.append(self.queryFragment)
        fragment.append(", \(bind: separator)")

        if let order {
            fragment.append(" ORDER BY \(order.queryFragment)")
        }
        fragment.append(")")

        if let filter {
            fragment.append(" FILTER (WHERE \(filter.queryFragment))")
        }

        return SQLQueryExpression(fragment, as: String?.self)
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
    ///   - distinct: Whether to aggregate only distinct values
    ///   - separator: The delimiter to place between values (default: ",")
    ///   - order: Optional ordering expression for the aggregated values
    ///   - filter: Optional filter condition (FILTER WHERE clause)
    /// - Returns: An optional string with all distinct values concatenated, or NULL if no values
    public func stringAgg(
        distinct: Bool,
        separator: String = ",",
        order: (any QueryExpression)? = nil,
        filter: (some QueryExpression<Bool>)? = nil
    ) -> some QueryExpression<String?> {
        var fragment: QueryFragment = "STRING_AGG("
        if distinct {
            fragment.append("DISTINCT ")
        }
        fragment.append(self.queryFragment)
        fragment.append(", \(bind: separator)")

        if let order {
            fragment.append(" ORDER BY \(order.queryFragment)")
        }
        fragment.append(")")

        if let filter {
            fragment.append(" FILTER (WHERE \(filter.queryFragment))")
        }

        return SQLQueryExpression(fragment, as: String?.self)
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
        filter: (some QueryExpression<Bool>)? = nil
    ) -> some QueryExpression<String?> {
        var fragment: QueryFragment = "STRING_AGG(CAST("
        fragment.append(self.queryFragment)
        fragment.append(" AS TEXT), \(bind: separator)")

        if let order {
            fragment.append(" ORDER BY \(order.queryFragment)")
        }
        fragment.append(")")

        if let filter {
            fragment.append(" FILTER (WHERE \(filter.queryFragment))")
        }

        return SQLQueryExpression(fragment, as: String?.self)
    }
}
