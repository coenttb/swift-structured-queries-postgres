import StructuredQueriesCore

extension Where {
    /// A select statement for the sum of an expression from the filtered table.
    ///
    /// ```swift
    /// Order.sum { $0.amount }
    /// // SELECT SUM("orders"."amount") FROM "orders"
    ///
    /// Order.where { $0.status == "completed" }.sum { $0.amount }
    /// // SELECT SUM("orders"."amount") FROM "orders" WHERE "orders"."status" = 'completed'
    /// ```
    ///
    /// - Parameter expression: A closure that takes table columns and returns an expression to sum.
    /// - Returns: A select statement that selects the sum of the expression.
    public func sum<Value>(
        of expression: (From.TableColumns) -> some QueryExpression<Value>
    ) -> Select<Value._Optionalized.Wrapped?, From, ()>
    where
        Value: _OptionalPromotable,
        Value._Optionalized.Wrapped: Numeric,
        Value._Optionalized.Wrapped: QueryRepresentable
    {
        let expr = expression(From.columns)
        return asSelect().select { _ in expr.sum() }
    }

    /// A select statement for the sum of an expression from the filtered table with a filter clause.
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
    public func sum<Value, Filter: QueryExpression<Bool>>(
        of expression: (From.TableColumns) -> some QueryExpression<Value>,
        filter: @escaping (From.TableColumns) -> Filter
    ) -> Select<Value._Optionalized.Wrapped?, From, ()>
    where
        Value: _OptionalPromotable,
        Value._Optionalized.Wrapped: Numeric,
        Value._Optionalized.Wrapped: QueryRepresentable
    {
        let expr = expression(From.columns)
        let filterExpr = filter(From.columns)
        return asSelect().select { _ in expr.sum(filter: filterExpr) }
    }

    /// A select statement for the sum of a column from the filtered table (KeyPath syntax).
    ///
    /// ```swift
    /// Order.sum(of: \.amount)
    /// // SELECT SUM("orders"."amount") FROM "orders"
    /// ```
    ///
    /// - Parameter keyPath: A key path to a column expression to sum.
    /// - Returns: A select statement that selects the sum of the column.
    public func sum<Value>(
        of keyPath: KeyPath<From.TableColumns, some QueryExpression<Value>>
    ) -> Select<Value._Optionalized.Wrapped?, From, ()>
    where
        Value: _OptionalPromotable,
        Value._Optionalized.Wrapped: Numeric,
        Value._Optionalized.Wrapped: QueryRepresentable
    {
        sum(of: { $0[keyPath: keyPath] })
    }

    /// A select statement for the sum of a column from the filtered table with a filter clause (KeyPath syntax).
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
    public func sum<Value, Filter: QueryExpression<Bool>>(
        of keyPath: KeyPath<From.TableColumns, some QueryExpression<Value>>,
        filter: @escaping (From.TableColumns) -> Filter
    ) -> Select<Value._Optionalized.Wrapped?, From, ()>
    where
        Value: _OptionalPromotable,
        Value._Optionalized.Wrapped: Numeric,
        Value._Optionalized.Wrapped: QueryRepresentable
    {
        sum(of: { $0[keyPath: keyPath] }, filter: filter)
    }
}
