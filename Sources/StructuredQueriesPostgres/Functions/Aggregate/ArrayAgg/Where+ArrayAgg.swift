import StructuredQueriesCore

extension Where {
  /// Aggregates values into an array for rows matching the WHERE clause.
  ///
  /// ```swift
  /// User.where { $0.isActive }.arrayAgg { $0.name }
  /// // SELECT ARRAY_AGG("users"."name") FROM "users" WHERE "users"."is_active"
  /// ```
  ///
  /// - Parameter expression: A closure that returns the column to aggregate into an array.
  /// - Returns: A select statement that returns an array of values.
  @inlinable
  public func arrayAgg(
    of expression: (From.TableColumns) -> some QueryExpression
  ) -> Select<String?, From, ()> {
    _aggregateSelect(of: expression) { $0.arrayAgg() }
  }

  /// Aggregates values into an array with a filter for rows matching the WHERE clause.
  ///
  /// ```swift
  /// User.where { $0.createdAt > date }.arrayAgg(of: { $0.name }, filter: { $0.isActive })
  /// // SELECT ARRAY_AGG("users"."name") FILTER (WHERE "users"."is_active") FROM "users" WHERE ...
  /// ```
  ///
  /// - Parameters:
  ///   - expression: A closure that returns the column to aggregate into an array.
  ///   - filter: A FILTER clause to apply to the aggregation.
  /// - Returns: A select statement that returns an array of values.
  @inlinable
  public func arrayAgg<Expr: QueryExpression, Filter: QueryExpression<Bool>>(
    of expression: (From.TableColumns) -> Expr,
    filter: @escaping (From.TableColumns) -> Filter
  ) -> Select<String?, From, ()> {
    asSelect()
      .select { _ in
        expression(From.columns).arrayAgg(filter: filter(From.columns))
      }
  }
}
