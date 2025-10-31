extension Table {
  /// An update statement.
  ///
  /// The trailing closure of this method allows you to set any field on the table. For example,
  /// constructing an update statement that sets the title of the reminder with "id" equal to 1:
  ///
  /// ```swift
  /// Reminder.update {
  ///   $0.title = "Get haircut"
  /// }
  /// .where { $0.id.eq(1) }
  /// // UPDATE "reminders"
  /// // SET "title" = 'Get haircut'
  /// // WHERE "id" = 1
  /// ```
  ///
  /// There is also a subset of mutations you can make to the argument of the trailing closure that
  /// is translated into the equivalent SQL. For example, to append "!" to the title of every row,
  /// one can do this:
  ///
  /// ```swift
  /// Reminder.update {
  ///   $0.title += "!"
  /// }
  /// // UPDATE "reminders"
  /// // SET "title" = "title" || 'Get haircut'
  /// ```
  ///
  /// The syntax `$0.title += "!"` is translated into the equivalent SQL of
  /// `"title" = "title" || 'Get haircut'`
  ///
  /// - Parameters:
  ///   - conflictResolution: A conflict resolution algorithm.
  ///   - updates: A closure describing column-wise updates to perform.
  /// - Returns: An update statement.
  public static func update(
    set updates: (inout Updates<Self>) -> Void
  ) -> UpdateOf<Self> {
    Where().update(set: updates)
  }
}
