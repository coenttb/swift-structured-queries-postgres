import Foundation
import StructuredQueriesCore

extension TableColumn {
    /// PostgreSQL JSONB_AGG function - aggregates values into a JSONB array
    ///
    /// ```swift
    /// User.select { $0.name.jsonbAgg() }
    /// // SELECT jsonb_agg("users"."name") FROM "users"
    ///
    /// User.select { $0.name.jsonbAgg(filter: $0.isActive) }
    /// // SELECT jsonb_agg("users"."name") FILTER (WHERE "users"."is_active") FROM "users"
    /// ```
    ///
    /// - Parameter filter: A FILTER clause to apply to the aggregation
    /// - Returns: A JSONB array aggregate of this expression
    public func jsonbAgg(
        filter: (some QueryExpression<Bool>)? = Bool?.none
    ) -> some QueryExpression<String?> {
        AggregateFunction<String?>(
            "jsonb_agg",
            [queryFragment],
            filter: filter?.queryFragment
        )
    }
}
