import Foundation
import StructuredQueriesCore

extension TableColumn {
    /// PostgreSQL JSON_AGG function - aggregates values into a JSON array
    ///
    /// ```swift
    /// User.select { $0.name.jsonAgg() }
    /// // SELECT json_agg("users"."name") FROM "users"
    /// ```
    public func jsonAgg() -> some QueryExpression<String?> {
        SimpleAggregateFunction<String?>(
            name: "json_agg",
            column: queryFragment
        )
    }
}
