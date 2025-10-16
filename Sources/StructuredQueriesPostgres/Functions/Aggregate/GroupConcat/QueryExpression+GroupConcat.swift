import StructuredQueriesCore

extension QueryExpression
where QueryValue: _OptionalPromotable, QueryValue._Optionalized.Wrapped == String {
    /// A string concatenation aggregate of this expression
    ///
    /// Concatenates all of the non-`NULL` strings in a group.
    ///
    /// ```swift
    /// Reminder.select { $0.title.groupConcat() }
    /// // SELECT group_concat("reminders"."title") FROM "reminders"
    /// ```
    ///
    /// - Parameters:
    ///   - separator: A string to insert between each of the results in a group. The default
    ///     separator is a comma.
    ///   - order: An `ORDER BY` clause to apply to the aggregation.
    ///   - filter: A `FILTER` clause to apply to the aggregation.
    /// - Returns: A string concatenation aggregate of this expression.
    public func groupConcat(
        _ separator: (some QueryExpression)? = String?.none,
        order: (some QueryExpression)? = Bool?.none,
        filter: (some QueryExpression<Bool>)? = Bool?.none
    ) -> some QueryExpression<String?> {
        AggregateFunction(
            "group_concat",
            separator.map { [queryFragment, $0.queryFragment] } ?? [queryFragment],
            order: order?.queryFragment,
            filter: filter?.queryFragment
        )
    }

    /// A string concatenation aggregate of this expression.
    ///
    /// See ``groupConcat(_:order:filter:)`` for more.
    ///
    /// - Parameters:
    ///   - isDistinct: Whether or not to include a `DISTINCT` clause, which filters duplicates from
    ///     the aggregation.
    ///   - order: An `ORDER BY` clause to apply to the aggregation.
    ///   - filter: A `FILTER` clause to apply to the aggregation.
    /// - Returns: A string concatenation aggregate of this expression.
    public func groupConcat(
        distinct isDistinct: Bool,
        order: (some QueryExpression)? = Bool?.none,
        filter: (some QueryExpression<Bool>)? = Bool?.none
    ) -> some QueryExpression<String?> {
        AggregateFunction(
            "group_concat",
            isDistinct: isDistinct,
            [queryFragment],
            order: order?.queryFragment,
            filter: filter?.queryFragment
        )
    }
}
