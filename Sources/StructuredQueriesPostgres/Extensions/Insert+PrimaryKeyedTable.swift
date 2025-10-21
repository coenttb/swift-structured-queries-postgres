import Foundation

extension PrimaryKeyedTable where TableColumns.PrimaryColumn: TableColumnExpression {
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

        // Get ALL primary key column names (handles both single columns and column groups)
        let primaryKeyNames = Set(Self.columns.primaryKey._names)

        // Check for NULL primary key values
        var hasAnyExplicitPrimaryKey = false
        var hasAnyNullPrimaryKey = false

        for rowValues in allValues {
            for (column, value) in zip(TableColumns.writableColumns, rowValues) {
                // Check if this column is part of the primary key
                // For column groups, check if ANY name in the column is a primary key name
                let columnNames = Set(column._names)
                let isPrimaryKeyColumn = !columnNames.isDisjoint(with: primaryKeyNames)

                if isPrimaryKeyColumn {
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
                    let columnNames = Set(column._names)
                    let isPrimaryKeyColumn = !columnNames.isDisjoint(with: primaryKeyNames)

                    if isPrimaryKeyColumn && isNullBinding(value) {
                        // Replace NULL with DEFAULT for PostgreSQL
                        processedRow.append(QueryFragment("DEFAULT"))
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
                where: [],
                doUpdate: updates,
                where: updateFilter(Self.columns)
            )
        }

        // Default behavior for non-mixed cases
        return _insert(
            columnNames: TableColumns.writableColumns.map(\.name),
            values: .values(allValues),
            onConflict: { _ -> ()? in nil },
            where: [],
            doUpdate: updates,
            where: updateFilter(Self.columns)
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

            // Get ALL primary key column names (handles both single columns and column groups)
            let primaryKeyNames = Set(Self.columns.primaryKey._names)

            // Check for NULL primary key values
            var hasAnyExplicitPrimaryKey = false
            var hasAnyNullPrimaryKey = false

            for rowValues in allValues {
                for (column, value) in zip(TableColumns.writableColumns, rowValues) {
                    let columnNames = Set(column._names)
                    let isPrimaryKeyColumn = !columnNames.isDisjoint(with: primaryKeyNames)

                    if isPrimaryKeyColumn {
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
                        for column in TableColumns.writableColumns {
                            let columnNames = Set(column._names)
                            let isPrimaryKeyColumn = !columnNames.isDisjoint(with: primaryKeyNames)

                            if !isPrimaryKeyColumn {
                                // For column groups, append all names
                                filteredColumnNames.append(contentsOf: column._names)
                            }
                        }
                    }

                    // Build values excluding primary key
                    for (column, value) in zip(TableColumns.writableColumns, rowValues) {
                        let columnNames = Set(column._names)
                        let isPrimaryKeyColumn = !columnNames.isDisjoint(with: primaryKeyNames)

                        if !isPrimaryKeyColumn {
                            filteredRowValues.append(value)
                        }
                    }

                    filteredValues.append(filteredRowValues)
                }

                return _insert(
                    columnNames: filteredColumnNames,
                    values: .values(filteredValues),
                    onConflict: conflictTargets,
                    where: targetFilter(Self.columns),
                    doUpdate: updates,
                    where: updateFilter(Self.columns)
                )
            }

            // If we have mixed values, replace NULL with DEFAULT
            if hasAnyExplicitPrimaryKey && hasAnyNullPrimaryKey {
                var processedValues: [[QueryFragment]] = []

                for rowValues in allValues {
                    var processedRow: [QueryFragment] = []
                    for (column, value) in zip(TableColumns.writableColumns, rowValues) {
                        let columnNames = Set(column._names)
                        let isPrimaryKeyColumn = !columnNames.isDisjoint(with: primaryKeyNames)

                        if isPrimaryKeyColumn && isNullBinding(value) {
                            processedRow.append(QueryFragment("DEFAULT"))
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
                    where: targetFilter(Self.columns),
                    doUpdate: updates,
                    where: updateFilter(Self.columns)
                )
            }

            // Default behavior
            return _insert(
                columnNames: TableColumns.writableColumns.map(\.name),
                values: .values(allValues),
                onConflict: conflictTargets,
                where: targetFilter(Self.columns),
                doUpdate: updates,
                where: updateFilter(Self.columns)
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

        // Get ALL primary key column names (handles both single columns and column groups)
        let primaryKeyNames = Set(columns.primaryKey._names)

        // First pass: check if any row has a non-NULL primary key
        var hasAnyExplicitPrimaryKey = false

        for rowValues in allValues {
            for (column, value) in zip(Draft.TableColumns.writableColumns, rowValues) {
                let columnNames = Set(column._names)
                let isPrimaryKeyColumn = !columnNames.isDisjoint(with: primaryKeyNames)

                if isPrimaryKeyColumn && !isNullBinding(value) {
                    hasAnyExplicitPrimaryKey = true
                    break
                }
            }
            if hasAnyExplicitPrimaryKey { break }
        }

        // Process values - always include all columns to match upstream behavior
        // PostgreSQL translation: Replace NULL with DEFAULT for primary keys
        var filteredColumnNames: [String] = []
        var filteredValues: [[QueryFragment]] = []

        // Build column names from Draft columns (include all columns)
        for column in Draft.TableColumns.writableColumns {
            filteredColumnNames.append(contentsOf: column._names)
        }

        // Process each row
        for rowValues in allValues {
            var filteredRowValues: [QueryFragment] = []

            for (column, value) in zip(Draft.TableColumns.writableColumns, rowValues) {
                let columnNames = Set(column._names)
                let isPrimaryKeyColumn = !columnNames.isDisjoint(with: primaryKeyNames)

                if isPrimaryKeyColumn && isNullBinding(value) {
                    // PostgreSQL: Translate NULL to DEFAULT for primary key columns
                    // Upstream SQLite uses NULL here, but PostgreSQL requires DEFAULT
                    filteredRowValues.append(QueryFragment("DEFAULT"))
                } else {
                    filteredRowValues.append(value)
                }
            }

            filteredValues.append(filteredRowValues)
        }

        return _insert(
            columnNames: filteredColumnNames,
            values: .values(filteredValues),
            onConflict: { _ -> ()? in nil },
            where: [],
            doUpdate: updates,
            where: updateFilter(Self.columns)
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

        // Get ALL primary key column names (handles both single columns and column groups)
        let primaryKeyNames = Set(columns.primaryKey._names)

        // First pass: check if any row has a non-NULL primary key
        var hasAnyExplicitPrimaryKey = false
        var hasAnyNullPrimaryKey = false

        for (_, rowValues) in allValues.enumerated() {
            for (column, value) in zip(Draft.TableColumns.writableColumns, rowValues) {
                let columnNames = Set(column._names)
                let isPrimaryKeyColumn = !columnNames.isDisjoint(with: primaryKeyNames)

                if isPrimaryKeyColumn {
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
                    let columnNames = Set(column._names)
                    let isPrimaryKeyColumn = !columnNames.isDisjoint(with: primaryKeyNames)

                    // Skip primary key column only if not needed
                    if isPrimaryKeyColumn && !shouldIncludePrimaryKey {
                        continue
                    }
                    // For column groups, append all names
                    filteredColumnNames.append(contentsOf: column._names)
                }
            }

            // Build values for this row
            for (column, value) in zip(Draft.TableColumns.writableColumns, rowValues) {
                let columnNames = Set(column._names)
                let isPrimaryKeyColumn = !columnNames.isDisjoint(with: primaryKeyNames)

                // Handle primary key specially
                if isPrimaryKeyColumn {
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
                where: targetFilter(Self.columns),
                doUpdate: updates,
                where: updateFilter(Self.columns)
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

        // Get ALL primary key column names (handles both single columns and column groups)
        let primaryKeyNames = Set(columns.primaryKey._names)

        // For PostgreSQL upsert, we need to include the primary key column
        // even if it's NULL (using DEFAULT)
        var filteredColumnNames: [String] = []
        var filteredValues: [[QueryFragment]] = []

        // First pass: check if any value has explicit primary key
        var hasAnyExplicitPrimaryKey = false
        for rowValues in allValues {
            for (column, value) in zip(Draft.TableColumns.writableColumns, rowValues) {
                let columnNames = Set(column._names)
                let isPrimaryKeyColumn = !columnNames.isDisjoint(with: primaryKeyNames)

                if isPrimaryKeyColumn && !isNullBinding(value) {
                    hasAnyExplicitPrimaryKey = true
                    break
                }
            }
            if hasAnyExplicitPrimaryKey { break }
        }

        // Build columns list (always include primary key for upsert)
        for column in Draft.TableColumns.writableColumns {
            // For column groups, append all names
            filteredColumnNames.append(contentsOf: column._names)
        }

        // Process values
        for rowValues in allValues {
            var filteredRowValues: [QueryFragment] = []

            for (column, value) in zip(Draft.TableColumns.writableColumns, rowValues) {
                let columnNames = Set(column._names)
                let isPrimaryKeyColumn = !columnNames.isDisjoint(with: primaryKeyNames)

                if isPrimaryKeyColumn && isNullBinding(value) {
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
            where: [],
            doUpdate: { updates, _ in
                // Update all columns except the primary key
                // We need to match the filtered columns with excluded columns
                for columnName in filteredColumnNames {
                    // Skip if this column name is part of the primary key
                    if !primaryKeyNames.contains(columnName) {
                        // Find the matching excluded column
                        if let excludedColumn = Excluded.writableColumns.first(where: {
                            $0.name == columnName
                        }) {
                            // Find the original column to set
                            if let originalColumn = Draft.TableColumns.writableColumns.first(
                                where: { $0.name == columnName })
                            {
                                updates.set(originalColumn, excludedColumn.queryFragment)
                            }
                        }
                    }
                }
            },
            where: []
        )
    }
}
