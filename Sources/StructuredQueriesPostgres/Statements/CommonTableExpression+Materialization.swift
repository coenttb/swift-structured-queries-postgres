import StructuredQueriesCore

// MARK: - Result Builder Extension for Materialized CTEs

extension CommonTableExpressionBuilder {
    /// Build expression overload that extracts materialization hint from MaterializedSelect.
    ///
    /// This allows materialized CTEs to be used in the WITH clause:
    /// ```swift
    /// With {
    ///     User.where { $0.isActive }.materialized()
    /// } query: { ... }
    /// ```
    public static func buildExpression<CTETable: Table, Base: PartialSelectStatement<CTETable>>(
        _ expression: MaterializedSelect<Base>
    ) -> CommonTableExpressionClause {
        CommonTableExpressionClause(
            tableName: "\(CTETable.self)",
            select: expression.base.query,
            materialization: expression.materialization
        )
    }
}
