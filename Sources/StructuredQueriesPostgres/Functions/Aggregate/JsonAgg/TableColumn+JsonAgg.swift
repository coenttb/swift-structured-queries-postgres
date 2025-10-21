import Foundation
import StructuredQueriesCore

extension TableColumn {
    /// PostgreSQL JSON_AGG function - aggregates values into a JSON array
    ///
    /// ```swift
    /// User.select { $0.name.jsonAgg() }
    /// // SELECT json_agg("users"."name") FROM "users"
    ///
    /// User.select { $0.name.jsonAgg(distinct: true) }
    /// // SELECT json_agg(DISTINCT "users"."name") FROM "users"
    ///
    /// User.select { $0.name.jsonAgg(order: $0.createdAt.desc()) }
    /// // SELECT json_agg("users"."name" ORDER BY "users"."created_at" DESC) FROM "users"
    ///
    /// User.select { $0.name.jsonAgg(filter: $0.isActive) }
    /// // SELECT json_agg("users"."name") FILTER (WHERE "users"."is_active") FROM "users"
    /// ```
    ///
    /// - Parameters:
    ///   - isDistinct: Whether to include only distinct values
    ///   - order: Optional ordering expression for the aggregated values
    ///   - filter: A FILTER clause to apply to the aggregation
    /// - Returns: A JSON array aggregate of this expression
    public func jsonAgg(
        distinct isDistinct: Bool = false,
        order: (any QueryExpression)? = nil,
        filter: (some QueryExpression<Bool>)? = Bool?.none
    ) -> some QueryExpression<String?> {
        AggregateFunction<String?>(
            "json_agg",
            isDistinct: isDistinct,
            [queryFragment],
            order: order?.queryFragment,
            filter: filter?.queryFragment
        )
    }
}
