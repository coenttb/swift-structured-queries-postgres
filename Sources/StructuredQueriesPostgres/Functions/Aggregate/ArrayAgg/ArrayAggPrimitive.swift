import Foundation
import StructuredQueriesCore

extension TableColumn {
    /// PostgreSQL ARRAY_AGG function - aggregates values into an array
    ///
    /// ```swift
    /// User.select { $0.id.arrayAgg() }
    /// // SELECT array_agg("users"."id") FROM "users"
    /// ```
    public func arrayAgg() -> some QueryExpression<String?> {
        SimpleAggregateFunction<String?>(
            name: "array_agg",
            column: queryFragment
        )
    }
}
