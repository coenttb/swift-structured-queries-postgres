extension Table {
  /// A delete statement for a table.
  ///
  /// ```swift
  /// Reminder.delete()
  /// // DELETE FROM "reminders"
  /// ```
  ///
  /// - Returns: A delete statement.
  public static func delete() -> DeleteOf<Self> {
    Where().delete()
  }
}
