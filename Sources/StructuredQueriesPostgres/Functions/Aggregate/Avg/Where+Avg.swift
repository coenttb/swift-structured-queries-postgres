import StructuredQueriesCore

extension Where {
  /// Computes the average of a numeric column for rows matching the WHERE clause.
  ///
  /// ```swift
  /// Order.where { $0.isPaid }.avg { $0.amount }
  /// // SELECT AVG("orders"."amount") FROM "orders" WHERE "orders"."isPaid"
  /// ```
  ///
  /// - Parameters:
  ///   - expression: A closure that returns the column to average.
  ///   - filter: An optional additional filter clause (FILTER WHERE) to apply to the aggregation.
  /// - Returns: A select statement that returns the average as `Double?`.
  @inlinable
  public func avg<Value>(
    of expression: (From.TableColumns) -> some QueryExpression<Value>
  ) -> Select<Double?, From, ()>
  where Value: _OptionalPromotable, Value._Optionalized.Wrapped: Numeric {
    _aggregateSelect(of: expression) { $0.avg() }
  }

  /// Computes the average of a numeric column for rows matching the WHERE clause with a filter.
  ///
  /// ```swift
  /// Order.where { $0.createdAt > date }.avg(of: { $0.amount }, filter: { $0.isPaid })
  /// // SELECT AVG("orders"."amount") FILTER (WHERE "orders"."isPaid") FROM "orders" WHERE ...
  /// ```
  ///
  /// - Parameters:
  ///   - expression: A closure that returns the column to average.
  ///   - filter: A FILTER clause to apply to the aggregation.
  /// - Returns: A select statement that returns the average as `Double?`.
  @inlinable
  public func avg<Value, Filter: QueryExpression<Bool>>(
    of expression: (From.TableColumns) -> some QueryExpression<Value>,
    filter: @escaping (From.TableColumns) -> Filter
  ) -> Select<Double?, From, ()>
  where Value: _OptionalPromotable, Value._Optionalized.Wrapped: Numeric {
    _aggregateSelect(of: expression, filter: filter) { $0.avg(filter: $1) }
  }
}
