import StructuredQueriesCore

extension QueryExpression where QueryValue: QueryBindable & _OptionalPromotable {
  /// A minimum aggregate of this expression.
  ///
  /// ```swift
  /// Reminder.select { $0.date.min() }
  /// // SELECT min("reminders"."date") FROM "reminders"
  /// ```
  ///
  /// - Parameter filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A minimum aggregate of this expression.
  public func min(
    filter: (some QueryExpression<Bool>)? = Bool?.none
  ) -> some QueryExpression<QueryValue._Optionalized.Wrapped?> {
    AggregateFunction("min", [queryFragment], filter: filter?.queryFragment)
  }
}
