import StructuredQueriesCore

extension PrimaryKeyedTable {
    /// An update statement for the values of a given record.
    ///
    /// This method is defined only on ``PrimaryKeyedTable`` conformances (see
    /// <doc:PrimaryKeyedTables> for more info), and it constructs an update statement that sets
    /// every field of the row whose ID matches the "id" of the model:
    ///
    /// ```swift
    /// @Table
    /// struct Tag {
    ///   let id: Int
    ///   var name: String
    /// }
    ///
    /// Tag.update(Tag(id: 1, name: "home"))
    /// // UPDATE "tags" SET "name" = 'home' WHERE "id" = 1
    /// ```
    ///
    /// - Parameters:
    ///   - conflictResolution: A conflict resolution algorithm.
    ///   - row: A row to update.
    /// - Returns: An update statement.
    public static func update(
        _ row: Self
    ) -> UpdateOf<Self> {
        update { updates in
            for column in TableColumns.writableColumns
            where !columns.primaryKey._names.contains(column.name) {
                func open<Root, Value>(_ column: some WritableTableColumnExpression<Root, Value>) {
                    updates.set(
                        column,
                        Value(queryOutput: (row as! Root)[keyPath: column.keyPath]).queryFragment
                    )
                }
                open(column)
            }
        }
        .where {
            $0.primaryKey.eq(PrimaryKey(queryOutput: row[keyPath: $0.primaryKey.keyPath]))
        }
    }
}
