extension Where {
  /// A select statement for the filtered table joined to another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A select statement that joins the given table.
  public func join<each C: QueryRepresentable, F: Table, each J: Table>(
    _ other: some SelectStatement<(repeat each C), F, (repeat each J)>,
    on constraint: (
      (From.TableColumns, F.TableColumns, repeat (each J).TableColumns)
    ) -> some QueryExpression<Bool>
  ) -> Select<(repeat each C), From, (F, repeat each J)> {
    asSelect().join(other, on: constraint)
  }

  /// A select statement for the filtered table left-joined to another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A select statement that left-joins the given table.
  public func leftJoin<each C: QueryRepresentable, F: Table, each J: Table>(
    _ other: some SelectStatement<(repeat each C), F, (repeat each J)>,
    on constraint: (
      (From.TableColumns, F.TableColumns, repeat (each J).TableColumns)
    ) -> some QueryExpression<Bool>
  ) -> Select<
    (repeat (each C)._Optionalized),
    From,
    (F._Optionalized, repeat (each J)._Optionalized)
  > {
    let joined = asSelect().leftJoin(other, on: constraint)
    return joined
  }

  /// A select statement for the filtered table right-joined to another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A select statement that right-joins the given table.
  public func rightJoin<each C: QueryRepresentable, F: Table, each J: Table>(
    _ other: some SelectStatement<(repeat each C), F, (repeat each J)>,
    on constraint: (
      (From.TableColumns, F.TableColumns, repeat (each J).TableColumns)
    ) -> some QueryExpression<Bool>
  ) -> Select<(repeat each C), From._Optionalized, (F, repeat each J)> {
    let joined = asSelect().rightJoin(other, on: constraint)
    return joined
  }

  /// A select statement for the filtered table full-joined to another table.
  ///
  /// - Parameters:
  ///   - other: A select statement for another table.
  ///   - constraint: The constraint describing the join.
  /// - Returns: A select statement that full-joins the given table.
  public func fullJoin<each C: QueryRepresentable, F: Table, each J: Table>(
    _ other: some SelectStatement<(repeat each C), F, (repeat each J)>,
    on constraint: (
      (From.TableColumns, F.TableColumns, repeat (each J).TableColumns)
    ) -> some QueryExpression<Bool>
  ) -> Select<
    (repeat (each C)._Optionalized),
    From._Optionalized,
    (F._Optionalized, repeat (each J)._Optionalized)
  > {
    let joined = asSelect().fullJoin(other, on: constraint)
    return joined
  }

}
