import Foundation
import StructuredQueriesCore

// MARK: - JSONB.Index

extension JSONB {
    /// Namespace for JSONB indexing operations
    ///
    /// Provides utilities for creating PostgreSQL indexes on JSONB columns:
    /// - GIN indexes (recommended for JSONB)
    /// - B-tree indexes (for equality checks)
    /// - Path-specific indexes
    public enum Index {}
}

// MARK: - JSONB.Index.GIN

extension JSONB.Index {
    /// PostgreSQL GIN (Generalized Inverted Index) operator classes for JSONB indexing
    ///
    /// GIN indexes are the recommended index type for JSONB columns.
    /// PostgreSQL provides two operator classes with different trade-offs:
    ///
    /// - `jsonb_ops`: Default operator class that indexes all keys and values
    /// - `jsonb_path_ops`: Specialized operator class that indexes only values
    ///
    /// See [PostgreSQL Documentation](https://www.postgresql.org/docs/current/datatype-json.html#JSON-INDEXING)
    /// for detailed information about JSONB indexing strategies.
    public enum GIN: String, Sendable {
        // Mirrors PostgreSQL's operator-class name `jsonb_ops` verbatim.
        // swift-format-ignore: AlwaysUseLowerCamelCase
        /// Default operator class - indexes all keys and values
        ///
        /// **Supports operators:** `@>`, `@?`, `@@`, `?`, `?|`, `?&`
        ///
        /// **Use when:**
        /// - You use key existence operators (`?`, `?|`, `?&`)
        /// - You query both keys and values
        /// - You need maximum query flexibility
        ///
        /// **Trade-offs:**
        /// - Larger index size (30-50% more than jsonb_path_ops)
        /// - Slightly slower containment queries
        /// - More flexible querying capabilities
        case jsonb_ops

        // Mirrors PostgreSQL's operator-class name `jsonb_path_ops` verbatim.
        // swift-format-ignore: AlwaysUseLowerCamelCase
        /// Path operator class - indexes only values (more specific)
        ///
        /// **Supports operators:** `@>`, `@?`, `@@`
        ///
        /// **Use when:**
        /// - You primarily use containment queries (`@>`)
        /// - You want smaller indexes
        /// - You want faster containment queries
        ///
        /// **Trade-offs:**
        /// - No support for key existence operators (`?`, `?|`, `?&`)
        /// - Less query flexibility
        /// - Smaller index size (20-30% smaller)
        /// - Faster containment queries
        ///
        /// **Note:** Does not create index entries for JSON structures that don't contain any values.
        case jsonb_path_ops
    }
}

// MARK: - JSONB.Index Path Literal Escaping

extension JSONB.Index {
    /// Renders a JSON path as a properly escaped PostgreSQL array-literal SQL string.
    ///
    /// `CREATE INDEX` expressions are DDL and cannot bind parameters the way `SELECT`/
    /// `UPDATE` statements can, so the path has to be embedded directly in the SQL
    /// text. Each element that contains a comma, brace, double quote, backslash,
    /// whitespace, is empty, or is the literal token `NULL` is double-quoted per
    /// PostgreSQL's array literal syntax (with `\` and `"` backslash-escaped inside the
    /// quoted element). The resulting `{...}` array literal is then escaped for safe
    /// embedding inside a single-quoted SQL string literal, so a path element cannot
    /// break out of the literal and inject additional SQL.
    ///
    /// - Parameter path: The JSON path elements to render.
    /// - Returns: A single-quoted SQL string literal, e.g. `'{address,city}'`.
    fileprivate static func pathLiteral(_ path: [String]) -> String {
        let elements = path.map { element -> String in
            let needsQuoting =
                element.isEmpty
                || element.uppercased() == "NULL"
                || element.contains(where: { ",{}\"\\".contains($0) || $0.isWhitespace })
            guard needsQuoting else { return element }
            let escaped =
                element
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
            return "\"\(escaped)\""
        }
        let arrayLiteral = "{" + elements.joined(separator: ",") + "}"
        return "'\(arrayLiteral.escapedForPostgreSQL())'"
    }
}

// MARK: - Table Extensions for JSONB Indexes

extension Table {
    /// Create a GIN index on a JSONB column
    ///
    /// GIN (Generalized Inverted Index) is the recommended index type for JSONB columns,
    /// providing efficient support for containment and existence queries.
    ///
    /// ```swift
    /// // In your migration:
    /// try await db.execute(
    ///     UserProfile.createGINIndex(on: \.settings, operatorClass: .jsonb_path_ops)
    /// )
    /// // CREATE INDEX "idx_user_profiles_settings_gin"
    /// // ON "user_profiles"
    /// // USING GIN ("settings" jsonb_path_ops)
    /// ```
    ///
    /// **Performance Impact:**
    /// - 10-1000x faster containment queries
    /// - Enables efficient key existence checks
    /// - Allows PostgreSQL to use index scans instead of sequential scans
    ///
    /// **Index Size:**
    /// - `jsonb_ops`: Larger (indexes all keys and values)
    /// - `jsonb_path_ops`: Smaller (indexes only values)
    ///
    /// - Parameters:
    ///   - name: Optional custom index name. If nil, generates name from table and column.
    ///   - column: KeyPath to the JSONB column to index
    ///   - operatorClass: GIN operator class (default: jsonb_ops)
    /// - Returns: SQL fragment for index creation
    public static func createGINIndex(
        name: String? = nil,
        on column: KeyPath<TableColumns, TableColumn<Self, some _JSONBRepresentationProtocol>>,
        operatorClass: JSONB.Index.GIN = .jsonb_ops
    ) -> QueryFragment {
        let col = columns[keyPath: column]
        let indexName = name ?? "idx_\(tableName)_\(col.name)_gin"
        let opClass = operatorClass == .jsonb_ops ? "" : " \(operatorClass.rawValue)"

        var fragment: QueryFragment = "CREATE INDEX \(quote: indexName) ON "
        if let schemaName {
            fragment.append("\(quote: schemaName).")
        }
        fragment.append("\(quote: tableName) USING GIN (\(quote: col.name)\(raw: opClass))")

        return fragment
    }

    /// Create a GIN index on a specific JSONB path expression
    ///
    /// Expression indexes allow you to index specific nested paths within JSONB documents,
    /// providing even better performance for queries that always access the same path.
    ///
    /// ```swift
    /// try await db.execute(
    ///     UserProfile.createGINIndexPath(
    ///         on: \.metadata,
    ///         path: ["stats", "visits"]
    ///     )
    /// )
    /// // CREATE INDEX "idx_user_profiles_metadata_stats_visits_gin"
    /// // ON "user_profiles"
    /// // USING GIN (("metadata" #> '{stats,visits}'))
    /// ```
    ///
    /// **Use this when:**
    /// - You frequently query specific nested paths
    /// - You want targeted, fast queries
    /// - Your queries have predictable patterns
    ///
    /// **Example query that benefits:**
    /// ```swift
    /// UserProfile.where { $0.metadata.value(at: ["stats", "visits"]) > 100 }
    /// ```
    ///
    /// - Parameters:
    ///   - name: Optional custom index name
    ///   - column: KeyPath to the JSONB column
    ///   - path: Path to the nested element to index
    ///   - operatorClass: GIN operator class (default: jsonb_ops)
    /// - Returns: SQL fragment for expression index creation
    public static func createGINIndexPath(
        name: String? = nil,
        on column: KeyPath<TableColumns, TableColumn<Self, some _JSONBRepresentationProtocol>>,
        path: [String],
        operatorClass: JSONB.Index.GIN = .jsonb_ops
    ) -> QueryFragment {
        let col = columns[keyPath: column]
        let indexName = name ?? "idx_\(tableName)_\(col.name)_\(path.joined(separator: "_"))_gin"
        let pathExpr = JSONB.Index.pathLiteral(path)
        let opClass = operatorClass == .jsonb_ops ? "" : " \(operatorClass.rawValue)"

        var fragment: QueryFragment = "CREATE INDEX \(quote: indexName) ON "
        if let schemaName {
            fragment.append("\(quote: schemaName).")
        }
        fragment.append(
            "\(quote: tableName) USING GIN ((\(quote: col.name) #> \(raw: pathExpr))\(raw: opClass))"
        )

        return fragment
    }

    /// Create a B-tree index on a JSONB column for equality checks
    ///
    /// B-tree indexes are useful for complete document equality comparisons.
    /// For partial matches and containment, use GIN indexes instead.
    ///
    /// ```swift
    /// try await db.execute(
    ///     UserProfile.createBTreeIndex(on: \.settings)
    /// )
    /// // CREATE INDEX "idx_user_profiles_settings_btree"
    /// // ON "user_profiles"
    /// // USING BTREE ("settings")
    /// ```
    ///
    /// **Use this when:**
    /// - You primarily check for exact document equality (`=`, `!=`)
    /// - You don't need containment or key existence queries
    ///
    /// **Example query that benefits:**
    /// ```swift
    /// UserProfile.where { $0.settings == specificSettings }
    /// ```
    ///
    /// **Note:** For most JSONB use cases, GIN indexes are more appropriate.
    ///
    /// - Parameters:
    ///   - name: Optional custom index name
    ///   - column: KeyPath to the JSONB column to index
    /// - Returns: SQL fragment for B-tree index creation
    public static func createBTreeIndex(
        name: String? = nil,
        on column: KeyPath<TableColumns, TableColumn<Self, some _JSONBRepresentationProtocol>>
    ) -> QueryFragment {
        let col = columns[keyPath: column]
        let indexName = name ?? "idx_\(tableName)_\(col.name)_btree"

        var fragment: QueryFragment = "CREATE INDEX \(quote: indexName) ON "
        if let schemaName {
            fragment.append("\(quote: schemaName).")
        }
        fragment.append("\(quote: tableName) USING BTREE (\(quote: col.name))")

        return fragment
    }

    /// Drop an index by name
    ///
    /// ```swift
    /// try await db.execute(
    ///     UserProfile.dropIndex(name: "idx_user_profiles_settings_gin")
    /// )
    /// // DROP INDEX "idx_user_profiles_settings_gin"
    /// ```
    ///
    /// - Parameters:
    ///   - name: The name of the index to drop
    ///   - ifExists: If true, don't error if index doesn't exist (default: true)
    /// - Returns: SQL fragment for dropping the index
    public static func dropIndex(name: String, ifExists: Bool = true) -> QueryFragment {
        var fragment: QueryFragment = "DROP INDEX "
        if ifExists {
            fragment.append("IF EXISTS ")
        }
        if let schemaName {
            fragment.append("\(quote: schemaName).")
        }
        fragment.append("\(quote: name)")
        return fragment
    }
}

// MARK: - Raw Data Column Support

extension Table {
    /// Create GIN index on raw Data column (stored as JSONB in database)
    ///
    /// Use this overload when your JSONB column is stored as raw `Data` instead of
    /// a typed `_JSONBRepresentation`.
    ///
    /// ```swift
    /// @Table("posts")
    /// struct Post {
    ///     @Column(as: Data.self)
    ///     var metadata: Data  // Stored as JSONB in database
    /// }
    ///
    /// try await db.execute(
    ///     Post.createGINIndex(on: \.metadata, operatorClass: .jsonb_path_ops)
    /// )
    /// ```
    public static func createGINIndex(
        name: String? = nil,
        on column: KeyPath<TableColumns, TableColumn<Self, Data>>,
        operatorClass: JSONB.Index.GIN = .jsonb_ops
    ) -> QueryFragment {
        let col = columns[keyPath: column]
        let indexName = name ?? "idx_\(tableName)_\(col.name)_gin"
        let opClass = operatorClass == .jsonb_ops ? "" : " \(operatorClass.rawValue)"

        var fragment: QueryFragment = "CREATE INDEX \(quote: indexName) ON "
        if let schemaName {
            fragment.append("\(quote: schemaName).")
        }
        fragment.append("\(quote: tableName) USING GIN (\(quote: col.name)\(raw: opClass))")

        return fragment
    }

    /// Create GIN index on path for raw Data column
    ///
    /// Use this overload when your JSONB column is stored as raw `Data`.
    ///
    /// ```swift
    /// try await db.execute(
    ///     Post.createGINIndexPath(
    ///         on: \.metadata,
    ///         path: ["author", "id"]
    ///     )
    /// )
    /// ```
    public static func createGINIndexPath(
        name: String? = nil,
        on column: KeyPath<TableColumns, TableColumn<Self, Data>>,
        path: [String],
        operatorClass: JSONB.Index.GIN = .jsonb_ops
    ) -> QueryFragment {
        let col = columns[keyPath: column]
        let indexName = name ?? "idx_\(tableName)_\(col.name)_\(path.joined(separator: "_"))_gin"
        let pathExpr = JSONB.Index.pathLiteral(path)
        let opClass = operatorClass == .jsonb_ops ? "" : " \(operatorClass.rawValue)"

        var fragment: QueryFragment = "CREATE INDEX \(quote: indexName) ON "
        if let schemaName {
            fragment.append("\(quote: schemaName).")
        }
        fragment.append(
            "\(quote: tableName) USING GIN ((\(quote: col.name) #> \(raw: pathExpr))\(raw: opClass))"
        )

        return fragment
    }

    /// Create B-tree index on raw Data column
    ///
    /// Use this overload when your JSONB column is stored as raw `Data`.
    public static func createBTreeIndex(
        name: String? = nil,
        on column: KeyPath<TableColumns, TableColumn<Self, Data>>
    ) -> QueryFragment {
        let col = columns[keyPath: column]
        let indexName = name ?? "idx_\(tableName)_\(col.name)_btree"

        var fragment: QueryFragment = "CREATE INDEX \(quote: indexName) ON "
        if let schemaName {
            fragment.append("\(quote: schemaName).")
        }
        fragment.append("\(quote: tableName) USING BTREE (\(quote: col.name))")

        return fragment
    }
}
