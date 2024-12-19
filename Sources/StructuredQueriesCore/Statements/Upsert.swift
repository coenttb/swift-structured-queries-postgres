extension PrimaryKeyedTable {
  /// An upsert statement for a given draft.
  ///
  /// Generates an insert statement with an upsert clause. Useful for building forms that can both
  /// insert new records as well as update them.
  ///
  /// ```swift
  /// Reminder.upsert(draft)
  /// // INSERT INTO "reminders" ("id", …)
  /// // VALUES (1, …)
  /// // ON CONFLICT DO UPDATE SET "…" = "excluded"."…", …
  /// ```
  ///
  /// - Parameter row: A draft representing a row to insert or update.
  /// - Returns: An insert statement with an upsert clause.
  public static func upsert(
    _ row: Draft
  ) -> InsertOf<Self> {
    insert(
      row,
      onConflict: { updates in
        for column in Draft.TableColumns.allColumns where column.name != columns.primaryKey.name {
          updates.set(column, #""excluded".\#(quote: column.name)"#)
        }
      }
    )
  }
}
