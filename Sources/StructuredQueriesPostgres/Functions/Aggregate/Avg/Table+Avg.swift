import StructuredQueriesCore

extension Table {
    /// A select statement for the average of an expression from this table.
    ///
    /// ```swift
    /// Order.avg { $0.amount }
    /// // SELECT AVG("orders"."amount") FROM "orders"
    /// ```
    ///
    /// - Parameter expression: A closure that takes table columns and returns an expression to average.
    /// - Returns: A select statement that selects the average of the expression.
    public static func avg<Value>(
        of expression: (TableColumns) -> some QueryExpression<Value>
    ) -> Select<Double?, Self, ()>
    where Value: _OptionalPromotable, Value._Optionalized.Wrapped: Numeric {
        Where().avg(of: expression)
    }

    /// A select statement for the average of an expression from this table with a filter clause.
    ///
    /// ```swift
    /// Order.avg(of: { $0.amount }, filter: { $0.isPaid })
    /// // SELECT AVG("orders"."amount") FILTER (WHERE "orders"."isPaid") FROM "orders"
    /// ```
    ///
    /// - Parameters:
    ///   - expression: A closure that takes table columns and returns an expression to average.
    ///   - filter: A `FILTER` clause to apply to the aggregation.
    /// - Returns: A select statement that selects the average of the expression.
    public static func avg<Value, Filter: QueryExpression<Bool>>(
        of expression: (TableColumns) -> some QueryExpression<Value>,
        filter: @escaping (TableColumns) -> Filter
    ) -> Select<Double?, Self, ()>
    where Value: _OptionalPromotable, Value._Optionalized.Wrapped: Numeric {
        Where().avg(of: expression, filter: filter)
    }

    /// A select statement for the average of a column from this table (KeyPath syntax).
    ///
    /// ```swift
    /// Order.avg(of: \.amount)
    /// // SELECT AVG("orders"."amount") FROM "orders"
    /// ```
    ///
    /// - Parameter keyPath: A key path to a column expression to average.
    /// - Returns: A select statement that selects the average of the column.
    public static func avg<Value>(
        of keyPath: KeyPath<TableColumns, some QueryExpression<Value>>
    ) -> Select<Double?, Self, ()>
    where Value: _OptionalPromotable, Value._Optionalized.Wrapped: Numeric {
        Where().avg(of: keyPath)
    }

    /// A select statement for the average of a column from this table with a filter clause (KeyPath syntax).
    ///
    /// ```swift
    /// Order.avg(of: \.amount, filter: { $0.isPaid })
    /// // SELECT AVG("orders"."amount") FILTER (WHERE "orders"."isPaid") FROM "orders"
    /// ```
    ///
    /// - Parameters:
    ///   - keyPath: A key path to a column expression to average.
    ///   - filter: A `FILTER` clause to apply to the aggregation.
    /// - Returns: A select statement that selects the average of the column.
    public static func avg<Value, Filter: QueryExpression<Bool>>(
        of keyPath: KeyPath<TableColumns, some QueryExpression<Value>>,
        filter: @escaping (TableColumns) -> Filter
    ) -> Select<Double?, Self, ()>
    where Value: _OptionalPromotable, Value._Optionalized.Wrapped: Numeric {
        Where().avg(of: keyPath, filter: filter)
    }
}
