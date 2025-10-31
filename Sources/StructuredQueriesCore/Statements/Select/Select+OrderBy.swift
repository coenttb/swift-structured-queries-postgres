extension Select {
  /// Creates a new select statement from this one by appending a column to its `ORDER BY` clause.
  ///
  /// - Parameter ordering: A key path to a column to order by.
  /// - Returns: A new select statement that appends the given column to its `ORDER BY` clause.
  public func order(by ordering: KeyPath<From.TableColumns, some QueryExpression>) -> Self {
    var select = self
    select.order.append(From.columns[keyPath: ordering].queryFragment)
    return select
  }

  /// Creates a new select statement from this one by appending columns to its `ORDER BY` clause.
  ///
  /// - Parameter ordering: A result builder closure that returns columns to order by.
  /// - Returns: A new select statement that appends the returned columns to its `ORDER BY` clause.
  public func order<each J: Table>(
    @QueryFragmentBuilder<()>
    by ordering: (From.TableColumns, repeat (each J).TableColumns) -> [QueryFragment]
  ) -> Self
  where Joins == (repeat each J) {
    var select = self
    select.order.append(contentsOf: ordering(From.columns, repeat (each J).columns))
    return select
  }

  /// Creates a new select statement from this one by appending columns to its `ORDER BY` clause.
  ///
  /// - Parameter ordering: A result builder closure that returns columns to order by.
  /// - Returns: A new select statement that appends the returned columns to its `ORDER BY` clause.
  public func order(
    @QueryFragmentBuilder<()>
    by ordering: (From.TableColumns, Joins.TableColumns) -> [QueryFragment]
  ) -> Self
  where Joins: Table {
    var select = self
    select.order.append(contentsOf: ordering(From.columns, Joins.columns))
    return select
  }
}
