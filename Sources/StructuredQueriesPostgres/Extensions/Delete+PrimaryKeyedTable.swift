import StructuredQueriesCore

extension PrimaryKeyedTable {
    /// A delete statement for a table row.
    ///
    /// ```swift
    /// Reminder.delete(reminder)
    /// // DELETE FROM "reminders" WHERE "reminders"."id" = 1
    /// ```
    ///
    /// - Parameter row: A row to delete.
    /// - Returns: A delete statement.
    public static func delete(_ row: Self) -> DeleteOf<Self> {
        delete()
            .where {
                $0.primaryKey.eq(PrimaryKey(queryOutput: row[keyPath: $0.primaryKey.keyPath]))
            }
    }
}
