import StructuredQueriesCore

extension Where {
  /// A select statement for the maximum of an expression from the filtered table.
  ///
  /// ```swift
  /// Order.max { $0.amount }
  /// // SELECT max("orders"."amount") FROM "orders"
  ///
  /// Order.where { $0.status == "completed" }.max { $0.amount }
  /// // SELECT max("orders"."amount") FROM "orders" WHERE "orders"."status" = 'completed'
  /// ```
  ///
  /// - Parameter expression: A closure that takes table columns and returns an expression to find the maximum of.
  /// - Returns: A select statement that selects the maximum of the expression.
  @inlinable
  public func max<Value>(
    of expression: (From.TableColumns) -> some QueryExpression<Value>
  ) -> Select<Value._Optionalized.Wrapped?, From, ()>
  where
    Value: QueryBindable & _OptionalPromotable,
    Value._Optionalized.Wrapped: QueryRepresentable
  {
    _aggregateSelect(of: expression) { $0.max() }
  }

  /// A select statement for the maximum of an expression from the filtered table with a filter clause.
  ///
  /// ```swift
  /// Order.max(of: { $0.amount }, filter: { $0.status == "completed" })
  /// // SELECT max("orders"."amount") FILTER (WHERE "orders"."status" = 'completed') FROM "orders"
  /// ```
  ///
  /// - Parameters:
  ///   - expression: A closure that takes table columns and returns an expression to find the maximum of.
  ///   - filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A select statement that selects the maximum of the expression.
  @inlinable
  public func max<Value, Filter: QueryExpression<Bool>>(
    of expression: (From.TableColumns) -> some QueryExpression<Value>,
    filter: @escaping (From.TableColumns) -> Filter
  ) -> Select<Value._Optionalized.Wrapped?, From, ()>
  where
    Value: QueryBindable & _OptionalPromotable,
    Value._Optionalized.Wrapped: QueryRepresentable
  {
    _aggregateSelect(of: expression, filter: filter) { $0.max(filter: $1) }
  }
}
