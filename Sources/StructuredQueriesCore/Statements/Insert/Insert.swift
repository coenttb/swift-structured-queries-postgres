import Foundation
import IssueReporting

// Helper function to check if a QueryFragment represents NULL
private func isNullBinding(_ fragment: QueryFragment) -> Bool {
    // Empty fragment typically means NULL
    if fragment.segments.isEmpty {
        return true
    }

    // Check each segment
    for segment in fragment.segments {
        // Check for null binding
        if case .binding(.null) = segment {
            return true
        }
    }

    return false
}

package enum InsertValues {
    case `default`
    case values([[QueryFragment]])
    case select(QueryFragment)
}

/// An `INSERT` statement.
///
/// This type of statement is returned from the
/// `[Table.insert]<doc:Table/insert(or:_:values:onConflict:where:doUpdate:where:)>` family of
/// functions.
///
/// To learn more, see <doc:InsertStatements>.
public struct Insert<Into: Table, Returning>: Sendable {
    var columnNames: [String]
    var conflictTargetColumnNames: [String]
    var conflictTargetFilter: [QueryFragment]
    var values: InsertValues
    var updates: Updates<Into>?
    var updateFilter: [QueryFragment]
    var returning: [QueryFragment]

    /// Adds a returning clause to an insert statement.
    ///
    /// - Parameter selection: Columns to return.
    /// - Returns: A statement with a returning clause.
    public func returning<each QueryValue: QueryRepresentable>(
        _ selection: (From.TableColumns) -> (repeat TableColumn<From, each QueryValue>)
    ) -> Insert<Into, (repeat each QueryValue)> {
        var returning: [QueryFragment] = []
        for resultColumn in repeat each selection(From.columns) {
            returning.append("\(quote: resultColumn.name)")
        }
        return Insert<Into, (repeat each QueryValue)>(
            columnNames: columnNames,
            conflictTargetColumnNames: conflictTargetColumnNames,
            conflictTargetFilter: conflictTargetFilter,
            values: values,
            updates: updates,
            updateFilter: updateFilter,
            returning: returning
        )
    }

    // NB: This overload allows for single-column returns like 'returning(\.id)'.
    /// Adds a returning clause to an insert statement.
    ///
    /// ```swift
    /// Reminder.insert { draft }.returning(\.id)
    /// // INSERT INTO "reminders" (...) VALUES (...) RETURNING "reminders"."id"
    ///
    /// Reminder.insert { draft }.returning { $0.id }
    /// // INSERT INTO "reminders" (...) VALUES (...) RETURNING "reminders"."id"
    /// ```
    ///
    /// - Parameter selection: A single column to return.
    /// - Returns: A statement with a returning clause.
    public func returning<QueryValue: QueryRepresentable>(
        _ selection: (From.TableColumns) -> TableColumn<From, QueryValue>
    ) -> Insert<Into, QueryValue> {
        let column = selection(From.columns)
        return Insert<Into, QueryValue>(
            columnNames: columnNames,
            conflictTargetColumnNames: conflictTargetColumnNames,
            conflictTargetFilter: conflictTargetFilter,
            values: values,
            updates: updates,
            updateFilter: updateFilter,
            returning: [column.queryFragment]
        )
    }

    // NB: This overload allows for 'returning(\.self)'.
    /// Adds a returning clause to an insert statement.
    ///
    /// - Parameter selection: Columns to return.
    /// - Returns: A statement with a returning clause.
    @_documentation(visibility: private)
    @_disfavoredOverload
    public func returning(
        _ selection: (Into.TableColumns) -> Into.TableColumns
    ) -> Insert<Into, Into> {
        var returning: [QueryFragment] = []
        for resultColumn in From.TableColumns.allColumns {
            returning.append("\(quote: resultColumn.name)")
        }
        return Insert<Into, Into>(
            columnNames: columnNames,
            conflictTargetColumnNames: conflictTargetColumnNames,
            conflictTargetFilter: conflictTargetFilter,
            values: values,
            updates: updates,
            updateFilter: updateFilter,
            returning: returning
        )
    }
}

extension Insert: Statement {
    public typealias QueryValue = Returning
    public typealias From = Into

    public var query: QueryFragment {
        var query: QueryFragment = "INSERT"
        query.append(" INTO ")
        if let schemaName = Into.schemaName {
            query.append("\(quote: schemaName).")
        }
        query.append("\(quote: Into.tableName)")
        if let tableAlias = Into.tableAlias {
            query.append(" AS \(quote: tableAlias)")
        }
        if !columnNames.isEmpty {
            query.append(
                "\(.newlineOrSpace)(\(columnNames.map { "\(quote: $0)" }.joined(separator: ", ")))"
            )
        }
        switch values {
        case .default:
            query.append("\(.newlineOrSpace)DEFAULT VALUES")

        case .select(let select):
            query.append("\(.newlineOrSpace)\(select)")

        case .values(let values):
            guard !values.isEmpty else { return "" }
            query.append("\(.newlineOrSpace)VALUES\(.newlineOrSpace)")
            let values: [QueryFragment] = values.map {
                var value: QueryFragment = "("
                value.append($0.joined(separator: ", "))
                value.append(")")
                return value
            }
            query.append(values.joined(separator: ", "))
        }

        var hasInvalidWhere = false
        if let updates {
            query.append("\(.newlineOrSpace)ON CONFLICT ")
            if !conflictTargetColumnNames.isEmpty {
                query.append("(")
                query.append(
                    conflictTargetColumnNames.map { "\(quote: $0)" }.joined(separator: ", "))
                query.append(")\(.newlineOrSpace)")
                if !conflictTargetFilter.isEmpty {
                    query.append(
                        "WHERE \(conflictTargetFilter.joined(separator: " AND "))\(.newlineOrSpace)"
                    )
                }
            }
            query.append("DO ")
            if updates.isEmpty {
                query.append("NOTHING")
                hasInvalidWhere = !updateFilter.isEmpty
            } else {
                query.append("UPDATE \(bind: updates)")
                if !updateFilter.isEmpty {
                    query.append(
                        "\(.newlineOrSpace)WHERE \(updateFilter.joined(separator: " AND "))")
                }
            }
        } else {
            hasInvalidWhere = !updateFilter.isEmpty
        }
        if !returning.isEmpty {
            query.append("\(.newlineOrSpace)RETURNING \(returning.joined(separator: ", "))")
        }
        if hasInvalidWhere {
            reportIssue(
                """
                Insert statement has invalid update 'where': \(updateFilter.joined(separator: " AND "))

                \(query)
                """
            )
        }
        return query
    }
}

/// A convenience type alias for a non-`RETURNING ``Insert``.
public typealias InsertOf<Into: Table> = Insert<Into, ()>
