import Foundation
import StructuredQueriesCore

extension TableColumn {
    /// PostgreSQL JSONB_AGG function - aggregates values into a JSONB array
    ///
    /// ```swift
    /// User.select { $0.name.jsonbAgg() }
    /// // SELECT jsonb_agg("users"."name") FROM "users"
    /// ```
    public func jsonbAgg() -> some QueryExpression<String?> {
        SimpleAggregateFunction<String?>(
            name: "jsonb_agg",
            column: queryFragment
        )
    }
}
