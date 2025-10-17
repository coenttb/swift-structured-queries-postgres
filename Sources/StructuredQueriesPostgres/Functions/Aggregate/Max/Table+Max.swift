import StructuredQueriesCore

extension Table {
    /// A select statement for the maximum of an expression from this table.
    ///
    /// ```swift
    /// Order.max { $0.amount }
    /// // SELECT max("orders"."amount") FROM "orders"
    ///
    /// // KeyPath syntax also works (Swift 5.2+):
    /// Order.max(of: \.amount)
    /// ```
    ///
    /// - Parameter expression: A closure that takes table columns and returns an expression to find the maximum of.
    /// - Returns: A select statement that selects the maximum of the expression.
    public static func max<Value>(
        of expression: (TableColumns) -> some QueryExpression<Value>
    ) -> Select<Value._Optionalized.Wrapped?, Self, ()>
    where
        Value: QueryBindable & _OptionalPromotable,
        Value._Optionalized.Wrapped: QueryRepresentable
    {
        Self.all
            .asSelect()
            .select { _ in
                expression(columns).max()
            }
    }

    /// A select statement for the maximum of an expression from this table with a filter clause.
    ///
    /// ```swift
    /// Order.max(of: { $0.amount }, filter: { $0.status == "completed" })
    /// // SELECT max("orders"."amount") FILTER (WHERE "orders"."status" = 'completed') FROM "orders"
    ///
    /// // KeyPath syntax also works (Swift 5.2+):
    /// Order.max(of: \.amount, filter: { $0.status == "completed" })
    /// ```
    ///
    /// - Parameters:
    ///   - expression: A closure that takes table columns and returns an expression to find the maximum of.
    ///   - filter: A `FILTER` clause to apply to the aggregation.
    /// - Returns: A select statement that selects the maximum of the expression.
    public static func max<Value, Filter: QueryExpression<Bool>>(
        of expression: (TableColumns) -> some QueryExpression<Value>,
        filter: @escaping (TableColumns) -> Filter
    ) -> Select<Value._Optionalized.Wrapped?, Self, ()>
    where
        Value: QueryBindable & _OptionalPromotable,
        Value._Optionalized.Wrapped: QueryRepresentable
    {
        Self.all
            .asSelect()
            .select { _ in
                expression(columns).max(filter: filter(columns))
            }
    }
}
