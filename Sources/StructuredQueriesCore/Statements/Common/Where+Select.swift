extension Where {
  /// A select statement for a column of the filtered table.
  ///
  /// - Parameter selection: A key path to a column to select.
  /// - Returns: A select statement that selects the given column.
  public func select<C: QueryExpression>(
    _ selection: KeyPath<From.TableColumns, C>
  ) -> Select<C.QueryValue, From, ()>
  where C.QueryValue: QueryRepresentable {
    asSelect().select(selection)
  }

  /// A select statement for a column of the filtered table.
  ///
  /// - Parameter selection: A closure that selects a result column from the filtered table.
  /// - Returns: A select statement that selects the given column.
  public func select<C: QueryExpression>(
    _ selection: (From.TableColumns) -> C
  ) -> Select<C.QueryValue, From, ()>
  where C.QueryValue: QueryRepresentable {
    asSelect().select(selection)
  }

  /// A select statement for columns of the filtered table.
  ///
  /// - Parameter selection: A closure that selects result columns from the filtered table.
  /// - Returns: A select statement that selects the given columns.
  public func select<C1: QueryExpression, C2: QueryExpression, each C3: QueryExpression>(
    _ selection: (From.TableColumns) -> (C1, C2, repeat each C3)
  ) -> Select<(C1.QueryValue, C2.QueryValue, repeat (each C3).QueryValue), From, ()>
  where
    C1.QueryValue: QueryRepresentable,
    C2.QueryValue: QueryRepresentable,
    repeat (each C3).QueryValue: QueryRepresentable
  {
    asSelect().select(selection)
  }

  /// A distinct select statement for the filtered table.
  ///
  /// - Parameter isDistinct: Whether or not to `SELECT DISTINCT`.
  /// - Returns: A select statement with a `DISTINCT` clause determined by `isDistinct`.
  public func distinct(_ isDistinct: Bool = true) -> SelectOf<From> {
    asSelect().distinct(isDistinct)
  }

  /// A select statement with `DISTINCT ON` for the filtered table.
  ///
  /// PostgreSQL-specific feature that returns the first row of each group determined by the
  /// given expressions. Requires an `ORDER BY` clause to determine which row is "first".
  ///
  /// - Parameter expressions: A result builder closure that returns expressions to use for determining distinct groups.
  /// - Returns: A select statement with a `DISTINCT ON` clause.
  public func distinct(
    @QueryFragmentBuilder<()>
    on expressions: (From.TableColumns) -> [QueryFragment]
  ) -> SelectOf<From> {
    asSelect().distinct(on: expressions)
  }
}
