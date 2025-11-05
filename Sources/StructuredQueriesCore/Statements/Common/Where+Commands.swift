extension Where {
    /// A delete statement for the filtered table.
    public func delete() -> DeleteOf<From> {
        Delete(
            isEmpty: scope == .empty,
            where: scope == .unscoped ? predicates : From.all._selectClauses.where + predicates
        )
    }

    /// An update statement for the filtered table.
    ///
    /// - Parameters:
    ///   - conflictResolution: A conflict resolution algorithm.
    ///   - updates: A closure describing column-wise updates to perform.
    /// - Returns: An update statement.
    public func update(
        set updates: (inout Updates<From>) -> Void
    ) -> UpdateOf<From> {
        Update(
            isEmpty: scope == .empty,
            updates: Updates(updates),
            where: scope == .unscoped ? predicates : From.all._selectClauses.where + predicates
        )
    }
}
