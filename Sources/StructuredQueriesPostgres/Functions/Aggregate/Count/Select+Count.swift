import StructuredQueriesCore

extension Select {
  /// Creates a new select statement from this one by appending `count(*)` to its selection.
  ///
  /// - Parameter filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A new select statement that selects `count(*)`.
  public func count(
    filter: ((From.TableColumns) -> some QueryExpression<Bool>)? = nil
  ) -> Select<Int, From, ()>
  where Columns == (), Joins == () {
    let filter = filter?(From.columns)
    return select { _ in .count(filter: filter) }
  }

  /// Creates a new select statement from this one by appending `count(*)` to its selection.
  ///
  /// - Parameter filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A new select statement that selects `count(*)`.
  public func count<each J: Table>(
    filter: ((From.TableColumns, repeat (each J).TableColumns) -> some QueryExpression<Bool>)? = nil
  ) -> Select<Int, From, (repeat each J)>
  where Columns == (), Joins == (repeat each J) {
    let filter = filter?(From.columns, repeat (each J).columns)
    return select { _ in .count(filter: filter) }
  }

  /// Creates a new select statement from this one by appending `count(*)` to its selection.
  ///
  /// - Parameter filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A new select statement that selects `count(*)`.
  public func count<each C: QueryRepresentable, each J: Table>(
    filter: ((From.TableColumns, repeat (each J).TableColumns) -> some QueryExpression<Bool>)? = nil
  ) -> Select<
    (repeat each C, Int), From, (repeat each J)
  >
  where Columns == (repeat each C), Joins == (repeat each J) {
    let filter = filter?(From.columns, repeat (each J).columns)
    return select { _ in .count(filter: filter) }
  }

  /// Creates a new select statement from this one by appending `count(*)` to its selection.
  ///
  /// - Parameter filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A new select statement that selects `count(*)`.
  public func count(
    filter: ((From.TableColumns, Joins.TableColumns) -> some QueryExpression<Bool>)? = nil
  ) -> Select<Int, From, Joins>
  where Columns == (), Joins: Table {
    let filter = filter?(From.columns, Joins.columns)
    return select { _, _ in .count(filter: filter) }
  }

  /// Creates a new select statement from this one by appending `count(*)` to its selection.
  ///
  /// - Parameter filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A new select statement that selects `count(*)`.
  public func count<each C: QueryRepresentable>(
    filter: ((From.TableColumns, Joins.TableColumns) -> some QueryExpression<Bool>)? = nil
  ) -> Select<
    (repeat each C, Int), From, Joins
  >
  where Columns == (repeat each C), Joins: Table {
    let filter = filter?(From.columns, Joins.columns)
    return select { _, _ in .count(filter: filter) }
  }
}
