extension Delete {
    /// Adds a condition to a delete statement.
    ///
    /// ```swift
    /// Reminder.delete().where(\.isCompleted)
    /// // DELETE FROM "reminders" WHERE "reminders"."isCompleted"
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

    /// Adds a condition to a delete statement.
    ///
    /// ```swift
    /// Reminder.delete().where(\.isCompleted)
    /// // DELETE FROM "reminders" WHERE "reminders"."isCompleted"
    /// ```
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

    /// Adds a condition to a delete statement.
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
