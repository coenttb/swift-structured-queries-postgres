import StructuredQueriesCore

extension Select {
  /// Creates a new select statement from this one by appending a sum aggregate to its selection.
  ///
  /// ```swift
  /// Order.select().sum { $0.amount }
  /// // SELECT SUM("orders"."amount") FROM "orders"
  /// ```
  ///
  /// - Parameter expression: A closure that takes table columns and returns an expression to sum.
  /// - Returns: A new select statement that includes the sum of the expression.
  public func sum<Value>(
    of expression: (From.TableColumns) -> some QueryExpression<Value>
  ) -> Select<Value._Optionalized.Wrapped?, From, ()>
  where
    Columns == (), Joins == (),
    Value: _OptionalPromotable,
    Value._Optionalized.Wrapped: Numeric,
    Value._Optionalized.Wrapped: QueryRepresentable
  {
    let expr = expression(From.columns)
    return select { _ in expr.sum() }
  }

  /// Creates a new select statement from this one by appending a sum aggregate to its selection (with joins).
  ///
  /// - Parameter expression: A closure that takes table columns and returns an expression to sum.
  /// - Returns: A new select statement that includes the sum of the expression.
  public func sum<Value, each J: Table>(
    of expression: (From.TableColumns, repeat (each J).TableColumns) -> some QueryExpression<Value>
  ) -> Select<Value._Optionalized.Wrapped?, From, (repeat each J)>
  where
    Columns == (), Joins == (repeat each J),
    Value: _OptionalPromotable,
    Value._Optionalized.Wrapped: Numeric,
    Value._Optionalized.Wrapped: QueryRepresentable
  {
    let expr = expression(From.columns, repeat (each J).columns)
    return select { _ in expr.sum() }
  }

  /// Creates a new select statement from this one by appending a sum aggregate to its selection (with existing columns).
  ///
  /// - Parameter expression: A closure that takes table columns and returns an expression to sum.
  /// - Returns: A new select statement that includes the sum of the expression.
  public func sum<Value, each C: QueryRepresentable, each J: Table>(
    of expression: (From.TableColumns, repeat (each J).TableColumns) -> some QueryExpression<Value>
  ) -> Select<(repeat each C, Value._Optionalized.Wrapped?), From, (repeat each J)>
  where
    Columns == (repeat each C), Joins == (repeat each J),
    Value: _OptionalPromotable,
    Value._Optionalized.Wrapped: Numeric,
    Value._Optionalized.Wrapped: QueryRepresentable
  {
    let expr = expression(From.columns, repeat (each J).columns)
    return select { _ in expr.sum() }
  }

  /// Creates a new select statement from this one by appending a sum aggregate to its selection (with single join).
  ///
  /// - Parameter expression: A closure that takes table columns and returns an expression to sum.
  /// - Returns: A new select statement that includes the sum of the expression.
  public func sum<Value>(
    of expression: (From.TableColumns, Joins.TableColumns) -> some QueryExpression<Value>
  ) -> Select<Value._Optionalized.Wrapped?, From, Joins>
  where
    Columns == (), Joins: Table,
    Value: _OptionalPromotable,
    Value._Optionalized.Wrapped: Numeric,
    Value._Optionalized.Wrapped: QueryRepresentable
  {
    let expr = expression(From.columns, Joins.columns)
    return select { _, _ in expr.sum() }
  }

  /// Creates a new select statement from this one by appending a sum aggregate to its selection (with single join and existing columns).
  ///
  /// - Parameter expression: A closure that takes table columns and returns an expression to sum.
  /// - Returns: A new select statement that includes the sum of the expression.
  public func sum<Value, each C: QueryRepresentable>(
    of expression: (From.TableColumns, Joins.TableColumns) -> some QueryExpression<Value>
  ) -> Select<(repeat each C, Value._Optionalized.Wrapped?), From, Joins>
  where
    Columns == (repeat each C), Joins: Table,
    Value: _OptionalPromotable,
    Value._Optionalized.Wrapped: Numeric,
    Value._Optionalized.Wrapped: QueryRepresentable
  {
    let expr = expression(From.columns, Joins.columns)
    return select { _, _ in expr.sum() }
  }
}
