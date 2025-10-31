import StructuredQueriesCore

extension Table {
  /// Aggregates values into a JSONB array for the entire table.
  ///
  /// ```swift
  /// User.jsonbAgg { $0.name }
  /// // SELECT JSONB_AGG("users"."name") FROM "users"
  /// ```
  ///
  /// - Parameter expression: A closure that returns the column to aggregate into a JSONB array.
  /// - Returns: A select statement that returns a JSONB array of values.
  @inlinable
  public static func jsonbAgg(
    of expression: (TableColumns) -> some QueryExpression
  ) -> Select<String?, Self, ()> {
    _aggregateSelect(of: expression) { $0.jsonbAgg() }
  }

  /// Aggregates values into a JSONB array with a filter for the entire table.
  ///
  /// ```swift
  /// User.jsonbAgg(of: { $0.name }, filter: { $0.isActive })
  /// // SELECT JSONB_AGG("users"."name") FILTER (WHERE "users"."is_active") FROM "users"
  /// ```
  ///
  /// - Parameters:
  ///   - expression: A closure that returns the column to aggregate into a JSONB array.
  ///   - filter: A FILTER clause to apply to the aggregation.
  /// - Returns: A select statement that returns a JSONB array of values.
  @inlinable
  public static func jsonbAgg<Expr: QueryExpression, Filter: QueryExpression<Bool>>(
    of expression: (TableColumns) -> Expr,
    filter: @escaping (TableColumns) -> Filter
  ) -> Select<String?, Self, ()> {
    Self.all
      .asSelect()
      .select { _ in
        expression(columns).jsonbAgg(filter: filter(columns))
      }
  }
}
