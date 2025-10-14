extension Update {
    /// Adds a returning clause to an update statement.
    ///
    /// ```swift
    /// Reminder.update { $0.isFlagged = true }.returning { ($0.id, $0.title) }
    /// // UPDATE "reminders" SET "isFlagged" = 1 RETURNING "id", "title"
    ///
    /// Reminder.update { $0.isFlagged = true }.returning(\.self)
    /// // UPDATE "reminders" SET "isFlagged" = 1 RETURNING …
    /// ```
    ///
    /// - Parameter selection: Columns to return.
    /// - Returns: A statement with a returning clause.
    public func returning<each QueryValue: QueryRepresentable>(
        _ selection: (From.TableColumns) -> (repeat TableColumn<From, each QueryValue>)
    ) -> Update<From, (repeat each QueryValue)> {
        var returning: [QueryFragment] = []
        for resultColumn in repeat each selection(From.columns) {
            returning.append("\(quote: resultColumn.name)")
        }
        return Update<From, (repeat each QueryValue)>(
            isEmpty: false,
            updates: updates,
            where: `where`,
            returning: returning
        )
    }

    // NB: This overload allows for single-column returns like 'returning(\.id)'.
    /// Adds a returning clause to an update statement.
    ///
    /// ```swift
    /// Reminder.update { $0.isFlagged = true }.returning(\.id)
    /// // UPDATE "reminders" SET "isFlagged" = 1 RETURNING "reminders"."id"
    ///
    /// Reminder.update { $0.isFlagged = true }.returning { $0.id }
    /// // UPDATE "reminders" SET "isFlagged" = 1 RETURNING "reminders"."id"
    /// ```
    ///
    /// - Parameter selection: A single column to return.
    /// - Returns: A statement with a returning clause.
    public func returning<QueryValue: QueryRepresentable>(
        _ selection: (From.TableColumns) -> TableColumn<From, QueryValue>
    ) -> Update<From, QueryValue> {
        let column = selection(From.columns)
        return Update<From, QueryValue>(
            isEmpty: isEmpty,
            updates: updates,
            where: `where`,
            returning: [column.queryFragment]
        )
    }

    // NB: This overload allows for 'returning(\.self)'.
    /// Adds a returning clause to an update statement.
    ///
    /// - Parameter selection: Columns to return.
    /// - Returns: A statement with a returning clause.
    @_documentation(visibility: private)
    @_disfavoredOverload
    public func returning(
        _ selection: (From.TableColumns) -> From.TableColumns
    ) -> Update<From, From> {
        var returning: [QueryFragment] = []
        for resultColumn in From.TableColumns.allColumns {
            returning.append("\(quote: resultColumn.name)")
        }
        return Update<From, From>(
            isEmpty: isEmpty,
            updates: updates,
            where: `where`,
            returning: returning
        )
    }
}
