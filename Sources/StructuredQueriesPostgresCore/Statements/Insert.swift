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

extension Table {
  /// Columns referencing the value that would have been inserted in an
  /// [insert statement](<doc:InsertStatements>) had there been no conflict.
  public typealias Excluded = TableAlias<Self, _ExcludedName>.TableColumns

  /// An insert statement for one or more table rows.
  ///
  /// This function can be used to create an insert statement from a ``Table`` value.
  ///
  /// ```swift
  /// let tag = Tag(title: "car")
  /// Tag.insert { tag }
  /// // INSERT INTO "tags" ("title")
  /// // VALUES ('car')
  /// ```
  ///
  /// It can also be used to insert multiple rows in a single statement.
  ///
  /// ```swift
  /// let tags = [
  ///   Tag(title: "car"),
  ///   Tag(title: "kids"),
  ///   Tag(title: "someday"),
  ///   Tag(title: "optional")
  /// ]
  /// Tag.insert { tags }
  /// // INSERT INTO "tags" ("title")
  /// // VALUES ('car'), ('kids'), ('someday'), ('optional')
  /// ```
  ///
  /// The `values` trailing closure is a result builder that will insert any number of expressions,
  /// one after the other, and supports basic control flow statements.
  ///
  /// ```swift
  /// Tag.insert {
  ///   if vehicleOwner {
  ///     Tag(name: "car")
  ///   }
  ///   Tag(name: "kids")
  ///   Tag(name: "someday")
  ///   Tag(name: "optional")
  /// }
  /// // INSERT INTO "tags" ("title")
  /// // VALUES ('car'), ('kids'), ('someday'), ('optional')
  /// ```
  ///
  /// - Parameters:
  ///   - conflictResolution: A conflict resolution algorithm.
  ///   - columns: Columns to insert.
  ///   - values: A builder of row values for the given columns.
  ///   - updates: Updates to perform in an upsert clause should the insert conflict with an
  ///     existing row.
  ///   - updateFilter: A filter to apply to the update clause.
  /// - Returns: An insert statement.
  public static func insert(
    _ columns: (TableColumns) -> TableColumns = { $0 },
    @InsertValuesBuilder<Self> values: () -> [[QueryFragment]],
    onConflictDoUpdate updates: ((inout Updates<Self>, Excluded) -> Void)? = nil,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    _insert(
      columnNames: TableColumns.writableColumns.map(\.name),
      values: .values(values()),
      onConflict: { _ -> ()? in nil },
      where: { _ in return [] },
      doUpdate: updates,
      where: updateFilter
    )
  }

  /// An insert statement for one or more table rows.
  ///
  /// This function can be used to create an insert statement from a ``Table`` value.
  ///
  /// ```swift
  /// let tag = Tag(title: "car")
  /// Tag.insert { tag }
  /// // INSERT INTO "tags" ("title")
  /// // VALUES ('car')
  /// ```
  ///
  /// It can also be used to insert multiple rows in a single statement.
  ///
  /// ```swift
  /// let tags = [
  ///   Tag(title: "car"),
  ///   Tag(title: "kids"),
  ///   Tag(title: "someday"),
  ///   Tag(title: "optional")
  /// ]
  /// Tag.insert { tags }
  /// // INSERT INTO "tags" ("title")
  /// // VALUES ('car'), ('kids'), ('someday'), ('optional')
  /// ```
  ///
  /// The `values` trailing closure is a result builder that will insert any number of expressions,
  /// one after the other, and supports basic control flow statements.
  ///
  /// ```swift
  /// Tag.insert {
  ///   if vehicleOwner {
  ///     Tag(name: "car")
  ///   }
  ///   Tag(name: "kids")
  ///   Tag(name: "someday")
  ///   Tag(name: "optional")
  /// }
  /// // INSERT INTO "tags" ("title")
  /// // VALUES ('car'), ('kids'), ('someday'), ('optional')
  /// ```
  ///
  /// - Parameters:
  ///   - conflictResolution: A conflict resolution algorithm.
  ///   - columns: Columns to insert.
  ///   - values: A builder of row values for the given columns.
  ///   - updates: Updates to perform in an upsert clause should the insert conflict with an
  ///     existing row.
  ///   - updateFilter: A filter to apply to the update clause.
  /// - Returns: An insert statement.
  public static func insert(
    _ columns: (TableColumns) -> TableColumns = { $0 },
    @InsertValuesBuilder<Self> values: () -> [[QueryFragment]],
    onConflictDoUpdate updates: ((inout Updates<Self>) -> Void)?,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    insert(
      columns,
      values: values,
      onConflictDoUpdate: updates.map { updates in { row, _ in updates(&row) } },
      where: updateFilter
    )
  }

  /// An upsert statement for one or more table rows.
  ///
  /// - Parameters:
  ///   - conflictResolution: A conflict resolution algorithm.
  ///   - columns: Columns to insert.
  ///   - values: A builder of row values for the given columns.
  ///   - conflictTargets: Indexed columns to target for conflict resolution.
  ///   - targetFilter: A filter to apply to conflict target columns.
  ///   - updates: Updates to perform in an upsert clause should the insert conflict with an
  ///     existing row.
  ///   - updateFilter: A filter to apply to the update clause.
  /// - Returns: An insert statement.
  public static func insert<T1, each T2>(
    _ columns: (TableColumns) -> TableColumns = { $0 },
    @InsertValuesBuilder<Self> values: () -> [[QueryFragment]],
    onConflict conflictTargets: (TableColumns) -> (
      TableColumn<Self, T1>, repeat TableColumn<Self, each T2>
    ),
    @QueryFragmentBuilder<Bool>
    where targetFilter: (TableColumns) -> [QueryFragment] = { _ in [] },
    doUpdate updates: (inout Updates<Self>, Excluded) -> Void = { _, _ in },
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    withoutActuallyEscaping(updates) { updates in
      _insert(
        columnNames: TableColumns.writableColumns.map(\.name),
        values: .values(values()),
        onConflict: conflictTargets,
        where: targetFilter,
        doUpdate: updates,
        where: updateFilter
      )
    }
  }

  /// An upsert statement for one or more table rows.
  ///
  /// - Parameters:
  ///   - conflictResolution: A conflict resolution algorithm.
  ///   - columns: Columns to insert.
  ///   - values: A builder of row values for the given columns.
  ///   - conflictTargets: Indexed columns to target for conflict resolution.
  ///   - targetFilter: A filter to apply to conflict target columns.
  ///   - updates: Updates to perform in an upsert clause should the insert conflict with an
  ///     existing row.
  ///   - updateFilter: A filter to apply to the update clause.
  /// - Returns: An insert statement.
  public static func insert<T1, each T2>(
    _ columns: (TableColumns) -> TableColumns = { $0 },
    @InsertValuesBuilder<Self> values: () -> [[QueryFragment]],
    onConflict conflictTargets: (TableColumns) -> (
      TableColumn<Self, T1>, repeat TableColumn<Self, each T2>
    ),
    @QueryFragmentBuilder<Bool>
    where targetFilter: (TableColumns) -> [QueryFragment] = { _ in [] },
    doUpdate updates: (inout Updates<Self>) -> Void,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    insert(
      columns,
      values: values,
      onConflict: conflictTargets,
      where: targetFilter,
      doUpdate: { row, _ in updates(&row) },
      where: updateFilter
    )
  }

  /// An insert statement for one or more table rows.
  ///
  /// This function can be used to create an insert statement for a specified set of columns.
  ///
  /// ```swift
  /// Tag.insert {
  ///   $0.title
  /// } values: {
  ///   "car"
  /// }
  /// // INSERT INTO "tags" ("title")
  /// // VALUES ('car')
  /// ```
  ///
  /// It can also be used to insert multiple rows in a single statement.
  ///
  /// ```swift
  /// let tags = ["car", "kids", "someday", "optional"]
  /// Tag.insert {
  ///   $0.title
  /// } values: {
  ///   tags
  /// }
  /// let tags = ["car", "kids", "someday", "optional"]
  /// Tag.insert { tags }
  /// // INSERT INTO "tags" ("title")
  /// // VALUES ('car'), ('kids'), ('someday'), ('optional')
  /// ```
  ///
  /// The `values` trailing closure is a result builder that will insert any number of expressions,
  /// one after the other, and supports basic control flow statements.
  ///
  /// ```swift
  /// Tag.insert {
  ///   $0.title
  /// } values: {
  ///   if vehicleOwner {
  ///     "car"
  ///   }
  ///   "kids"
  ///   "someday"
  ///   "optional"
  /// }
  /// // INSERT INTO "tags" ("title")
  /// // VALUES ('car'), ('kids'), ('someday'), ('optional')
  /// ```
  ///
  /// - Parameters:
  ///   - conflictResolution: A conflict resolution algorithm.
  ///   - columns: Columns to insert.
  ///   - values: A builder of row values for the given columns.
  ///   - updates: Updates to perform in an upsert clause should the insert conflict with an
  ///     existing row.
  ///   - updateFilter: A filter to apply to the update clause.
  /// - Returns: An insert statement.
  public static func insert<V1, each V2>(
    _ columns: (TableColumns) -> (TableColumn<Self, V1>, repeat TableColumn<Self, each V2>),
    @InsertValuesBuilder<(V1, repeat each V2)>
    values: () -> [[QueryFragment]],
    onConflictDoUpdate updates: ((inout Updates<Self>, Excluded) -> Void)? = nil,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    _insert(
      columns,
      values: values,
      onConflict: { _ -> ()? in nil },
      where: { _ in return [] },
      doUpdate: updates,
      where: updateFilter
    )
  }

  /// An insert statement for one or more table rows.
  ///
  /// - Parameters:
  ///   - conflictResolution: A conflict resolution algorithm.
  ///   - columns: Columns to insert.
  ///   - values: A builder of row values for the given columns.
  ///   - updates: Updates to perform in an upsert clause should the insert conflict with an
  ///     existing row.
  ///   - updateFilter: A filter to apply to the update clause.
  /// - Returns: An insert statement.
  public static func insert<V1, each V2>(
    _ columns: (TableColumns) -> (TableColumn<Self, V1>, repeat TableColumn<Self, each V2>),
    @InsertValuesBuilder<(V1, repeat each V2)>
    values: () -> [[QueryFragment]],
    onConflictDoUpdate updates: ((inout Updates<Self>) -> Void)?,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    insert(
      columns,
      values: values,
      onConflictDoUpdate: updates.map { updates in { row, _ in updates(&row) } },
      where: updateFilter
    )
  }

  /// An upsert statement for one or more table rows.
  ///
  /// - Parameters:
  ///   - conflictResolution: A conflict resolution algorithm.
  ///   - columns: Columns to insert.
  ///   - values: A builder of row values for the given columns.
  ///   - conflictTargets: Indexed columns to target for conflict resolution.
  ///   - targetFilter: A filter to apply to conflict target columns.
  ///   - updates: Updates to perform in an upsert clause should the insert conflict with an
  ///     existing row.
  ///   - updateFilter: A filter to apply to the update clause.
  /// - Returns: An insert statement.
  public static func insert<V1, each V2, T1, each T2>(
    _ columns: (TableColumns) -> (TableColumn<Self, V1>, repeat TableColumn<Self, each V2>),
    @InsertValuesBuilder<(V1, repeat each V2)>
    values: () -> [[QueryFragment]],
    onConflict conflictTargets: (TableColumns) -> (
      TableColumn<Self, T1>, repeat TableColumn<Self, each T2>
    ),
    @QueryFragmentBuilder<Bool>
    where targetFilter: (TableColumns) -> [QueryFragment] = { _ in [] },
    doUpdate updates: (inout Updates<Self>, Excluded) -> Void = { _, _ in },
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    withoutActuallyEscaping(updates) { updates in
      _insert(
          columns,
        values: values,
        onConflict: conflictTargets,
        where: targetFilter,
        doUpdate: updates,
        where: updateFilter
      )
    }
  }

  /// An upsert statement for one or more table rows.
  ///
  /// - Parameters:
  ///   - conflictResolution: A conflict resolution algorithm.
  ///   - columns: Columns to insert.
  ///   - values: A builder of row values for the given columns.
  ///   - conflictTargets: Indexed columns to target for conflict resolution.
  ///   - targetFilter: A filter to apply to conflict target columns.
  ///   - updates: Updates to perform in an upsert clause should the insert conflict with an
  ///     existing row.
  ///   - updateFilter: A filter to apply to the update clause.
  /// - Returns: An insert statement.
  public static func insert<V1, each V2, T1, each T2>(
    _ columns: (TableColumns) -> (TableColumn<Self, V1>, repeat TableColumn<Self, each V2>),
    @InsertValuesBuilder<(V1, repeat each V2)>
    values: () -> [[QueryFragment]],
    onConflict conflictTargets: (TableColumns) -> (
      TableColumn<Self, T1>, repeat TableColumn<Self, each T2>
    ),
    @QueryFragmentBuilder<Bool>
    where targetFilter: (TableColumns) -> [QueryFragment] = { _ in [] },
    doUpdate updates: (inout Updates<Self>) -> Void,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    insert(
      columns,
      values: values,
      onConflict: conflictTargets,
      where: targetFilter,
      doUpdate: { row, _ in updates(&row) },
      where: updateFilter
    )
  }

  private static func _insert<each Value, each ConflictTarget>(
    _ columns: (TableColumns) -> (repeat TableColumn<Self, each Value>),
    @InsertValuesBuilder<(repeat each Value)>
    values: () -> [[QueryFragment]],
    onConflict conflictTargets: (TableColumns) -> (repeat TableColumn<Self, each ConflictTarget>)?,
    @QueryFragmentBuilder<Bool>
    where targetFilter: (TableColumns) -> [QueryFragment] = { _ in [] },
    doUpdate updates: ((inout Updates<Self>, Excluded) -> Void)?,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    var columnNames: [String] = []
    for column in repeat each columns(Self.columns) {
      columnNames.append(column.name)
    }
    return _insert(
      columnNames: columnNames,
      values: .values(values()),
      onConflict: conflictTargets,
      where: targetFilter,
      doUpdate: updates,
      where: updateFilter
    )
  }

  /// An insert statement for a table selection.
  ///
  /// This function can be used to create an insert statement for the results of a ``Select``
  /// statement.
  ///
  /// - Parameters:
  ///   - conflictResolution: A conflict resolution algorithm.
  ///   - columns: Columns values to be inserted.
  ///   - selection: A statement that selects the values to be inserted.
  ///   - updates: Updates to perform in an upsert clause should the insert conflict with an
  ///     existing row.
  ///   - updateFilter: A filter to apply to the update clause.
  /// - Returns: An insert statement.
  public static func insert<
    V1,
    each V2
  >(
    _ columns: (TableColumns) -> (TableColumn<Self, V1>, repeat TableColumn<Self, each V2>),
    select selection: () -> some PartialSelectStatement<(V1, repeat each V2)>,
    onConflictDoUpdate updates: ((inout Updates<Self>, Excluded) -> Void)? = nil,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    _insert(
      columns,
      select: selection,
      onConflict: { _ -> ()? in nil },
      where: { _ in return [] },
      doUpdate: updates,
      where: updateFilter
    )
  }

  /// An insert statement for a table selection.
  ///
  /// This function can be used to create an insert statement for the results of a ``Select``
  /// statement.
  ///
  /// - Parameters:
  ///   - conflictResolution: A conflict resolution algorithm.
  ///   - columns: Columns values to be inserted.
  ///   - selection: A statement that selects the values to be inserted.
  ///   - updates: Updates to perform in an upsert clause should the insert conflict with an
  ///     existing row.
  ///   - updateFilter: A filter to apply to the update clause.
  /// - Returns: An insert statement.
  public static func insert<
    V1,
    each V2
  >(
    _ columns: (TableColumns) -> (TableColumn<Self, V1>, repeat TableColumn<Self, each V2>),
    select selection: () -> some PartialSelectStatement<(V1, repeat each V2)>,
    onConflictDoUpdate updates: ((inout Updates<Self>) -> Void)?,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    insert(
      columns,
      select: selection,
      onConflictDoUpdate: updates.map { updates in { row, _ in updates(&row) } },
      where: updateFilter
    )
  }

  /// An insert statement for a table selection.
  ///
  /// This function can be used to create an insert statement for the results of a ``Select``
  /// statement.
  ///
  /// - Parameters:
  ///   - conflictResolution: A conflict resolution algorithm.
  ///   - columns: Columns values to be inserted.
  ///   - selection: A statement that selects the values to be inserted.
  ///   - conflictTargets: Indexed columns to target for conflict resolution.
  ///   - targetFilter: A filter to apply to conflict target columns.
  ///   - updates: Updates to perform in an upsert clause should the insert conflict with an
  ///     existing row.
  ///   - updateFilter: A filter to apply to the update clause.
  /// - Returns: An insert statement.
  public static func insert<
    V1,
    each V2,
    T1,
    each T2
  >(
    _ columns: (TableColumns) -> (TableColumn<Self, V1>, repeat TableColumn<Self, each V2>),
    select selection: () -> some PartialSelectStatement<(V1, repeat each V2)>,
    onConflict conflictTargets: (TableColumns) -> (
      TableColumn<Self, T1>, repeat TableColumn<Self, each T2>
    ),
    @QueryFragmentBuilder<Bool>
    where targetFilter: (TableColumns) -> [QueryFragment] = { _ in [] },
    doUpdate updates: (inout Updates<Self>, Excluded) -> Void = { _, _ in },
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    withoutActuallyEscaping(updates) { updates in
      _insert(
          columns,
        select: selection,
        onConflict: conflictTargets,
        where: targetFilter,
        doUpdate: updates,
        where: updateFilter
      )
    }
  }

  /// An insert statement for a table selection.
  ///
  /// This function can be used to create an insert statement for the results of a ``Select``
  /// statement.
  ///
  /// - Parameters:
  ///   - conflictResolution: A conflict resolution algorithm.
  ///   - columns: Columns values to be inserted.
  ///   - selection: A statement that selects the values to be inserted.
  ///   - conflictTargets: Indexed columns to target for conflict resolution.
  ///   - targetFilter: A filter to apply to conflict target columns.
  ///   - updates: Updates to perform in an upsert clause should the insert conflict with an
  ///     existing row.
  ///   - updateFilter: A filter to apply to the update clause.
  /// - Returns: An insert statement.
  public static func insert<
    V1,
    each V2,
    T1,
    each T2
  >(
    _ columns: (TableColumns) -> (TableColumn<Self, V1>, repeat TableColumn<Self, each V2>),
    select selection: () -> some PartialSelectStatement<(V1, repeat each V2)>,
    onConflict conflictTargets: (TableColumns) -> (
      TableColumn<Self, T1>, repeat TableColumn<Self, each T2>
    ),
    @QueryFragmentBuilder<Bool>
    where targetFilter: (TableColumns) -> [QueryFragment] = { _ in [] },
    doUpdate updates: (inout Updates<Self>) -> Void,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    insert(
      columns,
      select: selection,
      onConflict: conflictTargets,
      where: targetFilter,
      doUpdate: { row, _ in updates(&row) },
      where: updateFilter
    )
  }

  private static func _insert<
    each Value,
    each ConflictTarget
  >(
    _ columns: (TableColumns) -> (repeat TableColumn<Self, each Value>),
    select selection: () -> some PartialSelectStatement<(repeat each Value)>,
    onConflict conflictTargets: (TableColumns) -> (repeat TableColumn<Self, each ConflictTarget>)?,
    @QueryFragmentBuilder<Bool>
    where targetFilter: (TableColumns) -> [QueryFragment] = { _ in [] },
    doUpdate updates: ((inout Updates<Self>, Excluded) -> Void)?,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    var columnNames: [String] = []
    for column in repeat each columns(Self.columns) {
      columnNames.append(column.name)
    }
    return _insert(
      columnNames: columnNames,
      values: .select(selection().query),
      onConflict: conflictTargets,
      where: targetFilter,
      doUpdate: updates,
      where: updateFilter
    )
  }

  /// An insert statement for a table's default values.
  ///
  /// For example:
  ///
  /// ```swift
  /// Reminder.insert()
  /// // INSERT INTO "reminders" DEFAULT VALUES
  /// ```
  ///
  /// - Returns: An insert statement.
  public static func insert() -> InsertOf<Self> {
    _insert(
      columnNames: [],
      values: .default,
      onConflict: { _ -> ()? in nil },
      where: { _ in return [] },
      doUpdate: nil,
      where: { _ in return [] }
    )
  }

  fileprivate static func _insert<each ConflictTarget>(
    columnNames: [String],
    values: InsertValues,
    onConflict conflictTargets: (TableColumns) -> (repeat TableColumn<Self, each ConflictTarget>)?,
    @QueryFragmentBuilder<Bool>
    where targetFilter: (TableColumns) -> [QueryFragment] = { _ in [] },
    doUpdate updates: ((inout Updates<Self>, Excluded) -> Void)?,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    var conflictTargetColumnNames: [String] = []
    if let conflictTargets = conflictTargets(Self.columns) {
      for column in repeat each conflictTargets {
        conflictTargetColumnNames.append(column.name)
      }
    }
    return Insert(
      columnNames: columnNames,
      conflictTargetColumnNames: conflictTargetColumnNames,
      conflictTargetFilter: targetFilter(Self.columns),
      values: values,
      updates: updates.map { updates in Updates { updates(&$0, Excluded.QueryValue.columns) } },
      updateFilter: updateFilter(Self.columns),
      returning: []
    )
  }
}

extension PrimaryKeyedTable {
  /// An insert statement for one or more table rows with PostgreSQL NULL handling.
  ///
  /// This override handles the case where records are mixed with Drafts that have NULL primary keys.
  /// PostgreSQL doesn't allow NULL in PRIMARY KEY columns, so we use DEFAULT instead.
  public static func insert(
    _ columns: (TableColumns) -> TableColumns = { $0 },
    @InsertValuesBuilder<Self> values: () -> [[QueryFragment]],
    onConflictDoUpdate updates: ((inout Updates<Self>, Excluded) -> Void)? = nil,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    // Get the values
    let allValues = values()
    let primaryKeyName = Self.columns.primaryKey.name

    // Check for NULL primary key values
    var hasAnyExplicitPrimaryKey = false
    var hasAnyNullPrimaryKey = false

    for rowValues in allValues {
      for (column, value) in zip(TableColumns.writableColumns, rowValues) {
        if column.name == primaryKeyName {
          if isNullBinding(value) {
            hasAnyNullPrimaryKey = true
          } else {
            hasAnyExplicitPrimaryKey = true
          }
          break
        }
      }
    }

    // If we have mixed values (some NULL, some not), replace NULL with DEFAULT
    if hasAnyExplicitPrimaryKey && hasAnyNullPrimaryKey {
      var processedValues: [[QueryFragment]] = []

      for rowValues in allValues {
        var processedRow: [QueryFragment] = []
        for (column, value) in zip(TableColumns.writableColumns, rowValues) {
          if column.name == primaryKeyName && isNullBinding(value) {
            // Replace NULL with DEFAULT for PostgreSQL
            processedRow.append(.init("DEFAULT"))
          } else {
            processedRow.append(value)
          }
        }
        processedValues.append(processedRow)
      }

      return _insert(
        columnNames: TableColumns.writableColumns.map(\.name),
        values: .values(processedValues),
        onConflict: { _ -> ()? in nil },
        where: { _ in return [] },
        doUpdate: updates,
        where: updateFilter
      )
    }

    // Default behavior for non-mixed cases
    return _insert(
      columnNames: TableColumns.writableColumns.map(\.name),
      values: .values(allValues),
      onConflict: { _ -> ()? in nil },
      where: { _ in return [] },
      doUpdate: updates,
      where: updateFilter
    )
  }

  /// An insert statement with conflict resolution for mixed records/drafts.
  ///
  /// Handles NULL primary keys in Draft values for PostgreSQL compatibility.
  public static func insert<T1, each T2>(
    _ columns: (TableColumns) -> TableColumns = { $0 },
    @InsertValuesBuilder<Self> values: () -> [[QueryFragment]],
    onConflict conflictTargets: (TableColumns) -> (
      TableColumn<Self, T1>, repeat TableColumn<Self, each T2>
    ),
    @QueryFragmentBuilder<Bool>
    where targetFilter: (TableColumns) -> [QueryFragment] = { _ in [] },
    doUpdate updates: (inout Updates<Self>, Excluded) -> Void = { _, _ in },
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    withoutActuallyEscaping(updates) { updates in
      // Get the values
      let allValues = values()
      let primaryKeyName = Self.columns.primaryKey.name

      // Check for NULL primary key values
      var hasAnyExplicitPrimaryKey = false
      var hasAnyNullPrimaryKey = false

      for rowValues in allValues {
        for (column, value) in zip(TableColumns.writableColumns, rowValues) {
          if column.name == primaryKeyName {
            if isNullBinding(value) {
              hasAnyNullPrimaryKey = true
            } else {
              hasAnyExplicitPrimaryKey = true
            }
            break
          }
        }
      }

      // If we have only NULL primary keys, exclude the primary key column entirely
      // This is required for PostgreSQL which doesn't allow NULL in PRIMARY KEY columns
      if hasAnyNullPrimaryKey && !hasAnyExplicitPrimaryKey {
        // Build column names and values excluding the primary key
        var filteredColumnNames: [String] = []
        var filteredValues: [[QueryFragment]] = []

        for (index, rowValues) in allValues.enumerated() {
          var filteredRowValues: [QueryFragment] = []

          // Build column names from first row
          if index == 0 {
            for (columnIndex, column) in TableColumns.writableColumns.enumerated() {
              if column.name != primaryKeyName {
                filteredColumnNames.append(column.name)
              }
            }
          }

          // Build values excluding primary key
          for (column, value) in zip(TableColumns.writableColumns, rowValues) {
            if column.name != primaryKeyName {
              filteredRowValues.append(value)
            }
          }

          filteredValues.append(filteredRowValues)
        }

        return _insert(
          columnNames: filteredColumnNames,
          values: .values(filteredValues),
          onConflict: conflictTargets,
          where: targetFilter,
          doUpdate: updates,
          where: updateFilter
        )
      }

      // If we have mixed values, replace NULL with DEFAULT
      if hasAnyExplicitPrimaryKey && hasAnyNullPrimaryKey {
        var processedValues: [[QueryFragment]] = []

        for rowValues in allValues {
          var processedRow: [QueryFragment] = []
          for (column, value) in zip(TableColumns.writableColumns, rowValues) {
            if column.name == primaryKeyName && isNullBinding(value) {
              processedRow.append(.init("DEFAULT"))
            } else {
              processedRow.append(value)
            }
          }
          processedValues.append(processedRow)
        }

        return _insert(
          columnNames: TableColumns.writableColumns.map(\.name),
          values: .values(processedValues),
          onConflict: conflictTargets,
          where: targetFilter,
          doUpdate: updates,
          where: updateFilter
        )
      }

      // Default behavior
      return _insert(
        columnNames: TableColumns.writableColumns.map(\.name),
        values: .values(allValues),
        onConflict: conflictTargets,
        where: targetFilter,
        doUpdate: updates,
        where: updateFilter
      )
    }
  }

  /// An insert statement with conflict resolution for mixed records/drafts (single update parameter).
  ///
  /// Handles NULL primary keys in Draft values for PostgreSQL compatibility.
  public static func insert<T1, each T2>(
    _ columns: (TableColumns) -> TableColumns = { $0 },
    @InsertValuesBuilder<Self> values: () -> [[QueryFragment]],
    onConflict conflictTargets: (TableColumns) -> (
      TableColumn<Self, T1>, repeat TableColumn<Self, each T2>
    ),
    @QueryFragmentBuilder<Bool>
    where targetFilter: (TableColumns) -> [QueryFragment] = { _ in [] },
    doUpdate updates: (inout Updates<Self>) -> Void,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    // Delegate to the two-parameter version with a wrapper
    insert(
      columns,
      values: values,
      onConflict: conflictTargets,
      where: targetFilter,
      doUpdate: { row, _ in updates(&row) },
      where: updateFilter
    )
  }

  /// Helper function to check if a QueryFragment represents NULL
  private static func isNullBinding(_ fragment: QueryFragment) -> Bool {
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

      // Check for SQL "NULL" literal
      if case .sql(let sql) = segment {
        let trimmed = sql.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if trimmed == "NULL" {
          return true
        }
      }
    }
    return false
  }

  /// An insert statement for one or more draft rows.
  ///
  /// Dynamically handles NULL-valued primary keys for PostgreSQL compatibility.
  /// When all rows have NULL primary keys, excludes the column entirely.
  /// When mixing NULL and non-NULL primary keys, uses DEFAULT for NULL values.
  ///
  /// - Parameters:
  ///   - values: A builder of draft values to insert.
  ///   - onConflictDoUpdate: Updates to perform if the insert conflicts.
  ///   - updateFilter: A filter to apply to the update clause.
  /// - Returns: An insert statement.
  public static func insert(
    @InsertValuesBuilder<Draft> values: () -> [[QueryFragment]],
    onConflictDoUpdate updates: ((inout Updates<Self>, Excluded) -> Void)? = nil,
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    // Build the values using the standard builder
    let allValues = values()

    // Get the primary key column name
    let primaryKeyName = columns.primaryKey.name

    // First pass: check if any row has a non-NULL primary key
    var hasAnyExplicitPrimaryKey = false

    for rowValues in allValues {
      for (column, value) in zip(Draft.TableColumns.writableColumns, rowValues) {
        if column.name == primaryKeyName && !isNullBinding(value) {
          hasAnyExplicitPrimaryKey = true
          break
        }
      }
      if hasAnyExplicitPrimaryKey { break }
    }

    // Process values based on strategy
    var filteredColumnNames: [String] = []
    var filteredValues: [[QueryFragment]] = []

    for rowValues in allValues {
      var filteredRowValues: [QueryFragment] = []

      // Build column names from first row
      if filteredColumnNames.isEmpty {
        for column in Draft.TableColumns.writableColumns {
          // Skip primary key column if no rows have explicit values
          if column.name == primaryKeyName && !hasAnyExplicitPrimaryKey {
            continue
          }
          filteredColumnNames.append(column.name)
        }
      }

      // Build values for this row
      for (column, value) in zip(Draft.TableColumns.writableColumns, rowValues) {
        if column.name == primaryKeyName {
          if hasAnyExplicitPrimaryKey {
            // Include primary key column - use DEFAULT for NULL values
            if isNullBinding(value) {
                filteredRowValues.append(.init("DEFAULT"))
            } else {
              filteredRowValues.append(value)
            }
          }
          // If not including primary key column, skip it entirely
        } else {
          // Always include non-primary-key columns
          filteredRowValues.append(value)
        }
      }

      filteredValues.append(filteredRowValues)
    }

    return _insert(
      columnNames: filteredColumnNames,
      values: .values(filteredValues),
      onConflict: { _ -> ()? in nil },
      where: updateFilter,
      doUpdate: updates
    )
  }

  /// An insert statement with custom conflict resolution for draft rows.
  ///
  /// This method handles Draft inserts with ON CONFLICT clauses while properly
  /// excluding NULL primary keys for PostgreSQL compatibility.
  ///
  /// - Parameters:
  ///   - values: A builder of draft values to insert.
  ///   - conflictTargets: Columns to target for conflict resolution.
  ///   - targetFilter: A filter to apply to conflict target columns.
  ///   - updates: Updates to perform in an upsert clause should the insert conflict.
  ///   - updateFilter: A filter to apply to the update clause.
  /// - Returns: An insert statement.
  public static func insert<T1, each T2>(
    @InsertValuesBuilder<Draft> values: () -> [[QueryFragment]],
    onConflict conflictTargets: (TableColumns) -> (
      TableColumn<Self, T1>, repeat TableColumn<Self, each T2>
    ),
    @QueryFragmentBuilder<Bool>
    where targetFilter: (TableColumns) -> [QueryFragment] = { _ in [] },
    doUpdate updates: (inout Updates<Self>, Excluded) -> Void = { _, _ in },
    @QueryFragmentBuilder<Bool>
    where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
  ) -> InsertOf<Self> {
    // Build the values using the standard builder
    let allValues = values()

    // Get the primary key column name
    let primaryKeyName = columns.primaryKey.name

    // First pass: check if any row has a non-NULL primary key
    var hasAnyExplicitPrimaryKey = false
    var hasAnyNullPrimaryKey = false

    for (index, rowValues) in allValues.enumerated() {
      for (column, value) in zip(Draft.TableColumns.writableColumns, rowValues) {
        if column.name == primaryKeyName {
          if isNullBinding(value) {
            hasAnyNullPrimaryKey = true
          } else {
            hasAnyExplicitPrimaryKey = true
          }
          break
        }
      }
    }

    // For ON CONFLICT with Draft, we need to determine if we should include the primary key
    // PostgreSQL requires that if we're doing ON CONFLICT on a column, it must be in the INSERT
    // 
    // Since we can't easily check the conflict targets at compile time with parameter packs,
    // we'll use a safe approach: if all primary keys are NULL and we have ON CONFLICT,
    // we should include the primary key column with DEFAULT values.
    // This ensures ON CONFLICT on PK will work correctly.
    let shouldIncludePrimaryKey = hasAnyExplicitPrimaryKey || hasAnyNullPrimaryKey

    // Process values based on strategy
    var filteredColumnNames: [String] = []
    var filteredValues: [[QueryFragment]] = []

    for rowValues in allValues {
      var filteredRowValues: [QueryFragment] = []

      // Build column names from first row
      if filteredColumnNames.isEmpty {
        for column in Draft.TableColumns.writableColumns {
          // Skip primary key column only if not needed
          if column.name == primaryKeyName && !shouldIncludePrimaryKey {
            continue
          }
          filteredColumnNames.append(column.name)
        }
      }

      // Build values for this row
      for (column, value) in zip(Draft.TableColumns.writableColumns, rowValues) {
        // Handle primary key specially
        if column.name == primaryKeyName {
          if shouldIncludePrimaryKey {
            // Include primary key column - use DEFAULT for NULL values
            if isNullBinding(value) {
              // Replace NULL with DEFAULT for PostgreSQL
              filteredRowValues.append(QueryFragment("DEFAULT"))
            } else {
              filteredRowValues.append(value)
            }
          }
          // If not including primary key column, skip it entirely
        } else {
          // Always include non-primary-key columns
          filteredRowValues.append(value)
        }
      }

      filteredValues.append(filteredRowValues)
    }

    return withoutActuallyEscaping(updates) { updates in
      _insert(
        columnNames: filteredColumnNames,
        values: .values(filteredValues),
        onConflict: conflictTargets,
        where: targetFilter,
        doUpdate: updates,
        where: updateFilter
      )
    }
  }

  /// An upsert statement for given drafts.
  ///
  /// Generates an insert statement with an upsert clause. Useful for building forms that can both
  /// insert new records as well as update them.
  ///
  /// ```swift
  /// Reminder.upsert { draft }
  /// // INSERT INTO "reminders" ("id", …)
  /// // VALUES (1, …)
  /// // ON CONFLICT DO UPDATE SET "…" = "excluded"."…", …
  /// ```
  ///
  /// - Parameters:
  ///   - values: A builder of draft values for the given columns.
  /// - Returns: An insert statement with an upsert clause.
  public static func upsert(
    @InsertValuesBuilder<Draft> values: () -> [[QueryFragment]]
  ) -> InsertOf<Self> {
    // Build the values using the standard builder
    let allValues = values()

    // Get the primary key column name
    let primaryKeyName = columns.primaryKey.name

    // For PostgreSQL upsert, we need to include the primary key column
    // even if it's NULL (using DEFAULT)
    var filteredColumnNames: [String] = []
    var filteredValues: [[QueryFragment]] = []

    // First pass: check if any value has explicit primary key
    var hasAnyExplicitPrimaryKey = false
    for rowValues in allValues {
      for (column, value) in zip(Draft.TableColumns.writableColumns, rowValues) {
        if column.name == primaryKeyName && !isNullBinding(value) {
          hasAnyExplicitPrimaryKey = true
          break
        }
      }
      if hasAnyExplicitPrimaryKey { break }
    }

    // Build columns list (always include primary key for upsert)
    for column in Draft.TableColumns.writableColumns {
      filteredColumnNames.append(column.name)
    }

    // Process values
    for rowValues in allValues {
      var filteredRowValues: [QueryFragment] = []

      for (column, value) in zip(Draft.TableColumns.writableColumns, rowValues) {
        if column.name == primaryKeyName && isNullBinding(value) {
          // For upsert, use DEFAULT for NULL primary keys
          filteredRowValues.append(QueryFragment("DEFAULT"))
        } else {
          filteredRowValues.append(value)
        }
      }

      filteredValues.append(filteredRowValues)
    }

    // For UPSERT, we use ON CONFLICT on the primary key
    return _insert(
      columnNames: filteredColumnNames,
      values: .values(filteredValues),
      onConflict: { cols in cols.primaryKey },
      doUpdate: { updates, _ in
        // Update all columns except the primary key
        // We need to match the filtered columns with excluded columns
        for columnName in filteredColumnNames {
          if columnName != primaryKeyName {
            // Find the matching excluded column
            if let excludedColumn = Excluded.writableColumns.first(where: { $0.name == columnName }) {
              // Find the original column to set
              if let originalColumn = Draft.TableColumns.writableColumns.first(where: { $0.name == columnName }) {
                updates.set(originalColumn, excludedColumn.queryFragment)
              }
            }
          }
        }
      }
    )
  }
}

private enum InsertValues {
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
public struct Insert<Into: Table, Returning> {
  var columnNames: [String]
  var conflictTargetColumnNames: [String]
  var conflictTargetFilter: [QueryFragment]
  fileprivate var values: InsertValues
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

  // NB: This overload allows for 'returning(\.self)'.
  /// Adds a returning clause to an insert statement.
  ///
  /// - Parameter selection: Columns to return.
  /// - Returns: A statement with a returning clause.
  @_documentation(visibility: private)
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
        query.append(conflictTargetColumnNames.map { "\(quote: $0)" }.joined(separator: ", "))
        query.append(")\(.newlineOrSpace)")
        if !conflictTargetFilter.isEmpty {
          query.append("WHERE \(conflictTargetFilter.joined(separator: " AND "))\(.newlineOrSpace)")
        }
      }
      query.append("DO ")
      if updates.isEmpty {
        query.append("NOTHING")
        hasInvalidWhere = !updateFilter.isEmpty
      } else {
        query.append("UPDATE \(bind: updates)")
        if !updateFilter.isEmpty {
          query.append("\(.newlineOrSpace)WHERE \(updateFilter.joined(separator: " AND "))")
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

/// A builder of insert statement values.
///
/// This result builder is used by ``Table/insert(or:_:values:onConflict:where:doUpdate:where:)`` to
/// insert any number of rows into a table.
@resultBuilder
public enum InsertValuesBuilder<Value> {
  public static func buildExpression(_ expression: [Value]) -> [[QueryFragment]]
  where Value: Table {
    var valueFragments: [[QueryFragment]] = []
    for value in expression {
      var valueFragment: [QueryFragment] = []
      for column in Value.TableColumns.writableColumns {
        func open<Root, Member>(
          _ column: some WritableTableColumnExpression<Root, Member>
        ) -> QueryFragment {
          Member(queryOutput: (value as! Root)[keyPath: column.keyPath]).queryFragment
        }
        valueFragment.append(open(column))
      }
      valueFragments.append(valueFragment)
    }
    return valueFragments
  }

  @_disfavoredOverload
  public static func buildExpression(_ expression: [Value.Draft]) -> [[QueryFragment]]
  where Value: PrimaryKeyedTable {
    var valueFragments: [[QueryFragment]] = []
    for value in expression {
      var valueFragment: [QueryFragment] = []
      for column in Value.Draft.TableColumns.writableColumns {
        func open<Root, Member>(
          _ column: some WritableTableColumnExpression<Root, Member>
        ) -> QueryFragment {
          Member(queryOutput: (value as! Root)[keyPath: column.keyPath]).queryFragment
        }
        valueFragment.append(open(column))
      }
      valueFragments.append(valueFragment)
    }
    return valueFragments
  }

  @_disfavoredOverload
  public static func buildExpression<V: QueryExpression>(
    _ expression: [V]
  ) -> [[QueryFragment]]
  where
    Value == V.QueryValue,
    V.QueryValue: QueryRepresentable & QueryBindable {
    [expression.map(\.queryFragment)]
  }

  @_disfavoredOverload
  public static func buildExpression(
    _ expression: [Value.QueryOutput]
  ) -> [[QueryFragment]]
  where Value: QueryRepresentable & QueryBindable {
    [expression.map { Value(queryOutput: $0).queryFragment }]
  }

  public static func buildExpression(_ expression: Value) -> [[QueryFragment]]
  where Value: Table {
    buildExpression([expression])
  }

  public static func buildExpression(_ expression: Value.Draft) -> [[QueryFragment]]
  where Value: PrimaryKeyedTable {
    buildExpression([expression])
  }

  @_disfavoredOverload
  public static func buildExpression<V: QueryExpression>(
    _ expression: V
  ) -> [[QueryFragment]]
  where
    Value == V.QueryValue,
    V.QueryValue: QueryRepresentable & QueryBindable {
    buildExpression([expression])
  }

  public static func buildExpression(
    _ expression: Value.QueryOutput
  ) -> [[QueryFragment]]
  where Value: QueryRepresentable & QueryBindable {
    buildExpression([expression])
  }

  @_disfavoredOverload
  public static func buildExpression<each V: QueryExpression>(
    _ expression: (repeat each V)
  ) -> [[QueryFragment]]
  where
    Value == (repeat (each V).QueryValue),
    repeat (each V).QueryValue: QueryRepresentable & QueryBindable {
    var valueFragment: [QueryFragment] = []
    for column in repeat each expression {
      valueFragment.append(column.queryFragment)
    }
    return [valueFragment]
  }

  public static func buildExpression<each V: QueryRepresentable & QueryBindable>(
    _ expression: (repeat (each V).QueryOutput)
  ) -> [[QueryFragment]]
  where Value == (repeat each V) {
    var valueFragment: [QueryFragment] = []
    for (columnType, column) in repeat ((each V).self, each expression) {
      valueFragment.append(columnType.init(queryOutput: column).queryFragment)
    }
    return [valueFragment]
  }

  public static func buildExpression(
    _ expression: Value.Columns
  ) -> [[QueryFragment]]
  where Value: _Selection {
    [expression.selection.map(\.expression)]
  }

  public static func buildArray(_ components: [[[QueryFragment]]]) -> [[QueryFragment]] {
    components.flatMap(\.self)
  }

  public static func buildBlock(_ components: [[QueryFragment]]) -> [[QueryFragment]] {
    components
  }

  public static func buildEither(first component: [[QueryFragment]]) -> [[QueryFragment]] {
    component
  }

  public static func buildEither(second component: [[QueryFragment]]) -> [[QueryFragment]] {
    component
  }

  public static func buildLimitedAvailability(_ component: [[QueryFragment]]) -> [[QueryFragment]] {
    component
  }

  public static func buildOptional(_ component: [[QueryFragment]]?) -> [[QueryFragment]] {
    component ?? []
  }

  public static func buildPartialBlock(first: [[QueryFragment]]) -> [[QueryFragment]] {
    first
  }

  public static func buildPartialBlock(
    accumulated: [[QueryFragment]],
    next: [[QueryFragment]]
  ) -> [[QueryFragment]] {
    accumulated + next
  }
}

public struct _ExcludedName: AliasName {
  public static var aliasName: String { "excluded" }
}
