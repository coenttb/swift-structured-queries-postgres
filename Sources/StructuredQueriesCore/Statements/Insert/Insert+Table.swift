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
            where: [],
            doUpdate: updates,
            where: updateFilter(Self.columns)
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
                where: targetFilter(Self.columns),
                doUpdate: updates,
                where: updateFilter(Self.columns)
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
    public static func insert<V1: _TableColumnExpression, each V2: _TableColumnExpression>(
        _ columns: (TableColumns) -> (V1, repeat each V2),
        @InsertValuesBuilder<(V1.Value, repeat (each V2).Value)>
        values: () -> [[QueryFragment]],
        onConflictDoUpdate updates: ((inout Updates<Self>, Excluded) -> Void)? = nil,
        @QueryFragmentBuilder<Bool>
        where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
    ) -> InsertOf<Self> {
        _insert(
            columns,
            values: values,
            onConflict: { _ -> ()? in nil },
            where: [],
            doUpdate: updates,
            where: updateFilter(Self.columns)
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
    public static func insert<V1: _TableColumnExpression, each V2: _TableColumnExpression>(
        _ columns: (TableColumns) -> (V1, repeat each V2),
        @InsertValuesBuilder<(V1.Value, repeat (each V2).Value)>
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
    public static func insert<
        V1: _TableColumnExpression,
        each V2: _TableColumnExpression,
        T1: _TableColumnExpression,
        each T2: _TableColumnExpression
    >(
        _ columns: (TableColumns) -> (V1, repeat each V2),
        @InsertValuesBuilder<(V1.Value, repeat (each V2).Value)>
        values: () -> [[QueryFragment]],
        onConflict conflictTargets: (TableColumns) -> (T1, repeat each T2),
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
                where: targetFilter(Self.columns),
                doUpdate: updates,
                where: updateFilter(Self.columns)
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
    public static func insert<
        V1: _TableColumnExpression,
        each V2: _TableColumnExpression,
        T1: _TableColumnExpression,
        each T2: _TableColumnExpression
    >(
        _ columns: (TableColumns) -> (V1, repeat each V2),
        @InsertValuesBuilder<(V1.Value, repeat (each V2).Value)>
        values: () -> [[QueryFragment]],
        onConflict conflictTargets: (TableColumns) -> (T1, repeat each T2),
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

    private static func _insert<
        each Value: _TableColumnExpression,
        each ConflictTarget: _TableColumnExpression
    >(
        _ columns: (TableColumns) -> (repeat each Value),
        @InsertValuesBuilder<(repeat (each Value).Value)>
        values: () -> [[QueryFragment]],
        onConflict conflictTargets: (TableColumns) -> (repeat each ConflictTarget)?,
        where targetFilter: [QueryFragment] = [],
        doUpdate updates: ((inout Updates<Self>, Excluded) -> Void)?,
        where updateFilter: [QueryFragment] = []
    ) -> InsertOf<Self> {
        var columnNames: [String] = []
        for column in repeat each columns(Self.columns) {
            columnNames.append(contentsOf: column._names)
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
        V1: _TableColumnExpression,
        each V2: _TableColumnExpression
    >(
        _ columns: (TableColumns) -> (V1, repeat each V2),
        select selection: () -> some PartialSelectStatement<(V1.Value, repeat (each V2).Value)>,
        onConflictDoUpdate updates: ((inout Updates<Self>, Excluded) -> Void)? = nil,
        @QueryFragmentBuilder<Bool>
        where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
    ) -> InsertOf<Self> {
        _insert(
            columns,
            select: selection,
            onConflict: { _ -> ()? in nil },
            where: [],
            doUpdate: updates,
            where: updateFilter(Self.columns)
        )
    }

    // NB: This overload is required due to a parameter pack bug.
    public static func insert<V1: _TableColumnExpression>(
        _ columns: (TableColumns) -> V1,
        select selection: () -> some PartialSelectStatement<V1.Value>,
        onConflictDoUpdate updates: ((inout Updates<Self>, Excluded) -> Void)? = nil,
        @QueryFragmentBuilder<Bool>
        where updateFilter: (TableColumns) -> [QueryFragment] = { _ in [] }
    ) -> InsertOf<Self> {
        _insert(
            columns,
            select: selection,
            onConflict: { _ -> ()? in nil },
            where: [],
            doUpdate: updates,
            where: updateFilter(Self.columns)
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
        V1: _TableColumnExpression,
        each V2: _TableColumnExpression
    >(
        _ columns: (TableColumns) -> (V1, repeat each V2),
        select selection: () -> some PartialSelectStatement<(V1.Value, repeat (each V2).Value)>,
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
        V1: _TableColumnExpression,
        each V2: _TableColumnExpression,
        T1: _TableColumnExpression,
        each T2: _TableColumnExpression
    >(
        _ columns: (TableColumns) -> (V1, repeat each V2),
        select selection: () -> some PartialSelectStatement<(V1.Value, repeat (each V2).Value)>,
        onConflict conflictTargets: (TableColumns) -> (T1, repeat each T2),
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
                where: targetFilter(Self.columns),
                doUpdate: updates,
                where: updateFilter(Self.columns)
            )
        }
    }

    // NB: This overload is required due to a parameter pack bug.
    public static func insert<
        V1: _TableColumnExpression,
        T1: _TableColumnExpression,
        each T2: _TableColumnExpression
    >(
        _ columns: (TableColumns) -> V1,
        select selection: () -> some PartialSelectStatement<V1.Value>,
        onConflict conflictTargets: (TableColumns) -> (T1, repeat each T2),
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
                where: targetFilter(Self.columns),
                doUpdate: updates,
                where: updateFilter(Self.columns)
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
        V1: _TableColumnExpression,
        each V2: _TableColumnExpression,
        T1: _TableColumnExpression,
        each T2: _TableColumnExpression
    >(
        _ columns: (TableColumns) -> (V1, repeat each V2),
        select selection: () -> some PartialSelectStatement<(V1.Value, repeat (each V2).Value)>,
        onConflict conflictTargets: (TableColumns) -> (T1, repeat each T2),
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

    // NB: This overload is required due to a parameter pack bug.
    public static func insert<
        V1: _TableColumnExpression,
        T1: _TableColumnExpression,
        each T2: _TableColumnExpression
    >(
        _ columns: (TableColumns) -> V1,
        select selection: () -> some PartialSelectStatement<V1.Value>,
        onConflict conflictTargets: (TableColumns) -> (T1, repeat each T2),
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

    // NB: We should constrain these generics `where Root == Self` when Swift supports same-type
    //     constraints in parameter packs.
    private static func _insert<
        each Value: _TableColumnExpression,
        each ConflictTarget: _TableColumnExpression
    >(
        _ columns: (TableColumns) -> (repeat each Value),
        select selection: () -> some PartialSelectStatement<(repeat (each Value).Value)>,
        onConflict conflictTargets: (TableColumns) -> (repeat each ConflictTarget)?,
        where targetFilter: [QueryFragment] = [],
        doUpdate updates: ((inout Updates<Self>, Excluded) -> Void)?,
        where updateFilter: [QueryFragment] = []
    ) -> InsertOf<Self> {
        var columnNames: [String] = []
        for column in repeat each columns(Self.columns) {
            columnNames.append(contentsOf: column._names)
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
            where: [],
            doUpdate: nil,
            where: []
        )
    }

    package static func _insert<each ConflictTarget: _TableColumnExpression>(
        columnNames: [String],
        values: InsertValues,
        onConflict conflictTargets: (TableColumns) -> (repeat each ConflictTarget)?,
        where targetFilter: [QueryFragment] = [],
        doUpdate updates: ((inout Updates<Self>, Excluded) -> Void)?,
        where updateFilter: [QueryFragment] = []
    ) -> InsertOf<Self> {
        var conflictTargetColumnNames: [String] = []
        if let conflictTargets = conflictTargets(Self.columns) {
            for column in repeat each conflictTargets {
                conflictTargetColumnNames.append(contentsOf: column._names)
            }
        }
        return Insert(
            columnNames: columnNames,
            conflictTargetColumnNames: conflictTargetColumnNames,
            conflictTargetFilter: targetFilter,
            values: values,
            updates: updates.map { updates in Updates { updates(&$0, Excluded.QueryValue.columns) }
            },
            updateFilter: updateFilter,
            returning: []
        )
    }
}
