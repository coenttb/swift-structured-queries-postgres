import StructuredQueriesCore

// MARK: - SQL Operators for ColumnGroup

extension ColumnGroup {
    /// Returns a predicate expression indicating whether two column groups are equal.
    ///
    /// This method enables tuple/row comparison for column groups in WHERE clauses.
    ///
    /// ```swift
    /// Item.where { $0.status.eq(Status()) }
    /// // SELECT … WHERE ("items"."isOutOfStock", "items"."isOnBackOrder") = (false, false)
    /// ```
    ///
    /// - Parameter other: A column group value to compare this one to.
    /// - Returns: A predicate expression.
    public func eq(_ other: Values) -> some QueryExpression<Bool> {
        SQLQueryExpression<Bool>(
            "(\(queryFragment)) = (\(Values(queryOutput: other).queryFragment))")
    }
}
