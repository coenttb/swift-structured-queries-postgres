import StructuredQueriesCore

extension Where {
  /// A select statement for the filtered table's row count.
  ///
  /// - Parameter filter: A `FILTER` clause to apply to the aggregation.
  /// - Returns: A select statement that selects `count(*)`.
  public func count(
    filter: ((From.TableColumns) -> some QueryExpression<Bool>)? = nil
  ) -> Select<Int, From, ()> {
    let filter = filter?(From.columns)
    return asSelect().select { _ in .count(filter: filter) }
  }
}
