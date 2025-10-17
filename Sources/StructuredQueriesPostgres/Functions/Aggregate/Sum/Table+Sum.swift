import StructuredQueriesCore

extension Table {
    /// A select statement for the sum of an expression from this table.
    ///
    /// ```swift
    /// Order.sum { $0.amount }
    /// // SELECT SUM("orders"."amount") FROM "orders"
    /// ```
    ///
    /// - Parameter expression: A closure that takes table columns and returns an expression to sum.
    /// - Returns: A select statement that selects the sum of the expression.
    public static func sum<Value>(
        of expression: (TableColumns) -> some QueryExpression<Value>
    ) -> Select<Value._Optionalized.Wrapped?, Self, ()>
    where
        Value: _OptionalPromotable,
        Value._Optionalized.Wrapped: Numeric,
        Value._Optionalized.Wrapped: QueryRepresentable
    {
        Where().sum(of: expression)
    }

    /// A select statement for the sum of an expression from this table with a filter clause.
    ///
    /// ```swift
    /// Order.sum(of: { $0.amount }, filter: { $0.status == "completed" })
    /// // SELECT SUM("orders"."amount") FILTER (WHERE "orders"."status" = 'completed') FROM "orders"
    /// ```
    ///
    /// - Parameters:
    ///   - expression: A closure that takes table columns and returns an expression to sum.
    ///   - filter: A `FILTER` clause to apply to the aggregation.
    /// - Returns: A select statement that selects the sum of the expression.
    public static func sum<Value, Filter: QueryExpression<Bool>>(
        of expression: (TableColumns) -> some QueryExpression<Value>,
        filter: @escaping (TableColumns) -> Filter
    ) -> Select<Value._Optionalized.Wrapped?, Self, ()>
    where
        Value: _OptionalPromotable,
        Value._Optionalized.Wrapped: Numeric,
        Value._Optionalized.Wrapped: QueryRepresentable
    {
        Where().sum(of: expression, filter: filter)
    }

    /// A select statement for the sum of a column from this table (KeyPath syntax).
    ///
    /// ```swift
    /// Order.sum(of: \.amount)
    /// // SELECT SUM("orders"."amount") FROM "orders"
    /// ```
    ///
    /// - Parameter keyPath: A key path to a column expression to sum.
    /// - Returns: A select statement that selects the sum of the column.
    public static func sum<Value>(
        of keyPath: KeyPath<TableColumns, some QueryExpression<Value>>
    ) -> Select<Value._Optionalized.Wrapped?, Self, ()>
    where
        Value: _OptionalPromotable,
        Value._Optionalized.Wrapped: Numeric,
        Value._Optionalized.Wrapped: QueryRepresentable
    {
        Where().sum(of: keyPath)
    }

    /// A select statement for the sum of a column from this table with a filter clause (KeyPath syntax).
    ///
    /// ```swift
    /// Order.sum(of: \.amount, filter: { $0.status == "completed" })
    /// // SELECT SUM("orders"."amount") FILTER (WHERE "orders"."status" = 'completed') FROM "orders"
    /// ```
    ///
    /// - Parameters:
    ///   - keyPath: A key path to a column expression to sum.
    ///   - filter: A `FILTER` clause to apply to the aggregation.
    /// - Returns: A select statement that selects the sum of the column.
    public static func sum<Value, Filter: QueryExpression<Bool>>(
        of keyPath: KeyPath<TableColumns, some QueryExpression<Value>>,
        filter: @escaping (TableColumns) -> Filter
    ) -> Select<Value._Optionalized.Wrapped?, Self, ()>
    where
        Value: _OptionalPromotable,
        Value._Optionalized.Wrapped: Numeric,
        Value._Optionalized.Wrapped: QueryRepresentable
    {
        Where().sum(of: keyPath, filter: filter)
    }
}
