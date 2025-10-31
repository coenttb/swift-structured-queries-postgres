import StructuredQueriesCore

extension Table {
  /// A select statement for the minimum of an expression from this table.
  ///
  /// ```swift
  /// Order.min { $0.amount }
  /// // SELECT min("orders"."amount") FROM "orders"
  ///
  /// // KeyPath syntax also works (Swift 5.2+):
  /// Order.min(of: \.amount)
  /// ```
  ///
  /// - Parameter expression: A closure that takes table columns and returns an expression to find the minimum of.
  /// - Returns: A select statement that selects the minimum of the expression.
  @inlinable
  public static func min<Value>(
    of expression: (TableColumns) -> some QueryExpression<Value>
  ) -> Select<Value._Optionalized.Wrapped?, Self, ()>
  where
    Value: QueryBindable & _OptionalPromotable,
    Value._Optionalized.Wrapped: QueryRepresentable
  {
    _aggregateSelect(of: expression) { $0.min() }
  }

  /// A select statement for the minimum of an expression from this table with a filter clause.
  ///
  /// ```swift
  /// Order.min(of: { $0.amount }, filter: { $0.status == "completed" })
  /// // SELECT min("orders"."amount") FILTER (WHERE "orders"."status" = 'completed') FROM "orders"
  ///
  /// // KeyPath syntax also works (Swift 5.2+):
  /// Order.min(of: \.amount, filter: { $0.status == "completed" })
  /// ```
  ///
  /// - Parameters:
  ///   - expression: A closure that takes table columns and returns an expression to find the minimum of.
  ///   - filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A select statement that selects the minimum of the expression.
  @inlinable
  public static func min<Value, Filter: QueryExpression<Bool>>(
    of expression: (TableColumns) -> some QueryExpression<Value>,
    filter: @escaping (TableColumns) -> Filter
  ) -> Select<Value._Optionalized.Wrapped?, Self, ()>
  where
    Value: QueryBindable & _OptionalPromotable,
    Value._Optionalized.Wrapped: QueryRepresentable
  {
    _aggregateSelect(of: expression, filter: filter) { $0.min(filter: $1) }
  }
}
