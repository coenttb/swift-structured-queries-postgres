import StructuredQueriesCore

extension Where {
  /// Aggregates values into a JSONB array for rows matching the WHERE clause.
  ///
  /// ```swift
  /// User.where { $0.isActive }.jsonbAgg { $0.name }
  /// // SELECT JSONB_AGG("users"."name") FROM "users" WHERE "users"."is_active"
  /// ```
  ///
  /// - Parameter expression: A closure that returns the column to aggregate into a JSONB array.
  /// - Returns: A select statement that returns a JSONB array of values.
  @inlinable
  public func jsonbAgg(
    of expression: (From.TableColumns) -> some QueryExpression
  ) -> Select<String?, From, ()> {
    _aggregateSelect(of: expression) { $0.jsonbAgg() }
  }

  /// Aggregates values into a JSONB array with a filter for rows matching the WHERE clause.
  ///
  /// ```swift
  /// User.where { $0.createdAt > date }.jsonbAgg(of: { $0.name }, filter: { $0.isActive })
  /// // SELECT JSONB_AGG("users"."name") FILTER (WHERE "users"."is_active") FROM "users" WHERE ...
  /// ```
  ///
  /// - Parameters:
  ///   - expression: A closure that returns the column to aggregate into a JSONB array.
  ///   - filter: A FILTER clause to apply to the aggregation.
  /// - Returns: A select statement that returns a JSONB array of values.
  @inlinable
  public func jsonbAgg<Expr: QueryExpression, Filter: QueryExpression<Bool>>(
    of expression: (From.TableColumns) -> Expr,
    filter: @escaping (From.TableColumns) -> Filter
  ) -> Select<String?, From, ()> {
    asSelect()
      .select { _ in
        expression(From.columns).jsonbAgg(filter: filter(From.columns))
      }
  }
}
