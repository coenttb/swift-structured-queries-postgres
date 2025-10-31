extension Table {
  /// A select statement for a column of this table.
  ///
  /// See <doc:SelectStatements> for more info.
  ///
  /// - Parameter selection: A key path to a column to select.
  /// - Returns: A select statement that selects the given column.
  public static func select<ResultColumn: QueryExpression>(
    _ selection: KeyPath<TableColumns, ResultColumn>
  ) -> Select<ResultColumn.QueryValue, Self, ()>
  where ResultColumn.QueryValue: QueryRepresentable {
    Where().select(selection)
  }

  /// A select statement for a column of this table.
  ///
  /// See <doc:SelectStatements> for more info.
  ///
  /// - Parameter selection: A closure that selects a result column from this table's columns.
  /// - Returns: A select statement that selects the given column.
  public static func select<ResultColumn: QueryExpression>(
    _ selection: (TableColumns) -> ResultColumn
  ) -> Select<ResultColumn.QueryValue, Self, ()>
  where ResultColumn.QueryValue: QueryRepresentable {
    Where().select(selection)
  }

  /// A select statement for columns of this table.
  ///
  /// See <doc:SelectStatements> for more info.
  ///
  /// - Parameter selection: A closure that selects result columns from this table's columns.
  /// - Returns: A select statement that selects the given columns.
  public static func select<
    C1: QueryExpression,
    C2: QueryExpression,
    each C3: QueryExpression
  >(
    _ selection: (TableColumns) -> (C1, C2, repeat each C3)
  ) -> Select<(C1.QueryValue, C2.QueryValue, repeat (each C3).QueryValue), Self, ()>
  where
    C1.QueryValue: QueryRepresentable,
    C2.QueryValue: QueryRepresentable,
    repeat (each C3).QueryValue: QueryRepresentable
  {
    Where().select(selection)
  }

  /// A distinct select statement for this table.
  ///
  /// - Parameter isDistinct: Whether or not to `SELECT DISTINCT`.
  /// - Returns: A select statement with a `DISTINCT` clause determined by `isDistinct`.
  public static func distinct(_ isDistinct: Bool = true) -> SelectOf<Self> {
    Where().distinct(isDistinct)
  }

  /// A select statement with `DISTINCT ON` for this table.
  ///
  /// PostgreSQL-specific feature that returns the first row of each group determined by the
  /// given expressions. Requires an `ORDER BY` clause to determine which row is "first".
  ///
  /// - Parameter expressions: A result builder closure that returns expressions to use for determining distinct groups.
  /// - Returns: A select statement with a `DISTINCT ON` clause.
  public static func distinct(
    @QueryFragmentBuilder<()>
    on expressions: (TableColumns) -> [QueryFragment]
  ) -> SelectOf<Self> {
    Where().distinct(on: expressions)
  }

  /// A select statement for this table joined to another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A select statement that joins the given table.
  public static func join<
    each C: QueryRepresentable,
    F: Table,
    each J: Table
  >(
    _ other: some SelectStatement<(repeat each C), F, (repeat each J)>,
    on constraint: (
      (TableColumns, F.TableColumns, repeat (each J).TableColumns)
    ) -> some QueryExpression<Bool>
  ) -> Select<(repeat each C), Self, (F, repeat each J)> {
    Where().join(other, on: constraint)
  }

  // NB: Optimization
  /// A select statement for this table joined to another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A select statement that joins the given table.
  @_documentation(visibility: private)
  public static func join<each C: QueryRepresentable, F: Table>(
    _ other: some SelectStatement<(repeat each C), F, ()>,
    on constraint: (
      (TableColumns, F.TableColumns)
    ) -> some QueryExpression<Bool>
  ) -> Select<(repeat each C), Self, F> {
    Where().join(other, on: constraint)
  }

  /// A select statement for this table left-joined to another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A select statement that left-joins the given table.
  public static func leftJoin<
    each C: QueryRepresentable,
    F: Table,
    each J: Table
  >(
    _ other: some SelectStatement<(repeat each C), F, (repeat each J)>,
    on constraint: (
      (TableColumns, F.TableColumns, repeat (each J).TableColumns)
    ) -> some QueryExpression<Bool>
  ) -> Select<
    (repeat (each C)._Optionalized),
    Self,
    (F._Optionalized, repeat (each J)._Optionalized)
  > {
    Where().leftJoin(other, on: constraint)
  }

  // NB: Optimization
  /// A select statement for this table left-joined to another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A select statement that left-joins the given table.
  @_documentation(visibility: private)
  public static func leftJoin<each C: QueryRepresentable, F: Table>(
    _ other: some SelectStatement<(repeat each C), F, ()>,
    on constraint: (
      (TableColumns, F.TableColumns)
    ) -> some QueryExpression<Bool>
  ) -> Select<(repeat (each C)._Optionalized), Self, F._Optionalized> {
    Where().leftJoin(other, on: constraint)
  }

  /// A select statement for this table right-joined to another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A select statement that right-joins the given table.
  public static func rightJoin<
    each C: QueryRepresentable,
    F: Table,
    each J: Table
  >(
    _ other: some SelectStatement<(repeat each C), F, (repeat each J)>,
    on constraint: (
      (TableColumns, F.TableColumns, repeat (each J).TableColumns)
    ) -> some QueryExpression<Bool>
  ) -> Select<(repeat each C), Self._Optionalized, (F, repeat each J)> {
    Where<Self>().rightJoin(other, on: constraint)
  }

  // NB: Optimization
  /// A select statement for this table right-joined to another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A select statement that right-joins the given table.
  @_documentation(visibility: private)
  public static func rightJoin<each C: QueryRepresentable, F: Table>(
    _ other: some SelectStatement<(repeat each C), F, ()>,
    on constraint: (
      (TableColumns, F.TableColumns)
    ) -> some QueryExpression<Bool>
  ) -> Select<(repeat each C), Self._Optionalized, F> {
    Where<Self>().rightJoin(other, on: constraint)
  }

  /// A select statement for this table full-joined to another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A select statement that full-joins the given table.
  public static func fullJoin<
    each C: QueryRepresentable,
    F: Table,
    each J: Table
  >(
    _ other: some SelectStatement<(repeat each C), F, (repeat each J)>,
    on constraint: (
      (TableColumns, F.TableColumns, repeat (each J).TableColumns)
    ) -> some QueryExpression<Bool>
  ) -> Select<
    (repeat (each C)._Optionalized),
    Self._Optionalized,
    (F._Optionalized, repeat (each J)._Optionalized)
  > {
    Where<Self>().fullJoin(other, on: constraint)
  }

  // NB: Optimization
  /// A select statement for this table full-joined to another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A select statement that full-joins the given table.
  @_documentation(visibility: private)
  public static func fullJoin<each C: QueryRepresentable, F: Table>(
    _ other: some SelectStatement<(repeat each C), F, ()>,
    on constraint: (
      (TableColumns, F.TableColumns)
    ) -> some QueryExpression<Bool>
  ) -> Select<(repeat (each C)._Optionalized), Self._Optionalized, F._Optionalized> {
    Where<Self>().fullJoin(other, on: constraint)
  }

  /// A select statement for this table grouped by the given column.
  ///
  /// - Parameter grouping: A closure that returns a column to group by from this table's columns.
  /// - Returns: A select statement that groups by the given column.
  public static func group<C: QueryExpression>(
    by grouping: (TableColumns) -> C
  ) -> SelectOf<Self> {
    Where().group(by: grouping)
  }

  /// A select statement for this table grouped by the given columns.
  ///
  /// - Parameter grouping: A closure that returns columns to group by from this table's columns.
  /// - Returns: A select statement that groups by the given column.
  public static func group<
    C1: QueryExpression,
    C2: QueryExpression,
    each C3: QueryExpression
  >(
    by grouping: (TableColumns) -> (C1, C2, repeat each C3)
  ) -> SelectOf<Self> {
    Where().group(by: grouping)
  }

  /// A select statement for this table with the given `HAVING` clause.
  ///
  /// - Parameter predicate: A closure that produces a Boolean query expression from this table's
  ///   columns.
  /// - Returns: A select statement that is filtered by the given predicate.
  public static func having(
    _ predicate: (TableColumns) -> some QueryExpression<some _OptionalPromotable<Bool?>>
  ) -> SelectOf<Self> {
    Where().having(predicate)
  }

  /// A select statement for this table ordered by the given column.
  ///
  /// - Parameter ordering: A key path to a column to order by.
  /// - Returns: A select statement that is ordered by the given column.
  public static func order(
    by ordering: KeyPath<TableColumns, some QueryExpression>
  ) -> SelectOf<Self> {
    Where().order(by: ordering)
  }

  /// A select statement for this table ordered by the given columns.
  ///
  /// - Parameter ordering: A result builder closure that returns columns to order by.
  /// - Returns: A select statement that is ordered by the given columns.
  public static func order(
    @QueryFragmentBuilder<()>
    by ordering: (TableColumns) -> [QueryFragment]
  ) -> SelectOf<Self> {
    Where().order(by: ordering)
  }

  /// A select statement for this table with a limit and optional offset.
  ///
  /// - Parameters:
  ///   - maxLength: A closure that produces a `LIMIT` expression from the filtered table's columns.
  ///   - offset: A closure that produces an `OFFSET` expression from the filtered table's columns.
  /// - Returns: A select statement with a limit and optional offset.
  public static func limit(
    _ maxLength: (TableColumns) -> some QueryExpression<Int>,
    offset: ((TableColumns) -> some QueryExpression<Int>)? = nil
  ) -> SelectOf<Self> {
    Where().limit(maxLength, offset: offset)
  }

  /// A select statement for this table with a limit and optional offset.
  ///
  /// - Parameters:
  ///   - maxLength: An integer limit for the select's `LIMIT` clause.
  ///   - offset: An optional integer offset of the select's `OFFSET` clause.
  /// - Returns: A select statement with a limit and optional offset.
  public static func limit(_ maxLength: Int, offset: Int? = nil) -> SelectOf<Self> {
    Where().limit(maxLength, offset: offset)
  }

}
