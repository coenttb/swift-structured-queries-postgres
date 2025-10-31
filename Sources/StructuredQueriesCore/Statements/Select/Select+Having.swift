extension Select {
  /// Creates a new select statement from this one by appending a predicate to its `HAVING` clause.
  ///
  /// - Parameter predicate: A closure that produces a Boolean query expression from this select's
  ///   tables.
  /// - Returns: A new select statement that appends the given predicate to its `HAVING` clause.
  @_disfavoredOverload
  public func having<each J: Table>(
    _ predicate: (From.TableColumns, repeat (each J).TableColumns) -> some QueryExpression<
      some _OptionalPromotable<Bool?>
    >
  ) -> Self
  where Joins == (repeat each J) {
    var select = self
    select.having.append(predicate(From.columns, repeat (each J).columns).queryFragment)
    return select
  }

  /// Creates a new select statement from this one by appending a predicate to its `HAVING` clause.
  ///
  /// - Parameter predicate: A result builder closure that returns a Boolean expression to filter
  ///   by.
  /// - Returns: A new select statement that appends the given predicate to its `HAVING` clause.
  public func having<each J: Table>(
    @QueryFragmentBuilder<Bool>
    _ predicate: (From.TableColumns, repeat (each J).TableColumns) -> [QueryFragment]
  ) -> Self
  where Joins == (repeat each J) {
    var select = self
    select.having.append(contentsOf: predicate(From.columns, repeat (each J).columns))
    return select
  }

  /// Creates a new select statement from this one by appending a predicate to its `HAVING` clause.
  ///
  /// - Parameter predicate: A closure that produces a Boolean query expression from this select's
  ///   tables.
  /// - Returns: A new select statement that appends the given predicate to its `HAVING` clause.
  @_disfavoredOverload
  public func having(
    _ predicate: (From.TableColumns, Joins.TableColumns) -> some QueryExpression<
      some _OptionalPromotable<Bool?>
    >
  ) -> Self
  where Joins: Table {
    var select = self
    select.having.append(predicate(From.columns, Joins.columns).queryFragment)
    return select
  }

  /// Creates a new select statement from this one by appending a predicate to its `HAVING` clause.
  ///
  /// - Parameter predicate: A result builder closure that returns a Boolean expression to filter
  ///   by.
  /// - Returns: A new select statement that appends the given predicate to its `HAVING` clause.
  public func having(
    @QueryFragmentBuilder<Bool>
    _ predicate: (From.TableColumns, Joins.TableColumns) -> [QueryFragment]
  ) -> Self
  where Joins: Table {
    var select = self
    select.having.append(contentsOf: predicate(From.columns, Joins.columns))
    return select
  }

  /// Creates a new select statement from this one by combining its `HAVING` predicates with
  /// additional predicates using `OR` logic.
  ///
  /// This method allows building complex `HAVING` conditions with `OR` semantics, similar to
  /// how `.or()` works for `WHERE` clauses.
  ///
  /// - Parameter predicates: An array of query fragments representing additional `HAVING` conditions.
  /// - Returns: A new select statement with the combined `HAVING` clause.
  public func orHaving(_ predicates: [QueryFragment]) -> Self {
    var select = self
    if select.having.isEmpty {
      select.having = predicates
    } else {
      select.having = [
        """
        (\(select.having.joined(separator: " AND ")) \
        OR \
        \(predicates.joined(separator: " AND ")))
        """
      ]
    }
    return select
  }
}
