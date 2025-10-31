import StructuredQueriesCore

extension Where {
  /// A select statement for the minimum of an expression from the filtered table.
  ///
  /// ```swift
  /// Order.min { $0.amount }
  /// // SELECT min("orders"."amount") FROM "orders"
  ///
  /// Order.where { $0.status == "completed" }.min { $0.amount }
  /// // SELECT min("orders"."amount") FROM "orders" WHERE "orders"."status" = 'completed'
  /// ```
  ///
  /// - Parameter expression: A closure that takes table columns and returns an expression to find the minimum of.
  /// - Returns: A select statement that selects the minimum of the expression.
  @inlinable
  public func min<Value>(
    of expression: (From.TableColumns) -> some QueryExpression<Value>
  ) -> Select<Value._Optionalized.Wrapped?, From, ()>
  where
    Value: QueryBindable & _OptionalPromotable,
    Value._Optionalized.Wrapped: QueryRepresentable
  {
    _aggregateSelect(of: expression) { $0.min() }
  }

  /// A select statement for the minimum of an expression from the filtered table with a filter clause.
  ///
  /// ```swift
  /// Order.min(of: { $0.amount }, filter: { $0.status == "completed" })
  /// // SELECT min("orders"."amount") FILTER (WHERE "orders"."status" = 'completed') FROM "orders"
  /// ```
  ///
  /// - Parameters:
  ///   - expression: A closure that takes table columns and returns an expression to find the minimum of.
  ///   - filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A select statement that selects the minimum of the expression.
  @inlinable
  public func min<Value, Filter: QueryExpression<Bool>>(
    of expression: (From.TableColumns) -> some QueryExpression<Value>,
    filter: @escaping (From.TableColumns) -> Filter
  ) -> Select<Value._Optionalized.Wrapped?, From, ()>
  where
    Value: QueryBindable & _OptionalPromotable,
    Value._Optionalized.Wrapped: QueryRepresentable
  {
    _aggregateSelect(of: expression, filter: filter) { $0.min(filter: $1) }
  }
}
