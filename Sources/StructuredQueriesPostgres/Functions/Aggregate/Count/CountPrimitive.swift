import StructuredQueriesCore

// MARK: - Count Aggregate Primitives

extension QueryExpression where QueryValue: QueryBindable {
    /// A count aggregate of this expression.
    ///
    /// Counts the number of non-`NULL` times the expression appears in a group.
    ///
    /// ```swift
    /// Reminder.select { $0.id.count() }
    /// // SELECT count("reminders"."id") FROM "reminders"
    ///
    /// Reminder.select { $0.title.count(distinct: true) }
    /// // SELECT count(DISTINCT "reminders"."title") FROM "reminders"
    /// ```
    ///
    /// - Parameters:
    ///   - isDistinct: Whether or not to include a `DISTINCT` clause, which filters duplicates from
    ///     the aggregation.
    ///   - filter: A `FILTER` clause to apply to the aggregation.
    /// - Returns: A count aggregate of this expression.
    public func count(
        distinct isDistinct: Bool = false,
        filter: (some QueryExpression<Bool>)? = Bool?.none
    ) -> some QueryExpression<Int> {
        AggregateFunction(
            "count",
            isDistinct: isDistinct,
            [queryFragment],
            filter: filter?.queryFragment
        )
    }
}

extension QueryExpression where Self == AggregateFunction<Int> {
    /// A `count(*)` aggregate.
    ///
    /// ```swift
    /// Reminder.select { .count() }
    /// // SELECT count(*) FROM "reminders"
    /// ```
    ///
    /// - Parameter filter: A `FILTER` clause to apply to the aggregation.
    /// - Returns: A `count(*)` aggregate.
    public static func count(
        filter: (any QueryExpression<Bool>)? = nil
    ) -> Self {
        AggregateFunction("count", ["*"], filter: filter?.queryFragment)
    }
}
