import StructuredQueriesCore

extension Table {
  /// Aggregates values into an array for the entire table.
  ///
  /// ```swift
  /// User.arrayAgg { $0.name }
  /// // SELECT ARRAY_AGG("users"."name") FROM "users"
  /// ```
  ///
  /// - Parameter expression: A closure that returns the column to aggregate into an array.
  /// - Returns: A select statement that returns an array of values.
  @inlinable
  public static func arrayAgg(
    of expression: (TableColumns) -> some QueryExpression
  ) -> Select<String?, Self, ()> {
    _aggregateSelect(of: expression) { $0.arrayAgg() }
  }

  /// Aggregates values into an array with a filter for the entire table.
  ///
  /// ```swift
  /// User.arrayAgg(of: { $0.name }, filter: { $0.isActive })
  /// // SELECT ARRAY_AGG("users"."name") FILTER (WHERE "users"."is_active") FROM "users"
  /// ```
  ///
  /// - Parameters:
  ///   - expression: A closure that returns the column to aggregate into an array.
  ///   - filter: A FILTER clause to apply to the aggregation.
  /// - Returns: A select statement that returns an array of values.
  @inlinable
  public static func arrayAgg<Expr: QueryExpression, Filter: QueryExpression<Bool>>(
    of expression: (TableColumns) -> Expr,
    filter: @escaping (TableColumns) -> Filter
  ) -> Select<String?, Self, ()> {
    Self.all
      .asSelect()
      .select { _ in
        expression(columns).arrayAgg(filter: filter(columns))
      }
  }
}
