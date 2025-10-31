import StructuredQueriesCore

extension Where {
  /// Internal helper for creating aggregate select statements from filtered tables without a filter clause.
  ///
  /// This method provides shared implementation for all aggregate functions (MIN, MAX, SUM, AVG, etc.).
  /// It reduces code duplication while maintaining type safety and performance through inlining.
  ///
  /// - Parameters:
  ///   - expression: A closure that takes table columns and returns an expression to aggregate.
  ///   - transform: A closure that applies the specific aggregate function (min, max, sum, etc.) to the expression.
  /// - Returns: A select statement that selects the aggregated result from the filtered table.
  @usableFromInline
  internal func _aggregateSelect<Value, Result, Expr: QueryExpression<Value>>(
    of expression: (From.TableColumns) -> Expr,
    applying transform: (Expr) -> some QueryExpression<Result>
  ) -> Select<Result, From, ()> where Result: QueryRepresentable {
    let expr = expression(From.columns)
    return asSelect().select { _ in transform(expr) }
  }

  /// Internal helper for creating aggregate select statements from filtered tables with a filter clause.
  ///
  /// This method provides shared implementation for all aggregate functions with FILTER support.
  /// It reduces code duplication while maintaining type safety and performance through inlining.
  ///
  /// - Parameters:
  ///   - expression: A closure that takes table columns and returns an expression to aggregate.
  ///   - filter: A closure that returns a boolean expression for the FILTER clause.
  ///   - transform: A closure that applies the specific aggregate function with filter to the expression.
  /// - Returns: A select statement that selects the aggregated result with filter applied from the filtered table.
  @usableFromInline
  internal func _aggregateSelect<
    Value, Result, Expr: QueryExpression<Value>, Filter: QueryExpression<Bool>
  >(
    of expression: (From.TableColumns) -> Expr,
    filter: @escaping (From.TableColumns) -> Filter,
    applying transform: (Expr, Filter) -> some QueryExpression<Result>
  ) -> Select<Result, From, ()> where Result: QueryRepresentable {
    asSelect()
      .select { _ in
        transform(expression(From.columns), filter(From.columns))
      }
  }
}
