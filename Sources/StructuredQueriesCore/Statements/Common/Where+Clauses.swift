extension Where {
  /// A select statement for the filtered table grouped by the given column.
  public func group<C: QueryExpression>(
    by grouping: (From.TableColumns) -> C
  ) -> Select<(), From, ()> {
    asSelect().group(by: grouping)
  }

  /// A select statement for the filtered table grouped by the given columns.
  public func group<C1: QueryExpression, C2: QueryExpression, each C3: QueryExpression>(
    by grouping: (From.TableColumns) -> (C1, C2, repeat each C3)
  ) -> SelectOf<From> {
    asSelect().group(by: grouping)
  }

  /// A select statement for the filtered table with the given `HAVING` clause.
  public func having(
    _ predicate: (From.TableColumns) -> some QueryExpression<some _OptionalPromotable<Bool?>>
  ) -> SelectOf<From> {
    asSelect().having(predicate)
  }

  /// A select statement for the filtered table ordered by the given column.
  ///
  /// - Parameter ordering: A key path to a column to order by.
  /// - Returns: A select statement that is ordered by the given column.
  public func order(
    by ordering: KeyPath<From.TableColumns, some QueryExpression>
  ) -> SelectOf<From> {
    asSelect().order(by: ordering)
  }

  /// A select statement for the filtered table grouped by the given columns.
  ///
  /// - Parameter ordering: A result builder closure that returns columns to order by.
  /// - Returns: A select statement that is ordered by the given columns.
  public func order(
    @QueryFragmentBuilder<()>
    by ordering: (From.TableColumns) -> [QueryFragment]
  ) -> SelectOf<From> {
    asSelect().order(by: ordering)
  }

  /// A select statement for the filtered table with a limit and optional offset.
  ///
  /// - Parameters:
  ///   - maxLength: A closure that produces a `LIMIT` expression from this table's columns.
  ///   - offset: A closure that produces an `OFFSET` expression from this table's columns.
  /// - Returns: A select statement with a limit and optional offset.
  public func limit(
    _ maxLength: (From.TableColumns) -> some QueryExpression<Int>,
    offset: ((From.TableColumns) -> some QueryExpression<Int>)? = nil
  ) -> SelectOf<From> {
    asSelect().limit(maxLength, offset: offset)
  }

  /// A select statement for the filtered table with a limit and optional offset.
  ///
  /// - Parameters:
  ///   - maxLength: An integer limit for the select's `LIMIT` clause.
  ///   - offset: An optional integer offset of the select's `OFFSET` clause.
  /// - Returns: A select statement with a limit and optional offset.
  public func limit(_ maxLength: Int, offset: Int? = nil) -> SelectOf<From> {
    asSelect().limit(maxLength, offset: offset)
  }
}
