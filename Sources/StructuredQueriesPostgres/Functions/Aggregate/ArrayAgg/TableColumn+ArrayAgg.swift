import Foundation
import StructuredQueriesCore

extension TableColumn {
    /// PostgreSQL ARRAY_AGG function - aggregates values into an array
    ///
    /// ```swift
    /// User.select { $0.id.arrayAgg() }
    /// // SELECT array_agg("users"."id") FROM "users"
    ///
    /// User.select { $0.id.arrayAgg(distinct: true) }
    /// // SELECT array_agg(DISTINCT "users"."id") FROM "users"
    ///
    /// User.select { $0.id.arrayAgg(filter: $0.isActive) }
    /// // SELECT array_agg("users"."id") FILTER (WHERE "users"."is_active") FROM "users"
    /// ```
    ///
    /// - Parameters:
    ///   - isDistinct: Whether to include only distinct values
    ///   - filter: A FILTER clause to apply to the aggregation
    /// - Returns: An array aggregate of this expression
    public func arrayAgg(
        distinct isDistinct: Bool = false,
        filter: (some QueryExpression<Bool>)? = Bool?.none
    ) -> some QueryExpression<String?> {
        AggregateFunction<String?>(
            "array_agg",
            isDistinct: isDistinct,
            [queryFragment],
            filter: filter?.queryFragment
        )
    }
}
