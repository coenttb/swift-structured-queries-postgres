extension Table {
    /// A `CREATE TEMPORARY VIEW` statement.
    ///
    /// See <doc:Views> for more information.
    ///
    /// - Parameters:
    ///   - orReplace: Adds an `OR REPLACE` clause to the `CREATE VIEW` statement.
    ///   - select: A statement describing the contents of the view.
    /// - Returns: A temporary trigger.
    public static func createTemporaryView<Selection: PartialSelectStatement>(
        orReplace: Bool = false,
        as select: Selection
    ) -> TemporaryView<Self, Selection>
    where Selection.QueryValue == Columns.QueryValue {
        TemporaryView(orReplace: orReplace, select: select)
    }
}

/// A `CREATE TEMPORARY VIEW` statement.
///
/// This type of statement is returned from ``Table/createTemporaryView(orReplace:as:)``.
///
/// To learn more, see <doc:Views>.
public struct TemporaryView<View: Table, Selection: PartialSelectStatement>: Statement
where Selection.QueryValue == View {
    public typealias QueryValue = ()
    public typealias From = Never

    fileprivate let orReplace: Bool
    fileprivate let select: Selection

    /// Returns a `DROP VIEW` statement for this trigger.
    ///
    /// - Parameter ifExists: Adds an `IF EXISTS` condition to the `DROP VIEW`.
    /// - Returns: A `DROP VIEW` statement for this trigger.
    public func drop(ifExists: Bool = false) -> some Statement<()> {
        var query: QueryFragment = "DROP VIEW"
        if ifExists {
            query.append(" IF EXISTS")
        }
        query.append(" ")
        if let schemaName = View.schemaName {
            query.append("\(quote: schemaName).")
        }
        query.append(View.tableFragment)
        return SQLQueryExpression(query)
    }

    public var query: QueryFragment {
        var query: QueryFragment = "CREATE"
        if orReplace {
            query.append(" OR REPLACE")
        }
        query.append(" TEMP VIEW")
        query.append(.newlineOrSpace)
        if let schemaName = View.schemaName {
            query.append("\(quote: schemaName).")
        }
        query.append(View.tableFragment)
        let columnNames: [QueryFragment] = View.TableColumns.allColumns
            .map { "\(quote: $0.name)" }
        query.append("\(.newlineOrSpace)(\(columnNames.joined(separator: ", ")))")
        query.append("\(.newlineOrSpace)AS")
        query.append("\(.newlineOrSpace)\(select)")
        return query
    }
}
