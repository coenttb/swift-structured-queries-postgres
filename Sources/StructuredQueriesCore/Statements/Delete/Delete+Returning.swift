extension Delete {
  /// Adds a returning clause to a delete statement.
  ///
  /// ```swift
  /// Reminder.delete().returning { ($0.id, $0.title) }
  /// // DELETE FROM "reminders" RETURNING "id", "title"
  ///
  /// Reminder.delete().returning(\.self)
  /// // DELETE FROM "reminders" RETURNING …
  /// ```
  ///
  /// - Parameter selection: Columns to return.
  /// - Returns: A statement with a returning clause.
  public func returning<each QueryValue: QueryRepresentable>(
    _ selection: (From.TableColumns) -> (repeat TableColumn<From, each QueryValue>)
  ) -> Delete<From, (repeat each QueryValue)> {
    var returning: [QueryFragment] = []
    for resultColumn in repeat each selection(From.columns) {
      returning.append("\(quote: resultColumn.name)")
    }
    return Delete<From, (repeat each QueryValue)>(
      isEmpty: isEmpty,
      where: `where`,
      returning: Array(repeat each selection(From.columns))
    )
  }

  // NB: This overload allows for single-column returns like 'returning(\.id)'.
  /// Adds a returning clause to a delete statement.
  ///
  /// ```swift
  /// Reminder.delete().returning(\.id)
  /// // DELETE FROM "reminders" RETURNING "reminders"."id"
  ///
  /// Reminder.delete().returning { $0.id }
  /// // DELETE FROM "reminders" RETURNING "reminders"."id"
  /// ```
  ///
  /// - Parameter selection: A single column to return.
  /// - Returns: A statement with a returning clause.
  public func returning<QueryValue: QueryRepresentable>(
    _ selection: (From.TableColumns) -> TableColumn<From, QueryValue>
  ) -> Delete<From, QueryValue> {
    let column = selection(From.columns)
    return Delete<From, QueryValue>(
      isEmpty: isEmpty,
      where: `where`,
      returning: [column.queryFragment]
    )
  }

  // NB: This overload allows for 'returning(\.self)'.
  /// Adds a returning clause to a delete statement.
  ///
  /// - Parameter selection: Columns to return.
  /// - Returns: A statement with a returning clause.
  @_documentation(visibility: private)
  @_disfavoredOverload
  public func returning(
    _ selection: (From.TableColumns) -> From.TableColumns
  ) -> Delete<From, From> {
    var returning: [QueryFragment] = []
    for resultColumn in From.TableColumns.allColumns {
      returning.append("\(quote: resultColumn.name)")
    }
    return Delete<From, From>(
      isEmpty: isEmpty,
      where: `where`,
      returning: returning
    )
  }
}
