extension Where {
    /// Adds a condition to a where clause.
    ///
    /// ```swift
    /// extension Reminder {
    ///   static let flagged = Self.where(\.isFlagged)
    /// }
    ///
    /// Reminder.flagged.where(\.isCompleted)
    /// // WHERE "reminders"."isFlagged" AND "reminders"."isCompleted"
    /// ```
    ///
    /// - Parameter keyPath: A key path to a Boolean expression to filter by.
    /// - Returns: A where clause with the added predicate.
    public func `where`(
        _ keyPath: KeyPath<From.TableColumns, some QueryExpression<some _OptionalPromotable<Bool?>>>
    ) -> Self {
        var `where` = self
        `where`.predicates.append(From.columns[keyPath: keyPath].queryFragment)
        return `where`
    }

    /// Adds a condition to a where clause.
    ///
    /// - Parameter predicate: A predicate to add.
    /// - Returns: A where clause with the added predicate.
    @_disfavoredOverload
    public func `where`(
        _ predicate: (From.TableColumns) -> some QueryExpression<some _OptionalPromotable<Bool?>>
    ) -> Self {
        var `where` = self
        `where`.predicates.append(predicate(From.columns).queryFragment)
        return `where`
    }

    /// Adds a condition to a where clause.
    ///
    /// - Parameter predicate: A predicate to add.
    /// - Returns: A where clause with the added predicate.
    public func `where`(
        @QueryFragmentBuilder<Bool> _ predicate: (From.TableColumns) -> [QueryFragment]
    ) -> Self {
        var `where` = self
        `where`.predicates.append(contentsOf: predicate(From.columns))
        return `where`
    }

    /// Combines the predicates of two where clauses together using `AND`.
    ///
    /// - Parameters:
    ///   - lhs: A where clause.
    ///   - rhs: Another where clause.
    /// - Returns: A where clause that `AND`s the given where clauses together.
    public static func && (lhs: Self, rhs: Self) -> Self {
        lhs.and(rhs)
    }

    /// Combines the predicates of two where clauses together using `OR`.
    ///
    /// - Parameters:
    ///   - lhs: A where clause.
    ///   - rhs: Another where clause.
    /// - Returns: A where clause that `OR`s the given where clauses together.
    public static func || (lhs: Self, rhs: Self) -> Self {
        lhs.or(rhs)
    }

    /// Negates the predicates of a where clause using `NOT`.
    ///
    /// - Parameter where: A where clause.
    /// - Returns: A where clause that `NOT`s the given where clause.
    public static prefix func ! (where: Self) -> Self {
        `where`.not()
    }

    /// Combines the predicates of this where clause and another using `AND`.
    ///
    /// - Parameter other: Another where clause.
    /// - Returns: A where clause that `AND`s the given where clauses together.
    public func and(_ other: Self) -> Self {
        guard !predicates.isEmpty else { return other }
        guard !other.predicates.isEmpty else { return self }
        var `where` = self
        `where`.predicates = [
            """
            (\(`where`.predicates.joined(separator: " AND "))) \
            AND \
            (\(other.predicates.joined(separator: " AND ")))
            """
        ]
        return `where`
    }

    /// Combines the predicates of this where clause and another using `OR`.
    ///
    /// - Parameter other: Another where clause.
    /// - Returns: A where clause that `OR`s the given where clauses together.
    public func or(_ other: Self) -> Self {
        guard !predicates.isEmpty else { return other }
        guard !other.predicates.isEmpty else { return self }
        var `where` = self
        `where`.predicates = [
            """
            (\(`where`.predicates.joined(separator: " AND "))) \
            OR \
            (\(other.predicates.joined(separator: " AND ")))
            """
        ]
        return `where`
    }

    /// Negates the predicates of a where clause using `NOT`.
    ///
    /// - Returns: A where clause that `NOT`s this where clause.
    public func not() -> Self {
        var `where` = self
        `where`.predicates = [
            "NOT (\(predicates.isEmpty ? "1" : predicates.joined(separator: " AND ")))"
        ]
        return `where`
    }
}
