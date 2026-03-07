extension Select {
  /// Creates a new select statement from this one by appending the given column to its `GROUP BY`
  /// clause.
  ///
  /// - Parameter grouping: A closure that returns a column to group by from this select's tables.
  /// - Returns: A new select statement that groups by the given column.
  @_disfavoredOverload
  public func group<C: QueryExpression, each J: Table>(
    by grouping: (From.TableColumns, repeat (each J).TableColumns) -> C
  ) -> Self where Joins == (repeat each J) {
    _groupPacks(by: grouping)
  }

  /// Creates a new select statement from this one by appending the given columns to its `GROUP BY`
  /// clause.
  ///
  /// - Parameter grouping: A closure that returns a column to group by from this select's tables.
  /// - Returns: A new select statement that groups by the given column.
  @_disfavoredOverload
  public func group<
    C1: QueryExpression,
    C2: QueryExpression,
    each C3: QueryExpression,
    each J: Table
  >(
    by grouping: (From.TableColumns, repeat (each J).TableColumns) -> (C1, C2, repeat each C3)
  ) -> Self where Joins == (repeat each J) {
    _groupPacks(by: grouping)
  }

  /// Creates a new select statement from this one by appending the given column to its `GROUP BY`
  /// clause.
  ///
  /// - Parameter grouping: A closure that returns a column to group by from this select's tables.
  /// - Returns: A new select statement that groups by the given column.
  public func group<C: QueryExpression>(
    by grouping: (From.TableColumns, Joins.TableColumns) -> C
  ) -> Self where Joins: Table {
    _groupPack(by: grouping)
  }

  /// Creates a new select statement from this one by appending the given columns to its `GROUP BY`
  /// clause.
  ///
  /// - Parameter grouping: A closure that returns a column to group by from this select's tables.
  /// - Returns: A new select statement that groups by the given column.
  public func group<
    C1: QueryExpression,
    C2: QueryExpression,
    each C3: QueryExpression
  >(
    by grouping: (From.TableColumns, Joins.TableColumns) -> (C1, C2, repeat each C3)
  ) -> Self where Joins: Table {
    _groupPack(by: grouping)
  }

  private func _groupPacks<
    each C: QueryExpression,
    each J: Table
  >(
    by grouping: (From.TableColumns, repeat (each J).TableColumns) -> (repeat each C)
  ) -> Self where Joins == (repeat each J) {
    var select = self
    select.group
      .append(
        contentsOf: Array(repeat each grouping(From.columns, repeat (each J).columns))
      )
    return select
  }

  private func _groupPack<each C: QueryExpression>(
    by grouping: (From.TableColumns, Joins.TableColumns) -> (repeat each C)
  ) -> Self where Joins: Table {
    var select = self
    select.group
      .append(
        contentsOf: Array(repeat each grouping(From.columns, Joins.columns))
      )
    return select
  }
}
