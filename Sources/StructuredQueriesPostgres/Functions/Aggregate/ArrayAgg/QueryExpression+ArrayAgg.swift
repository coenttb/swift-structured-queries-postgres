import Foundation
import StructuredQueriesCore

extension QueryExpression {
    /// PostgreSQL ARRAY_AGG function - aggregates values into an array
    ///
    /// ```swift
    /// User.select { $0.id.arrayAgg() }
    /// // SELECT ARRAY_AGG("users"."id") FROM "users"
    ///
    /// User.select { $0.id.arrayAgg(distinct: true) }
    /// // SELECT ARRAY_AGG(DISTINCT "users"."id") FROM "users"
    ///
    /// User.select { $0.id.arrayAgg(filter: $0.isActive) }
    /// // SELECT ARRAY_AGG("users"."id") FILTER (WHERE "users"."is_active") FROM "users"
    /// ```
    ///
    /// - Parameters:
    ///   - isDistinct: Whether to include only distinct values
    ///   - order: Optional ordering expression for the aggregated values
    ///   - filter: A FILTER clause to apply to the aggregation
    /// - Returns: An array aggregate of this expression
    public func arrayAgg(
        distinct isDistinct: Bool = false,
        order: (any QueryExpression)? = nil,
        filter: (some QueryExpression<Bool>)? = Bool?.none
    ) -> some QueryExpression<String?> {
        AggregateFunction<String?>(
            "array_agg",
            isDistinct: isDistinct,
            [queryFragment],
            order: order?.queryFragment,
            filter: filter?.queryFragment
        )
    }
}
