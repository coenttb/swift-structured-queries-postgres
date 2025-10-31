import Foundation
import StructuredQueriesCore

extension TableColumn {
  /// PostgreSQL JSONB_AGG function - aggregates values into a JSONB array
  ///
  /// ```swift
  /// User.select { $0.name.jsonbAgg() }
  /// // SELECT jsonb_agg("users"."name") FROM "users"
  ///
  /// User.select { $0.name.jsonbAgg(distinct: true) }
  /// // SELECT jsonb_agg(DISTINCT "users"."name") FROM "users"
  ///
  /// User.select { $0.name.jsonbAgg(order: $0.createdAt.desc()) }
  /// // SELECT jsonb_agg("users"."name" ORDER BY "users"."created_at" DESC) FROM "users"
  ///
  /// User.select { $0.name.jsonbAgg(filter: $0.isActive) }
  /// // SELECT jsonb_agg("users"."name") FILTER (WHERE "users"."is_active") FROM "users"
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
    filter: (some QueryExpression<Bool>)? = Bool?.none
  ) -> some QueryExpression<String?> {
    AggregateFunction<String?>(
      "jsonb_agg",
      isDistinct: isDistinct,
      [queryFragment],
      order: order?.queryFragment,
      filter: filter?.queryFragment
    )
  }
}
