extension Update {
  /// Adds a condition to an update statement.
  ///
  /// ```swift
  /// Reminder.update { $0.isFlagged = true }.where(\.isCompleted)
  /// // UPDATE "reminders" SET "isFlagged" = 1 WHERE "reminders"."isCompleted"
  /// ```
  ///
  /// - Parameter keyPath: A key path to a Boolean expression to filter by.
  /// - Returns: A statement with the added predicate.
  public func `where`(
    _ keyPath: KeyPath<From.TableColumns, some QueryExpression<some _OptionalPromotable<Bool?>>>
  ) -> Self {
    var update = self
    update.where.append(From.columns[keyPath: keyPath].queryFragment)
    return update
  }

  /// Adds a condition to an update statement.
  ///
  /// - Parameter predicate: A closure that returns a Boolean expression to filter by.
  /// - Returns: A statement with the added predicate.
  @_disfavoredOverload
  public func `where`(
    _ predicate: (From.TableColumns) -> some QueryExpression<some _OptionalPromotable<Bool?>>
  ) -> Self {
    var update = self
    update.where.append(predicate(From.columns).queryFragment)
    return update
  }

  /// Adds a condition to an update statement.
  ///
  /// - Parameter predicate: A result builder closure that returns a Boolean expression to filter
  ///   by.
  /// - Returns: A statement with the added predicate.
  public func `where`(
    @QueryFragmentBuilder<Bool> _ predicate: (From.TableColumns) -> [QueryFragment]
  ) -> Self {
    var update = self
    update.where.append(contentsOf: predicate(From.columns))
    return update
  }
}
