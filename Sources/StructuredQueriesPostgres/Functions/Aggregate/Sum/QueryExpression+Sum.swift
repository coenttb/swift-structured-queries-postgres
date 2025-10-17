import StructuredQueriesCore

extension QueryExpression
where QueryValue: _OptionalPromotable, QueryValue._Optionalized.Wrapped: Numeric {
    /// A sum aggregate of this expression (PostgreSQL `SUM` function).
    ///
    /// Computes the sum of all non-NULL values in the group.
    ///
    /// ```swift
    /// Order.select { $0.amount.sum() }
    /// // SELECT SUM("orders"."amount") FROM "orders"
    ///
    /// Product.select { $0.price.sum(distinct: true) }
    /// // SELECT SUM(DISTINCT "products"."price") FROM "products"
    /// ```
    ///
    /// - Parameters:
    ///   - isDistinct: Whether or not to include a `DISTINCT` clause, which filters duplicates from
    ///     the aggregation.
    ///   - filter: A `FILTER` clause to apply to the aggregation.
    /// - Returns: A sum aggregate of this expression.
    public func sum(
        distinct isDistinct: Bool = false,
        filter: (some QueryExpression<Bool>)? = Bool?.none
    ) -> some QueryExpression<QueryValue._Optionalized.Wrapped?> {
        AggregateFunction(
            "SUM",
            isDistinct: isDistinct,
            [queryFragment],
            filter: filter?.queryFragment
        )
    }
}
