import StructuredQueriesCore

extension QueryExpression
where QueryValue: _OptionalPromotable, QueryValue._Optionalized.Wrapped: Numeric {
    /// A total aggregate of this expression.
    ///
    /// ```swift
    /// Item.select { $0.price.total() }
    /// // SELECT total("items"."price") FROM "items"
    /// ```
    ///
    /// - Parameters:
    ///   - isDistinct: Whether or not to include a `DISTINCT` clause, which filters duplicates from
    ///     the aggregation.
    ///   - filter: A `FILTER` clause to apply to the aggregation.
    /// - Returns: A total aggregate of this expression.
    public func total(
        distinct isDistinct: Bool = false,
        filter: (some QueryExpression<Bool>)? = Bool?.none
    ) -> some QueryExpression<QueryValue> {
        AggregateFunction(
            "total",
            isDistinct: isDistinct,
            [queryFragment],
            filter: filter?.queryFragment
        )
    }
}
