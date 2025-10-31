import StructuredQueriesCore

extension Table {
  /// A select statement for the average of an expression from this table.
  ///
  /// ```swift
  /// Order.avg { $0.amount }
  /// // SELECT AVG("orders"."amount") FROM "orders"
  ///
  /// // KeyPath syntax also works (Swift 5.2+):
  /// Order.avg(of: \.amount)
  /// ```
  ///
  /// - Parameter expression: A closure that takes table columns and returns an expression to average.
  /// - Returns: A select statement that selects the average of the expression.
  @inlinable
  public static func avg<Value>(
    of expression: (TableColumns) -> some QueryExpression<Value>
  ) -> Select<Double?, Self, ()>
  where Value: _OptionalPromotable, Value._Optionalized.Wrapped: Numeric {
    _aggregateSelect(of: expression) { $0.avg() }
  }

  /// A select statement for the average of an expression from this table with a filter clause.
  ///
  /// ```swift
  /// Order.avg(of: { $0.amount }, filter: { $0.isPaid })
  /// // SELECT AVG("orders"."amount") FILTER (WHERE "orders"."isPaid") FROM "orders"
  ///
  /// // KeyPath syntax also works (Swift 5.2+):
  /// Order.avg(of: \.amount, filter: { $0.isPaid })
  /// ```
  ///
  /// - Parameters:
  ///   - expression: A closure that takes table columns and returns an expression to average.
  ///   - filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A select statement that selects the average of the expression.
  @inlinable
  public static func avg<Value, Filter: QueryExpression<Bool>>(
    of expression: (TableColumns) -> some QueryExpression<Value>,
    filter: @escaping (TableColumns) -> Filter
  ) -> Select<Double?, Self, ()>
  where Value: _OptionalPromotable, Value._Optionalized.Wrapped: Numeric {
    _aggregateSelect(of: expression, filter: filter) { $0.avg(filter: $1) }
  }
}
