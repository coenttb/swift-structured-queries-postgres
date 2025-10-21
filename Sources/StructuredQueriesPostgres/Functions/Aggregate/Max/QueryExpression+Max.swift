import StructuredQueriesCore

extension QueryExpression where QueryValue: QueryBindable & _OptionalPromotable {
    /// A maximum aggregate of this expression.
    ///
    /// ```swift
    /// Reminder.select { $0.date.max() }
    /// // SELECT max("reminders"."date") FROM "reminders"
    /// ```
    ///
    /// - Parameter filter: A `FILTER` clause to apply to the aggregation.
    /// - Returns: A maximum aggregate of this expression.
    public func max(
        filter: (some QueryExpression<Bool>)? = Bool?.none
    ) -> some QueryExpression<QueryValue._Optionalized.Wrapped?> {
        AggregateFunction("max", [queryFragment], filter: filter?.queryFragment)
    }
}
