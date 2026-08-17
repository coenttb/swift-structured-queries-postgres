import Foundation
import StructuredQueriesCore

extension QueryExpression {
    /// PostgreSQL JSONB_AGG function - aggregates values into a JSONB array
    ///
    /// ```swift
    /// User.select { $0.name.jsonbAgg() }
    /// // SELECT JSONB_AGG("users"."name") FROM "users"
    ///
    /// User.select { $0.name.jsonbAgg(distinct: true) }
    /// // SELECT JSONB_AGG(DISTINCT "users"."name") FROM "users"
    ///
    /// User.select { $0.name.jsonbAgg(filter: $0.isActive) }
    /// // SELECT JSONB_AGG("users"."name") FILTER (WHERE "users"."is_active") FROM "users"
    /// ```
    ///
    /// - Parameters:
    ///   - isDistinct: Whether to include only distinct values
    ///   - order: Optional ordering expression for the aggregated values
    ///   - filter: A FILTER clause to apply to the aggregation
    /// - Returns: A JSONB array aggregate of this expression
    public func jsonbAgg(
        distinct isDistinct: Bool = false,
        order: (any QueryExpression)? = nil,
        // swiftlint:disable:previous no_any_protocol_existential
        // reason: fork-heritage type-erased DSL (pointfreeco/swift-structured-queries)
        filter: (some QueryExpression<Bool>)? = Bool?.none
    ) -> some QueryExpression<String?> {
        AggregateFunction<String?>(
            "JSONB_AGG",
            isDistinct: isDistinct,
            [queryFragment],
            order: order?.queryFragment,
            filter: filter?.queryFragment
        )
    }
}
