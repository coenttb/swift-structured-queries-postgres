import Foundation
import StructuredQueriesCore

extension TableColumn {
    /// PostgreSQL JSON_AGG function - aggregates values into a JSON array
    ///
    /// ```swift
    /// User.select { $0.name.jsonAgg() }
    /// // SELECT json_agg("users"."name") FROM "users"
    ///
    /// User.select { $0.name.jsonAgg(filter: $0.isActive) }
    /// // SELECT json_agg("users"."name") FILTER (WHERE "users"."is_active") FROM "users"
    /// ```
    ///
    /// - Parameter filter: A FILTER clause to apply to the aggregation
    /// - Returns: A JSON array aggregate of this expression
    public func jsonAgg(
        filter: (some QueryExpression<Bool>)? = Bool?.none
    ) -> some QueryExpression<String?> {
        AggregateFunction<String?>(
            "json_agg",
            [queryFragment],
            filter: filter?.queryFragment
        )
    }
}
