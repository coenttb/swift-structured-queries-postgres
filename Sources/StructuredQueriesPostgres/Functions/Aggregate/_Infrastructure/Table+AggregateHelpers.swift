import StructuredQueriesCore

extension Table {
    /// Internal helper for creating aggregate select statements without a filter.
    ///
    /// This method provides shared implementation for all aggregate functions (MIN, MAX, SUM, AVG, etc.).
    /// It reduces code duplication while maintaining type safety and performance through inlining.
    ///
    /// - Parameters:
    ///   - expression: A closure that takes table columns and returns an expression to aggregate.
    ///   - transform: A closure that applies the specific aggregate function (min, max, sum, etc.) to the expression.
    /// - Returns: A select statement that selects the aggregated result.
    @usableFromInline
    internal static func _aggregateSelect<Value, Result, Expr: QueryExpression<Value>>(
        of expression: (TableColumns) -> Expr,
        applying transform: (Expr) -> some QueryExpression<Result>
    ) -> Select<Result, Self, ()> where Result: QueryRepresentable {
        Self.all
            .asSelect()
            .select { _ in
                transform(expression(columns))
            }
    }

    /// Internal helper for creating aggregate select statements with a filter clause.
    ///
    /// This method provides shared implementation for all aggregate functions with FILTER support.
    /// It reduces code duplication while maintaining type safety and performance through inlining.
    ///
    /// - Parameters:
    ///   - expression: A closure that takes table columns and returns an expression to aggregate.
    ///   - filter: A closure that returns a boolean expression for the FILTER clause.
    ///   - transform: A closure that applies the specific aggregate function with filter to the expression.
    /// - Returns: A select statement that selects the aggregated result with filter applied.
    @usableFromInline
    internal static func _aggregateSelect<Value, Result, Expr: QueryExpression<Value>, Filter: QueryExpression<Bool>>(
        of expression: (TableColumns) -> Expr,
        filter: @escaping (TableColumns) -> Filter,
        applying transform: (Expr, Filter) -> some QueryExpression<Result>
    ) -> Select<Result, Self, ()> where Result: QueryRepresentable {
        Self.all
            .asSelect()
            .select { _ in
                transform(expression(columns), filter(columns))
            }
    }
}
