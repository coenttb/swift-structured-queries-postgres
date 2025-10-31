extension Select {
  /// Creates a new select statement from this one by appending a predicate to its `WHERE` clause.
  ///
  /// - Parameter keyPath: A key path from this select's table to a Boolean expression to filter by.
  /// - Returns: A new select statement that appends the given predicate to its `WHERE` clause.
  public func `where`(
    _ keyPath: KeyPath<From.TableColumns, some QueryExpression<some _OptionalPromotable<Bool?>>>
  ) -> Self
  where Joins == () {
    var select = self
    select.where.append(From.columns[keyPath: keyPath].queryFragment)
    return select
  }

  /// Creates a new select statement from this one by appending a predicate to its `WHERE` clause.
  ///
  /// - Parameter predicate: A closure that produces a Boolean query expression from this select's
  ///   tables.
  /// - Returns: A new select statement that appends the given predicate to its `WHERE` clause.
  @_disfavoredOverload
  public func `where`<each J: Table>(
    _ predicate: (From.TableColumns, repeat (each J).TableColumns) -> some QueryExpression<
      some _OptionalPromotable<Bool?>
    >
  ) -> Self
  where Joins == (repeat each J) {
    var select = self
    select.where.append(predicate(From.columns, repeat (each J).columns).queryFragment)
    return select
  }

  /// Creates a new select statement from this one by appending a predicate to its `WHERE` clause.
  ///
  /// - Parameter predicate: A result builder closure that returns a Boolean expression to filter
  ///   by.
  /// - Returns: A new select statement that appends the given predicate to its `WHERE` clause.
  public func `where`<each J: Table>(
    @QueryFragmentBuilder<Bool>
    _ predicate: (From.TableColumns, repeat (each J).TableColumns) -> [QueryFragment]
  ) -> Self
  where Joins == (repeat each J) {
    var select = self
    select.where.append(contentsOf: predicate(From.columns, repeat (each J).columns))
    return select
  }

  /// Creates a new select statement from this one by appending a predicate to its `WHERE` clause.
  ///
  /// - Parameter predicate: A closure that produces a Boolean query expression from this select's
  ///   tables.
  /// - Returns: A new select statement that appends the given predicate to its `WHERE` clause.
  @_disfavoredOverload
  public func `where`(
    _ predicate: (From.TableColumns, Joins.TableColumns) -> some QueryExpression<
      some _OptionalPromotable<Bool?>
    >
  ) -> Self
  where Joins: Table {
    var select = self
    select.where.append(predicate(From.columns, Joins.columns).queryFragment)
    return select
  }

  /// Creates a new select statement from this one by appending a predicate to its `WHERE` clause.
  ///
  /// - Parameter predicate: A result builder closure that returns a Boolean expression to filter
  ///   by.
  /// - Returns: A new select statement that appends the given predicate to its `WHERE` clause.
  public func `where`(
    @QueryFragmentBuilder<Bool>
    _ predicate: (From.TableColumns, Joins.TableColumns) -> [QueryFragment]
  ) -> Self
  where Joins: Table {
    var select = self
    select.where.append(contentsOf: predicate(From.columns, Joins.columns))
    return select
  }

  public func and(_ other: Where<From>) -> Self {
    var select = self
    select.where = (select.where + other.predicates).removingDuplicates()
    return select
  }

  public func or(_ other: Where<From>) -> Self {
    var select = self
    if select.where.isEmpty {
      select.where = other.predicates
    } else {
      select.where = [
        """
        (\(select.where.joined(separator: " AND ")) \
        OR \
        \(other.predicates.joined(separator: " AND ")))
        """
      ]
    }
    return select
  }
}
