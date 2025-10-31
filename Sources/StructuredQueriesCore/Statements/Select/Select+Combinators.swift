extension Select {
  /// Creates a new select statement from this one by transforming its selected columns to a new
  /// selection.
  ///
  /// - Parameter transform: A mapping closure. Accepts a tuple of selected columns and returns a
  ///   transformed selection.
  /// - Returns: A new select statement that selects the result of the transformation.
  public func map<each C1: QueryRepresentable, each C2: QueryExpression>(
    _ transform: (repeat SQLQueryExpression<each C1>) -> (repeat each C2)
  ) -> Select<(repeat (each C2).QueryValue), From, Joins>
  where
    QueryValue == (repeat each C1),
    repeat (each C2).QueryValue: QueryRepresentable
  {
    var iterator = columns.makeIterator()
    func next<Element>() -> SQLQueryExpression<Element> {
      SQLQueryExpression(iterator.next()!)
    }
    return Select<(repeat (each C2).QueryValue), From, Joins>(
      isEmpty: isEmpty,
      distinct: distinct,
      columns: Array(repeat each transform(repeat { _ in next() }((each C1).self))),
      joins: joins,
      where: `where`,
      group: group,
      having: having,
      order: order,
      windows: windows,
      limit: limit
    )
  }

  /// Returns a fully unscoped version of this select statement.
  public var unscoped: Where<From> {
    From.unscoped
  }

  /// Returns this select statement unchanged.
  public var all: Self {
    self
  }

  /// Returns an empty select statement.
  public var none: Self {
    var select = self
    select.isEmpty = true
    return select
  }
}
