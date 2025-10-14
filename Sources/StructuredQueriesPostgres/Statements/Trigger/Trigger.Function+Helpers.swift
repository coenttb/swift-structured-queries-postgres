import Foundation
import StructuredQueriesCore
import StructuredQueriesPostgresSupport

// MARK: - Convenience Helpers

/// Convenience function helpers for common trigger patterns.
///
/// These helpers provide semantic, type-safe ways to create common trigger functions
/// like updating timestamps, incrementing versions, auditing changes, and more.
///
/// ## Example
///
/// ```swift
/// // Timestamp helper
/// User.createTrigger(
///     before: .update,
///     function: .updateTimestamp(column: \.updatedAt)
/// )
///
/// // Audit helper
/// let auditFunc = Trigger.Function<User>.audit(to: UserAudit.self)
/// User.createTrigger(after: .insert, function: auditFunc)
/// User.createTrigger(after: .update, function: auditFunc)
/// User.createTrigger(after: .delete, function: auditFunc)
/// ```
extension Trigger.Function where On: Table {

    // MARK: - Timestamp Helpers

    /// Automatically updates a timestamp column to track when rows are modified.
    ///
    /// Creates a trigger function that sets a timestamp column to the current time whenever a row
    /// is inserted or updated. This is the most common trigger pattern for tracking modification times.
    ///
    /// ## When to Use
    ///
    /// - Track when records were last modified (`updatedAt` pattern)
    /// - Audit trail timestamp management
    /// - Cache invalidation tracking
    /// - Any scenario where you need automatic modification timestamps
    ///
    /// ## Usage Pattern
    ///
    /// Pair with BEFORE UPDATE triggers for automatic timestamp management:
    ///
    /// ```swift
    /// let trigger = User.createTrigger(
    ///     timing: .before,
    ///     event: .update,
    ///     function: .updateTimestamp(column: \.updatedAt)
    /// )
    /// try await trigger.execute(db)
    ///
    /// // Now every UPDATE automatically sets updatedAt:
    /// try await User.where { $0.id == userId }
    ///     .update { $0.name = "New Name" }
    /// // updatedAt is automatically set to CURRENT_TIMESTAMP
    /// ```
    ///
    /// ## Generated SQL
    ///
    /// ```sql
    /// -- Function:
    /// CREATE OR REPLACE FUNCTION "update_updatedAt_users"()
    /// RETURNS TRIGGER AS $$
    /// BEGIN
    ///   NEW."updatedAt" = CURRENT_TIMESTAMP;
    ///   RETURN NEW;
    /// END
    /// $$ LANGUAGE plpgsql
    ///
    /// -- Trigger:
    /// CREATE TRIGGER "users_before_update_update_updatedAt"
    /// BEFORE UPDATE
    /// ON "users"
    /// FOR EACH ROW
    /// EXECUTE FUNCTION "update_updatedAt_users"()
    /// ```
    ///
    /// ## Complete Example
    ///
    /// ```swift
    /// @Table("users")
    /// struct User {
    ///     let id: Int
    ///     var name: String
    ///     var email: String
    ///     var createdAt: Date?
    ///     var updatedAt: Date?  // ← Automatically managed
    /// }
    ///
    /// // Setup (run once during migration):
    /// let updateTrigger = User.createTrigger(
    ///     timing: .before,
    ///     event: .update,
    ///     function: .updateTimestamp(column: \.updatedAt)
    /// )
    /// try await updateTrigger.execute(db)
    ///
    /// // Application code - timestamps are automatic:
    /// let user = User(id: 1, name: "Alice", email: "alice@example.com",
    ///                 createdAt: .now, updatedAt: .now)
    /// try await user.insert().execute(db)
    ///
    /// // Later - updatedAt is set automatically by trigger:
    /// try await User.where { $0.id == 1 }
    ///     .update { $0.email = "newemail@example.com" }
    ///
    /// let updated = try await User.where { $0.id == 1 }.fetchOne(db)
    /// print(updated.updatedAt)  // Current timestamp from trigger
    /// ```
    ///
    /// ## Best Practices
    ///
    /// **Combine with createdAt for complete timestamp tracking:**
    /// ```swift
    /// // Set creation timestamp
    /// User.createTrigger(timing: .before, event: .insert,
    ///                    function: .createdAt(column: \.createdAt))
    ///
    /// // Set update timestamp
    /// User.createTrigger(timing: .before, event: .update,
    ///                    function: .updateTimestamp(column: \.updatedAt))
    /// ```
    ///
    /// **Use BEFORE triggers, not AFTER:**
    /// - BEFORE triggers can modify the row being saved
    /// - AFTER triggers cannot modify data
    ///
    /// **Consider statement-level triggers for bulk updates:**
    /// ```swift
    /// // If you need to track bulk operations differently:
    /// User.createTrigger(timing: .after, event: .update, level: .statement,
    ///                    function: customBulkUpdateLogger)
    /// ```
    ///
    /// ## Custom Timestamp Expressions
    ///
    /// By default uses `CURRENT_TIMESTAMP`, but you can provide custom expressions:
    ///
    /// ```swift
    /// // Use a specific timezone:
    /// .updateTimestamp(column: \.updatedAt,
    ///                  to: SQLQueryExpression("CURRENT_TIMESTAMP AT TIME ZONE 'UTC'"))
    ///
    /// // Add an offset:
    /// .updateTimestamp(column: \.updatedAt,
    ///                  to: SQLQueryExpression("CURRENT_TIMESTAMP + INTERVAL '1 hour'"))
    /// ```
    ///
    /// ## See Also
    ///
    /// - ``createdAt(column:to:)`` - Set timestamp on INSERT
    /// - ``updateTimestamps(columns:to:)`` - Update multiple timestamp columns
    /// - ``Table/createTrigger(name:timing:event:ifNotExists:level:function:)`` - Create triggers
    ///
    /// - Parameters:
    ///   - column: The timestamp column to update (typically `updatedAt` or `modifiedAt`)
    ///   - expression: The SQL expression for the new value. Defaults to `CURRENT_TIMESTAMP`.
    /// - Returns: A trigger function that automatically updates the timestamp on modification
    public static func updateTimestamp<D: _OptionalPromotable<Date?>>(
        column: KeyPath<On.TableColumns, TableColumn<On, D>>,
        to expression: any QueryExpression<D> = SQLQueryExpression("CURRENT_TIMESTAMP")
    ) -> Self {
        let columnName = On.columns[keyPath: column]._names[0]
        let functionName = "update_\(columnName)_\(On.tableName)"

        var body: QueryFragment = "NEW.\(quote: columnName) = "
        body.append(expression.queryFragment)
        body.append(";\nRETURN NEW;")

        return .plpgsql(functionName, body)
    }

    /// Automatically sets a creation timestamp when rows are inserted.
    ///
    /// Creates a trigger function that sets a timestamp column to the current time when a row
    /// is first created. Pair with ``updateTimestamp(column:to:)`` for complete timestamp tracking.
    ///
    /// ## When to Use
    ///
    /// - Track when records were created (`createdAt` pattern)
    /// - Audit trail for record creation
    /// - Immutable creation timestamps (set once, never changed)
    ///
    /// ## Complete Timestamp Management
    ///
    /// ```swift
    /// // Set createdAt on INSERT
    /// let createTrigger = User.createTrigger(
    ///     timing: .before,
    ///     event: .insert,
    ///     function: .createdAt(column: \.createdAt)
    /// )
    ///
    /// // Set updatedAt on UPDATE
    /// let updateTrigger = User.createTrigger(
    ///     timing: .before,
    ///     event: .update,
    ///     function: .updateTimestamp(column: \.updatedAt)
    /// )
    ///
    /// try await createTrigger.execute(db)
    /// try await updateTrigger.execute(db)
    ///
    /// // Now timestamps are completely automatic:
    /// let user = User(id: 1, name: "Alice")
    /// try await user.insert().execute(db)  // createdAt set automatically
    ///
    /// try await User.where { $0.id == 1 }
    ///     .update { $0.name = "Bob" }  // updatedAt set automatically
    /// ```
    ///
    /// ## Generated SQL
    ///
    /// ```sql
    /// CREATE OR REPLACE FUNCTION "set_createdAt_users"()
    /// RETURNS TRIGGER AS $$
    /// BEGIN
    ///   NEW."createdAt" = CURRENT_TIMESTAMP;
    ///   RETURN NEW;
    /// END
    /// $$ LANGUAGE plpgsql
    /// ```
    ///
    /// ## See Also
    ///
    /// - ``updateTimestamp(column:to:)`` - Update timestamp on modifications
    /// - ``updateTimestamps(columns:to:)`` - Update multiple timestamps
    ///
    /// - Parameters:
    ///   - column: The timestamp column to set (typically `createdAt`)
    ///   - expression: The SQL expression for the timestamp. Defaults to `CURRENT_TIMESTAMP`.
    /// - Returns: A trigger function that sets the creation timestamp once
    public static func createdAt<D: _OptionalPromotable<Date?>>(
        column: KeyPath<On.TableColumns, TableColumn<On, D>>,
        to expression: any QueryExpression<D> = SQLQueryExpression("CURRENT_TIMESTAMP")
    ) -> Self {
        let columnName = On.columns[keyPath: column]._names[0]
        let functionName = "set_\(columnName)_\(On.tableName)"

        var body: QueryFragment = "NEW.\(quote: columnName) = "
        body.append(expression.queryFragment)
        body.append(";\nRETURN NEW;")

        return .plpgsql(functionName, body)
    }

    /// Updates multiple timestamp columns simultaneously.
    ///
    /// Efficiently sets multiple timestamp columns to the same value in a single trigger function.
    /// Use when you need to update several timestamps together, such as synchronizing modification
    /// and publication timestamps.
    ///
    /// ## When to Use
    ///
    /// - Update both modification and publication timestamps together
    /// - Synchronize multiple audit timestamps
    /// - Track multiple time-related events simultaneously
    /// - Reduce trigger overhead when updating multiple columns
    ///
    /// ## Complete Example
    ///
    /// ```swift
    /// @Table("posts")
    /// struct Post {
    ///     let id: Int
    ///     var title: String
    ///     var content: String
    ///     var updatedAt: Date?
    ///     var publishedAt: Date?
    ///     var syncedAt: Date?
    /// }
    ///
    /// // Setup (run once) - update all timestamps on modification:
    /// let trigger = Post.createTrigger(
    ///     timing: .before,
    ///     event: .update,
    ///     function: .updateTimestamps(columns: \.updatedAt, \.publishedAt, \.syncedAt)
    /// )
    /// try await trigger.execute(db)
    ///
    /// // Now all three timestamps update automatically:
    /// try await Post.where { $0.id == 1 }
    ///     .set(\.title, to: "New Title")
    ///     .execute(db)
    /// // updatedAt, publishedAt, and syncedAt all set to CURRENT_TIMESTAMP
    /// ```
    ///
    /// ## Generated SQL
    ///
    /// ```sql
    /// CREATE OR REPLACE FUNCTION "update_timestamps_posts"()
    /// RETURNS TRIGGER AS $$
    /// BEGIN
    ///   NEW."updatedAt" = CURRENT_TIMESTAMP;
    ///   NEW."publishedAt" = CURRENT_TIMESTAMP;
    ///   NEW."syncedAt" = CURRENT_TIMESTAMP;
    ///   RETURN NEW;
    /// END
    /// $$ LANGUAGE plpgsql
    /// ```
    ///
    /// ## Real-World Examples
    ///
    /// **Content Management System:**
    /// ```swift
    /// @Table("articles")
    /// struct Article {
    ///     let id: Int
    ///     var title: String
    ///     var body: String
    ///     var modifiedAt: Date?
    ///     var publishedAt: Date?
    ///     var indexedAt: Date?
    /// }
    ///
    /// // Update modification, publication, and search index timestamps:
    /// Article.createTrigger(
    ///     timing: .before,
    ///     event: .update,
    ///     function: .updateTimestamps(columns: \.modifiedAt, \.publishedAt, \.indexedAt)
    /// )
    /// ```
    ///
    /// **Multi-Region Synchronization:**
    /// ```swift
    /// @Table("products")
    /// struct Product {
    ///     let id: Int
    ///     var name: String
    ///     var price: Decimal
    ///     var updatedAt: Date?
    ///     var syncedToEU: Date?
    ///     var syncedToAsia: Date?
    ///     var syncedToUS: Date?
    /// }
    ///
    /// // MARK: all regions for re-sync when product changes:
    /// Product.createTrigger(
    ///     timing: .before,
    ///     event: .update,
    ///     function: .updateTimestamps(columns: \.updatedAt, \.syncedToEU, \.syncedToAsia, \.syncedToUS)
    /// )
    /// ```
    ///
    /// ## Best Practices
    ///
    /// **Use single updateTimestamp() when possible:**
    /// ```swift
    /// // ✅ For single timestamp, use updateTimestamp():
    /// User.createTrigger(
    ///     timing: .before,
    ///     event: .update,
    ///     function: .updateTimestamp(column: \.updatedAt)
    /// )
    ///
    /// // ✅ Use updateTimestamps() only for multiple columns:
    /// Post.createTrigger(
    ///     timing: .before,
    ///     event: .update,
    ///     function: .updateTimestamps(columns: \.updatedAt, \.publishedAt)
    /// )
    /// ```
    ///
    /// **Consider separate triggers for different timestamps:**
    /// ```swift
    /// // If timestamps serve different purposes, use separate triggers:
    /// Post.createTrigger(
    ///     timing: .before,
    ///     event: .update,
    ///     function: .updateTimestamp(column: \.updatedAt)
    /// )
    ///
    /// Post.createTrigger(
    ///     timing: .before,
    ///     event: .update(when: { new, old in new.status == "published" }),
    ///     function: .updateTimestamp(column: \.publishedAt)
    /// )
    /// ```
    ///
    /// **Custom expressions for specific use cases:**
    /// ```swift
    /// // Set all timestamps to UTC explicitly:
    /// Post.createTrigger(
    ///     timing: .before,
    ///     event: .update,
    ///     function: .updateTimestamps(
    ///         columns: \.updatedAt, \.syncedAt,
    ///         to: SQLQueryExpression("CURRENT_TIMESTAMP AT TIME ZONE 'UTC'")
    ///     )
    /// )
    /// ```
    ///
    /// ## See Also
    ///
    /// - ``updateTimestamp(column:to:)`` - Update single timestamp (use this for single columns)
    /// - ``createdAt(column:to:)`` - Set creation timestamp on INSERT
    ///
    /// - Parameters:
    ///   - columns: Variadic list of timestamp columns to update simultaneously
    ///   - expression: SQL expression for the timestamp value. Defaults to `CURRENT_TIMESTAMP`.
    /// - Returns: A trigger function that updates all specified timestamps to the same value
    public static func updateTimestamps<each D>(
        columns: repeat KeyPath<On.TableColumns, TableColumn<On, each D>>,
        to expression: any QueryExpression<Date?> = SQLQueryExpression("CURRENT_TIMESTAMP")
    ) -> Self {
        var columnNames: [String] = []
        for column in repeat each columns {
            columnNames.append(On.columns[keyPath: column]._names[0])
        }

        let functionName = "update_timestamps_\(On.tableName)"

        var body: QueryFragment = ""
        for (index, col) in columnNames.enumerated() {
            if index > 0 {
                body.append(";\n  ")
            }
            body.append("NEW.\(quote: col) = ")
            body.append(expression.queryFragment)
        }
        body.append(";\n  RETURN NEW;")

        return .plpgsql(functionName, body)
    }

    // MARK: - Version Increment

    /// Implements optimistic locking by auto-incrementing a version column on updates.
    ///
    /// Creates a trigger function that automatically increments a version number whenever a row
    /// is updated. This enables optimistic concurrency control - detecting when two processes
    /// try to modify the same record simultaneously.
    ///
    /// ## When to Use
    ///
    /// - Prevent lost updates in concurrent editing scenarios
    /// - Document versioning systems
    /// - Collaborative editing features
    /// - Any multi-user application where concurrent modifications are possible
    ///
    /// ## How Optimistic Locking Works
    ///
    /// 1. Read a record and its current version
    /// 2. Make changes in your application
    /// 3. Update only if the version matches (no concurrent changes)
    /// 4. Trigger automatically increments version on successful update
    ///
    /// ##Complete Optimistic Locking Implementation
    ///
    /// ```swift
    /// @Table("documents")
    /// struct Document {
    ///     let id: Int
    ///     var title: String
    ///     var content: String
    ///     var version: Int  // ← Automatically incremented
    /// }
    ///
    /// // Setup (run once):
    /// let trigger = Document.createTrigger(
    ///     timing: .before,
    ///     event: .update,
    ///     function: .incrementVersion(column: \.version)
    /// )
    /// try await trigger.execute(db)
    ///
    /// // Application code - detect concurrent modifications:
    /// func updateDocument(id: Int, newContent: String) async throws {
    ///     // 1. Read current version
    ///     guard let doc = try await Document.where { $0.id == id }.fetchOne(db) else {
    ///         throw DocumentNotFound()
    ///     }
    ///     let currentVersion = doc.version
    ///
    ///     // 2. Update only if version hasn't changed
    ///     let updated = try await Document
    ///         .where { $0.id == id && $0.version == currentVersion }
    ///         .set(\.content, to: newContent)
    ///         .returning(\.version)
    ///         .fetchOne(db)
    ///
    ///     // 3. Check if update succeeded
    ///     guard let newVersion = updated else {
    ///         throw ConcurrentModificationError("Document was modified by another user")
    ///     }
    ///
    ///     print("Updated to version \(newVersion)")  // Version auto-incremented
    /// }
    /// ```
    ///
    /// ## Generated SQL
    ///
    /// ```sql
    /// CREATE OR REPLACE FUNCTION "increment_version_documents"()
    /// RETURNS TRIGGER AS $$
    /// BEGIN
    ///   NEW."version" = OLD."version" + 1;
    ///   RETURN NEW;
    /// END
    /// $$ LANGUAGE plpgsql
    /// ```
    ///
    /// ## Best Practices
    ///
    /// **Always check affected row count:**
    /// ```swift
    /// let rowsAffected = try await Document
    ///     .where { $0.id == id && $0.version == expectedVersion }
    ///     .update { $0.content = newContent }
    ///
    /// if rowsAffected == 0 {
    ///     // Either document doesn't exist OR version mismatch
    ///     throw ConcurrentModificationError()
    /// }
    /// ```
    ///
    /// **Use RETURNING clause for new version:**
    /// ```swift
    /// let newVersion = try await Document
    ///     .where { $0.id == id && $0.version == expectedVersion }
    ///     .set(\.content, to: newContent)
    ///     .returning(\.version)
    ///     .fetchOne(db)
    /// ```
    ///
    /// **Initialize version to 0 or 1:**
    /// ```swift
    /// let doc = Document(id: 1, title: "New", content: "...", version: 0)
    /// ```
    ///
    /// ## See Also
    ///
    /// - ``updateTimestamp(column:to:)`` - Often combined with version tracking
    ///
    /// - Parameter column: The version column to increment (typically `version`)
    /// - Returns: A trigger function that auto-increments the version on every update
    public static func incrementVersion<I: FixedWidthInteger>(
        column: KeyPath<On.TableColumns, TableColumn<On, I>>
    ) -> Self {
        let columnName = On.columns[keyPath: column]._names[0]
        let functionName = "increment_\(columnName)_\(On.tableName)"

        let body: QueryFragment = """
            NEW.\(quote: columnName) = OLD.\(quote: columnName) + 1;
            RETURN NEW;
            """

        return .plpgsql(functionName, body)
    }

    // MARK: - Audit Logging

    /// Creates a complete audit trail by logging all changes to an audit table.
    ///
    /// Automatically captures INSERT, UPDATE, and DELETE operations with full before/after data
    /// stored as JSONB. One function works for all operations - create separate triggers for each event.
    ///
    /// ## When to Use
    ///
    /// - Compliance requirements (GDPR, HIPAA, SOX)
    /// - Security auditing and forensics
    /// - Change history for debugging
    /// - Undo/rollback functionality
    /// - "Who changed what when" tracking
    ///
    /// ## Complete Audit Trail Setup
    ///
    /// ```swift
    /// // 1. Define audit table conforming to AuditTable protocol:
    /// @Table("user_audit")
    /// struct UserAudit: AuditTable {
    ///     let id: Int
    ///     var tableName: String     // Source table
    ///     var operation: String     // INSERT/UPDATE/DELETE
    ///     var oldData: String?      // JSONB of old row (NULL for INSERT)
    ///     var newData: String?      // JSONB of new row (NULL for DELETE)
    ///     var changedAt: Date       // When the change occurred
    ///     var changedBy: String     // Who made the change (current_user)
    /// }
    ///
    /// // 2. Create one function for all events:
    /// let auditFunc = Trigger.Function<User>.audit(to: UserAudit.self)
    ///
    /// // 3. Create triggers for each event (reusing same function):
    /// try await User.createTrigger(timing: .after, event: .insert, function: auditFunc).execute(db)
    /// try await User.createTrigger(timing: .after, event: .update, function: auditFunc).execute(db)
    /// try await User.createTrigger(timing: .after, event: .delete, function: auditFunc).execute(db)
    ///
    /// // 4. Changes are now automatically logged:
    /// try await User(id: 1, name: "Alice").insert().execute(db)
    /// // → INSERT logged with newData = {"id": 1, "name": "Alice"}
    ///
    /// try await User.where { $0.id == 1 }.set(\.name, to: "Bob").execute(db)
    /// // → UPDATE logged with oldData = {"name": "Alice"}, newData = {"name": "Bob"}
    ///
    /// try await User.where { $0.id == 1 }.delete().execute(db)
    /// // → DELETE logged with oldData = {"id": 1, "name": "Bob"}
    /// ```
    ///
    /// ## Querying Audit Logs
    ///
    /// ```swift
    /// // Get all changes to a specific user:
    /// let changes = try await UserAudit
    ///     .where { $0.newData.contains(["id": userId]) || $0.oldData.contains(["id": userId]) }
    ///     .order(by: \.changedAt, .descending)
    ///     .fetchAll(db)
    ///
    /// // Find who deleted records:
    /// let deletions = try await UserAudit
    ///     .where { $0.operation == "DELETE" }
    ///     .fetchAll(db)
    /// ```
    ///
    /// ## Generated SQL
    ///
    /// ```sql
    /// CREATE OR REPLACE FUNCTION "audit_users_to_user_audit"()
    /// RETURNS TRIGGER AS $$
    /// BEGIN
    ///   INSERT INTO "user_audit" (
    ///     "tableName",
    ///     operation,
    ///     "oldData",
    ///     "newData",
    ///     "changedAt",
    ///     "changedBy"
    ///   ) VALUES (
    ///     TG_TABLE_NAME,    -- 'users'
    ///     TG_OP,            -- 'INSERT', 'UPDATE', or 'DELETE'
    ///     to_jsonb(OLD),    -- NULL for INSERT
    ///     to_jsonb(NEW),    -- NULL for DELETE
    ///     CURRENT_TIMESTAMP,
    ///     current_user
    ///   );
    ///   RETURN COALESCE(NEW, OLD);
    /// END
    /// $$ LANGUAGE plpgsql
    /// ```
    ///
    /// ## Best Practices
    ///
    /// **Use AFTER triggers, not BEFORE:**
    /// - Audit only committed changes
    /// - BEFORE triggers can be cancelled
    ///
    /// **Function reuse is efficient:**
    /// ```swift
    /// // ✅ One function, three triggers
    /// let auditFunc = Trigger.Function<User>.audit(to: UserAudit.self)
    /// User.createTrigger(timing: .after, event: .insert, function: auditFunc)
    /// User.createTrigger(timing: .after, event: .update, function: auditFunc)
    /// User.createTrigger(timing: .after, event: .delete, function: auditFunc)
    ///
    /// // ❌ Don't create separate functions
    /// User.createTrigger(timing: .after, event: .insert, function: .audit(to: UserAudit.self))
    /// User.createTrigger(timing: .after, event: .update, function: .audit(to: UserAudit.self))
    /// ```
    ///
    /// **PostgreSQL Audit Table Schema:**
    /// ```sql
    /// CREATE TABLE "user_audit" (
    ///     id SERIAL PRIMARY KEY,
    ///     "tableName" TEXT NOT NULL,
    ///     operation TEXT NOT NULL,
    ///     "oldData" JSONB,
    ///     "newData" JSONB,
    ///     "changedAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ///     "changedBy" TEXT NOT NULL DEFAULT current_user
    /// );
    /// CREATE INDEX ON "user_audit" ("tableName", "changedAt");
    /// CREATE INDEX ON "user_audit" USING gin("oldData");
    /// CREATE INDEX ON "user_audit" USING gin("newData");
    /// ```
    ///
    /// ## See Also
    ///
    /// - ``AuditTable`` - Protocol for audit table types
    /// - ``updateTimestamp(column:to:)`` - Often used alongside auditing
    ///
    /// - Parameter auditTable: The audit table type conforming to ``AuditTable``
    /// - Returns: A reusable trigger function that logs all changes with full before/after data
    public static func audit<A: AuditTable>(
        to auditTable: A.Type
    ) -> Self {
        let auditTableName = A.tableName.quoted()
        let functionName = "audit_\(On.tableName)_to_\(A.tableName)"

        let body: QueryFragment = """
            INSERT INTO \(raw: auditTableName) (
              "tableName",
              operation,
              "oldData",
              "newData",
              "changedAt",
              "changedBy"
            ) VALUES (
              TG_TABLE_NAME,
              TG_OP,
              to_jsonb(OLD),
              to_jsonb(NEW),
              CURRENT_TIMESTAMP,
              current_user
            );
            RETURN COALESCE(NEW, OLD);
            """

        return .plpgsql(functionName, body)
    }

    // MARK: - Validation

    /// Validates data using custom PL/pgSQL logic before it's stored in the database.
    ///
    /// Enables complex validation rules that go beyond simple CHECK constraints, including
    /// pattern matching, cross-column validation, external lookups, and business logic enforcement.
    ///
    /// ## When to Use
    ///
    /// - Complex validation requiring PL/pgSQL logic (regex, conditionals, lookups)
    /// - Business rules that span multiple columns
    /// - Validation requiring database queries or function calls
    /// - Custom error messages with dynamic content
    /// - Domain-specific constraints (email formats, phone numbers, etc.)
    ///
    /// ## Complete Email Validation Example
    ///
    /// ```swift
    /// @Table("users")
    /// struct User {
    ///     let id: Int
    ///     var email: String
    ///     var name: String
    /// }
    ///
    /// // Setup (run once):
    /// let trigger = User.createTrigger(
    ///     timing: .before,
    ///     event: .insert,
    ///     function: .validate("""
    ///         IF NEW.email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}$' THEN
    ///             RAISE EXCEPTION 'Invalid email format: %', NEW.email;
    ///         END IF;
    ///         """)
    /// )
    /// try await trigger.execute(db)
    ///
    /// // Now insertions are validated:
    /// try await User(id: 1, email: "valid@example.com", name: "Alice")
    ///     .insert().execute(db)  // ✅ Success
    ///
    /// try await User(id: 2, email: "invalid-email", name: "Bob")
    ///     .insert().execute(db)  // ❌ Throws: "Invalid email format: invalid-email"
    /// ```
    ///
    /// ## Generated SQL
    ///
    /// ```sql
    /// CREATE OR REPLACE FUNCTION "validate_users"()
    /// RETURNS TRIGGER AS $$
    /// BEGIN
    ///   IF NEW.email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$' THEN
    ///     RAISE EXCEPTION 'Invalid email format: %', NEW.email;
    ///   END IF;
    ///   RETURN NEW;
    /// END
    /// $$ LANGUAGE plpgsql
    /// ```
    ///
    /// ## Advanced Validation Examples
    ///
    /// **Cross-Column Validation:**
    /// ```swift
    /// Order.createTrigger(
    ///     timing: .before,
    ///     event: .insert,
    ///     function: .validate("""
    ///         IF NEW.quantity <= 0 THEN
    ///             RAISE EXCEPTION 'Quantity must be positive';
    ///         END IF;
    ///
    ///         IF NEW.price < 0 THEN
    ///             RAISE EXCEPTION 'Price cannot be negative';
    ///         END IF;
    ///
    ///         IF NEW.total != NEW.quantity * NEW.price THEN
    ///             RAISE EXCEPTION 'Total must equal quantity × price';
    ///         END IF;
    ///         """)
    /// )
    /// ```
    ///
    /// **Conditional Validation Based on Column Values:**
    /// ```swift
    /// User.createTrigger(
    ///     timing: .before,
    ///     event: .update,
    ///     function: .validate("""
    ///         -- Admin users must have @company.com email
    ///         IF NEW.role = 'admin' AND NEW.email !~ '@company\\.com$' THEN
    ///             RAISE EXCEPTION 'Admin users must have company email address';
    ///         END IF;
    ///
    ///         -- Prevent downgrading admin to regular user
    ///         IF OLD.role = 'admin' AND NEW.role != 'admin' THEN
    ///             RAISE EXCEPTION 'Cannot remove admin role';
    ///         END IF;
    ///         """)
    /// )
    /// ```
    ///
    /// **Validation with Database Lookups:**
    /// ```swift
    /// Order.createTrigger(
    ///     timing: .before,
    ///     event: .insert,
    ///     function: .validate("""
    ///         DECLARE
    ///             product_stock INT;
    ///         BEGIN
    ///             SELECT stock INTO product_stock
    ///             FROM products
    ///             WHERE id = NEW.product_id;
    ///
    ///             IF product_stock < NEW.quantity THEN
    ///                 RAISE EXCEPTION 'Insufficient stock. Available: %, Requested: %',
    ///                     product_stock, NEW.quantity;
    ///             END IF;
    ///
    ///             RETURN NEW;
    ///         END;
    ///         """)
    /// )
    /// ```
    ///
    /// **Multiple Validation Rules:**
    /// ```swift
    /// Product.createTrigger(
    ///     timing: .before,
    ///     event: [.insert, .update],
    ///     function: .validate("""
    ///         -- SKU format validation
    ///         IF NEW.sku !~ '^[A-Z]{3}-[0-9]{6}$' THEN
    ///             RAISE EXCEPTION 'SKU must match format ABC-123456';
    ///         END IF;
    ///
    ///         -- Price range validation
    ///         IF NEW.price < 0.01 OR NEW.price > 999999.99 THEN
    ///             RAISE EXCEPTION 'Price must be between $0.01 and $999,999.99';
    ///         END IF;
    ///
    ///         -- Weight validation
    ///         IF NEW.weight <= 0 THEN
    ///             RAISE EXCEPTION 'Weight must be positive';
    ///         END IF;
    ///
    ///         -- Name length validation
    ///         IF LENGTH(NEW.name) < 3 OR LENGTH(NEW.name) > 200 THEN
    ///             RAISE EXCEPTION 'Product name must be 3-200 characters';
    ///         END IF;
    ///         """)
    /// )
    /// ```
    ///
    /// ## Best Practices
    ///
    /// **Use BEFORE triggers for validation:**
    /// - BEFORE triggers can prevent invalid data from being stored
    /// - AFTER triggers run after data is already written
    ///
    /// **Provide clear error messages:**
    /// ```swift
    /// // ✅ Helpful error message
    /// IF NEW.age < 18 THEN
    ///     RAISE EXCEPTION 'User must be at least 18 years old. Provided age: %', NEW.age;
    /// END IF;
    ///
    /// // ❌ Generic error message
    /// IF NEW.age < 18 THEN
    ///     RAISE EXCEPTION 'Invalid age';
    /// END IF;
    /// ```
    ///
    /// **Consider CHECK constraints for simple validation:**
    /// ```swift
    /// // For simple rules, use CHECK constraints instead:
    /// // ALTER TABLE users ADD CONSTRAINT age_positive CHECK (age > 0);
    ///
    /// // Use validate() for complex rules:
    /// User.createTrigger(before: .insert, function: .validate(...))
    /// ```
    ///
    /// **Escape single quotes in PL/pgSQL strings:**
    /// ```swift
    /// // Use double backslash for regex patterns:
    /// IF NEW.phone !~ '^\\d{3}-\\d{3}-\\d{4}$' THEN
    ///     RAISE EXCEPTION 'Invalid phone format';
    /// END IF;
    /// ```
    ///
    /// **Combine multiple events:**
    /// ```swift
    /// // Validate both INSERT and UPDATE:
    /// User.createTrigger(
    ///     timing: .before,
    ///     event: [.insert, .update],
    ///     function: .validate("...")
    /// )
    /// ```
    ///
    /// ## See Also
    ///
    /// - ``preventDeletion(message:)`` - Block all deletions with custom message
    /// - ``preventDeletionWhen(column:equals:message:)`` - Conditional deletion prevention
    ///
    /// - Parameter validationLogic: PL/pgSQL code that validates NEW record and raises exceptions for invalid data
    /// - Returns: A trigger function that validates data before storage
    public static func validate(_ validationLogic: String) -> Self {
        let functionName = "validate_\(On.tableName)"

        var body: QueryFragment = "\(raw: validationLogic)\n"
        body.append("RETURN NEW;")

        return .plpgsql(functionName, body)
    }

    // MARK: - Deletion Actions

    /// Prevents all deletions from a table by raising an exception for every DELETE attempt.
    ///
    /// Creates a trigger function that blocks all DELETE operations on the table, ensuring
    /// critical records can never be removed. Use this for permanent data that must never be
    /// deleted, such as system configuration, audit trails, or core reference data.
    ///
    /// ## When to Use
    ///
    /// - Protect critical system data (configuration, reference tables)
    /// - Preserve audit trails permanently
    /// - Prevent accidental deletion of important records
    /// - Enforce data retention policies
    /// - Protect master data in multi-tenant systems
    ///
    /// ## Complete Example
    ///
    /// ```swift
    /// @Table("system_config")
    /// struct SystemConfig {
    ///     let id: Int
    ///     var key: String
    ///     var value: String
    /// }
    ///
    /// // Setup (run once):
    /// let trigger = SystemConfig.createTrigger(
    ///     timing: .before,
    ///     event: .delete,
    ///     function: .preventDeletion(message: "Cannot delete system configuration")
    /// )
    /// try await trigger.execute(db)
    ///
    /// // Now all deletions are blocked:
    /// try await SystemConfig.where { $0.id == 1 }.delete().execute(db)
    /// // ❌ Throws: "Cannot delete system configuration"
    ///
    /// try await SystemConfig.delete().execute(db)  // Bulk delete
    /// // ❌ Throws: "Cannot delete system configuration"
    /// ```
    ///
    /// ## Generated SQL
    ///
    /// ```sql
    /// CREATE OR REPLACE FUNCTION "prevent_deletion_system_config"()
    /// RETURNS TRIGGER AS $$
    /// BEGIN
    ///   RAISE EXCEPTION 'Cannot delete system configuration';
    /// END
    /// $$ LANGUAGE plpgsql
    ///
    /// CREATE TRIGGER "system_config_before_delete_prevent_deletion"
    /// BEFORE DELETE
    /// ON "system_config"
    /// FOR EACH ROW
    /// EXECUTE FUNCTION "prevent_deletion_system_config"()
    /// ```
    ///
    /// ## Real-World Examples
    ///
    /// **Protect System Users:**
    /// ```swift
    /// @Table("users")
    /// struct User {
    ///     let id: Int
    ///     var username: String
    ///     var role: String
    /// }
    ///
    /// // Prevent deletion of ALL users
    /// User.createTrigger(
    ///     timing: .before,
    ///     event: .delete,
    ///     function: .preventDeletion(message: "User deletion not allowed. Use deactivation instead.")
    /// )
    /// ```
    ///
    /// **Protect Audit Tables:**
    /// ```swift
    /// @Table("audit_log")
    /// struct AuditLog: AuditTable {
    ///     let id: Int
    ///     var tableName: String
    ///     var operation: String
    ///     var oldData: String?
    ///     var newData: String?
    ///     var changedAt: Date
    /// }
    ///
    /// // Audit logs must NEVER be deleted (compliance requirement)
    /// AuditLog.createTrigger(
    ///     timing: .before,
    ///     event: .delete,
    ///     function: .preventDeletion(message: "Audit logs cannot be deleted per compliance policy")
    /// )
    /// ```
    ///
    /// **Protect Reference Data:**
    /// ```swift
    /// @Table("countries")
    /// struct Country {
    ///     let id: Int
    ///     var code: String
    ///     var name: String
    /// }
    ///
    /// // Reference data should never be deleted, only updated
    /// Country.createTrigger(
    ///     timing: .before,
    ///     event: .delete,
    ///     function: .preventDeletion(message: "Country reference data cannot be deleted")
    /// )
    /// ```
    ///
    /// ## Best Practices
    ///
    /// **Use clear, actionable error messages:**
    /// ```swift
    /// // ✅ Explains why and suggests alternative
    /// .preventDeletion(message: "Users cannot be deleted. Use soft delete by setting deletedAt instead.")
    ///
    /// // ❌ Unclear what to do instead
    /// .preventDeletion(message: "Cannot delete")
    /// ```
    ///
    /// **Consider conditional prevention instead:**
    /// ```swift
    /// // If you only need to protect SOME records, use preventDeletionWhen:
    /// User.createTrigger(
    ///     timing: .before,
    ///     event: .delete,
    ///     function: .preventDeletionWhen(
    ///         column: \.role,
    ///         equals: "admin",
    ///         message: "Cannot delete admin users"
    ///     )
    /// )
    /// ```
    ///
    /// **Combine with soft deletion for user-facing data:**
    /// ```swift
    /// // For user data, prefer soft deletion over complete prevention:
    /// User.createTrigger(
    ///     timing: .before,
    ///     event: .delete,
    ///     function: .softDelete(deletedAtColumn: \.deletedAt, identifiedBy: \.id)
    /// )
    /// ```
    ///
    /// **Document the business reason:**
    /// ```swift
    /// // Include why in the error message for future debugging:
    /// SystemConfig.createTrigger(
    ///     timing: .before,
    ///     event: .delete,
    ///     function: .preventDeletion(
    ///         message: "System configuration cannot be deleted (required for application startup)"
    ///     )
    /// )
    /// ```
    ///
    /// ## Disabling the Trigger Temporarily
    ///
    /// If you need to delete records despite the trigger (e.g., during migration):
    ///
    /// ```sql
    /// -- Disable trigger temporarily
    /// ALTER TABLE "system_config" DISABLE TRIGGER "system_config_before_delete_prevent_deletion";
    ///
    /// -- Perform necessary deletions
    /// DELETE FROM "system_config" WHERE ...;
    ///
    /// -- Re-enable trigger
    /// ALTER TABLE "system_config" ENABLE TRIGGER "system_config_before_delete_prevent_deletion";
    /// ```
    ///
    /// ## See Also
    ///
    /// - ``preventDeletionWhen(column:equals:message:)`` - Conditional deletion prevention
    /// - ``softDelete(deletedAtColumn:identifiedBy:to:)`` - Mark records as deleted instead
    /// - ``validate(_:)`` - Custom validation logic
    ///
    /// - Parameter message: Clear error message explaining why deletion is prevented and what to do instead
    /// - Returns: A trigger function that prevents all deletions with the specified error message
    public static func preventDeletion(message: String) -> Self {
        let functionName = "prevent_deletion_\(On.tableName)"
        let escapedMsg = message.escapedForPostgreSQL()

        let body: QueryFragment = "RAISE EXCEPTION '\(raw: escapedMsg)';"

        return .plpgsql(functionName, body)
    }

    /// Conditionally prevents deletion when a specific column matches a value.
    ///
    /// Protects specific records based on column values while allowing deletion of other records.
    /// More targeted than ``preventDeletion(message:)`` which blocks all deletions.
    ///
    /// ## When to Use
    ///
    /// - Protect admin users but allow regular user deletion
    /// - Prevent deletion of "active" records but allow deletion of "archived" ones
    /// - Block deletion based on status, role, or type columns
    /// - Enforce business rules about which records can be deleted
    ///
    /// ## Complete Example
    ///
    /// ```swift
    /// @Table("users")
    /// struct User {
    ///     let id: Int
    ///     var name: String
    ///     var role: String
    ///     var status: String
    /// }
    ///
    /// // Setup (run once) - protect admin users only:
    /// let trigger = User.createTrigger(
    ///     timing: .before,
    ///     event: .delete,
    ///     function: .preventDeletionWhen(
    ///         column: \.role,
    ///         equals: "admin",
    ///         message: "Cannot delete admin users"
    ///     )
    /// )
    /// try await trigger.execute(db)
    ///
    /// // Regular users can be deleted:
    /// try await User.where { $0.id == 1 && $0.role == "user" }
    ///     .delete().execute(db)  // ✅ Success
    ///
    /// // Admin users cannot be deleted:
    /// try await User.where { $0.id == 2 && $0.role == "admin" }
    ///     .delete().execute(db)  // ❌ Throws: "Cannot delete admin users"
    /// ```
    ///
    /// ## Generated SQL
    ///
    /// ```sql
    /// CREATE OR REPLACE FUNCTION "prevent_deletion_when_users"()
    /// RETURNS TRIGGER AS $$
    /// BEGIN
    ///   IF OLD."role" = 'admin' THEN
    ///     RAISE EXCEPTION 'Cannot delete admin users';
    ///   END IF;
    ///   RETURN OLD;
    /// END
    /// $$ LANGUAGE plpgsql
    /// ```
    ///
    /// ## Real-World Examples
    ///
    /// **Protect Active Subscriptions:**
    /// ```swift
    /// @Table("subscriptions")
    /// struct Subscription {
    ///     let id: Int
    ///     var userId: Int
    ///     var status: String
    ///     var plan: String
    /// }
    ///
    /// // Prevent deletion of active subscriptions (must be cancelled first):
    /// Subscription.createTrigger(
    ///     timing: .before,
    ///     event: .delete,
    ///     function: .preventDeletionWhen(
    ///         column: \.status,
    ///         equals: "active",
    ///         message: "Cannot delete active subscription. Cancel it first."
    ///     )
    /// )
    ///
    /// // Usage:
    /// try await Subscription.where { $0.id == subId }
    ///     .set(\.status, to: "cancelled")
    ///     .execute(db)  // First cancel
    ///
    /// try await Subscription.where { $0.id == subId }
    ///     .delete().execute(db)  // Then delete (now allowed)
    /// ```
    ///
    /// **Protect System Records:**
    /// ```swift
    /// @Table("config_settings")
    /// struct ConfigSetting {
    ///     let id: Int
    ///     var key: String
    ///     var value: String
    ///     var isSystem: Bool
    /// }
    ///
    /// // System configs cannot be deleted, user configs can:
    /// ConfigSetting.createTrigger(
    ///     timing: .before,
    ///     event: .delete,
    ///     function: .preventDeletionWhen(
    ///         column: \.isSystem,
    ///         equals: true,
    ///         message: "System configuration cannot be deleted"
    ///     )
    /// )
    /// ```
    ///
    /// **Protect Default Records:**
    /// ```swift
    /// @Table("templates")
    /// struct EmailTemplate {
    ///     let id: Int
    ///     var name: String
    ///     var content: String
    ///     var isDefault: Bool
    /// }
    ///
    /// // Default templates cannot be deleted:
    /// EmailTemplate.createTrigger(
    ///     timing: .before,
    ///     event: .delete,
    ///     function: .preventDeletionWhen(
    ///         column: \.isDefault,
    ///         equals: true,
    ///         message: "Default email templates cannot be deleted"
    ///     )
    /// )
    /// ```
    ///
    /// **Protect Records with Specific Status:**
    /// ```swift
    /// @Table("orders")
    /// struct Order {
    ///     let id: Int
    ///     var customerId: Int
    ///     var status: String
    ///     var total: Decimal
    /// }
    ///
    /// // Cannot delete shipped orders (compliance requirement):
    /// Order.createTrigger(
    ///     timing: .before,
    ///     event: .delete,
    ///     function: .preventDeletionWhen(
    ///         column: \.status,
    ///         equals: "shipped",
    ///         message: "Cannot delete shipped orders. Orders must be archived instead."
    ///     )
    /// )
    /// ```
    ///
    /// ## Best Practices
    ///
    /// **Provide context in error messages:**
    /// ```swift
    /// // ✅ Explains what to do instead
    /// .preventDeletionWhen(
    ///     column: \.status,
    ///     equals: "active",
    ///     message: "Cannot delete active users. Deactivate them first."
    /// )
    ///
    /// // ❌ Doesn't explain next steps
    /// .preventDeletionWhen(
    ///     column: \.status,
    ///     equals: "active",
    ///     message: "Deletion not allowed"
    /// )
    /// ```
    ///
    /// **For multiple conditions, use validate():**
    /// ```swift
    /// // ❌ Multiple preventDeletionWhen triggers get complex
    /// User.createTrigger(before: .delete, function: .preventDeletionWhen(column: \.role, equals: "admin", ...))
    /// User.createTrigger(before: .delete, function: .preventDeletionWhen(column: \.role, equals: "owner", ...))
    ///
    /// // ✅ Use validate() for complex logic instead
    /// User.createTrigger(
    ///     timing: .before,
    ///     event: .delete,
    ///     function: .validate("""
    ///         IF OLD.role IN ('admin', 'owner') THEN
    ///             RAISE EXCEPTION 'Cannot delete privileged users';
    ///         END IF;
    ///
    ///         IF OLD.status = 'active' AND OLD.has_subscriptions THEN
    ///             RAISE EXCEPTION 'Cannot delete users with active subscriptions';
    ///         END IF;
    ///         """)
    /// )
    /// ```
    ///
    /// **Combine with soft deletion:**
    /// ```swift
    /// // Protect admins completely, soft-delete regular users:
    /// User.createTrigger(
    ///     timing: .before,
    ///     event: .delete(when: { old in old.role == "admin" }),
    ///     function: .preventDeletion(message: "Admin users cannot be deleted")
    /// )
    ///
    /// User.createTrigger(
    ///     timing: .before,
    ///     event: .delete(when: { old in old.role != "admin" }),
    ///     function: .softDelete(deletedAtColumn: \.deletedAt, identifiedBy: \.id)
    /// )
    /// ```
    ///
    /// ## See Also
    ///
    /// - ``preventDeletion(message:)`` - Block all deletions unconditionally
    /// - ``softDelete(deletedAtColumn:identifiedBy:to:)`` - Mark records as deleted
    /// - ``validate(_:)`` - Complex validation logic with multiple conditions
    ///
    /// - Parameters:
    ///   - column: The column to check (typically status, role, type, or flag column)
    ///   - value: The value that prevents deletion when matched
    ///   - message: Clear error message explaining why deletion is prevented and what to do
    /// - Returns: A trigger function that conditionally prevents deletion based on column value
    public static func preventDeletionWhen<C: QueryBindable>(
        column: KeyPath<On.TableColumns, TableColumn<On, C>>,
        equals value: C,
        message: String
    ) -> Self {
        let columnName = On.columns[keyPath: column]._names[0].quoted()
        let functionName = "prevent_deletion_when_\(On.tableName)"
        let escapedMsg = message.escapedForPostgreSQL()

        var body: QueryFragment = "IF OLD.\(raw: columnName) = "
        body.append(value.queryFragment)
        body.append(" THEN\n  RAISE EXCEPTION '\(raw: escapedMsg)';\nEND IF;\nRETURN OLD;")

        return .plpgsql(functionName, body)
    }

    /// Implements soft deletion by marking rows as deleted instead of removing them.
    ///
    /// Prevents permanent data loss by intercepting DELETE operations and converting them to
    /// UPDATE operations that set a `deletedAt` timestamp. The actual row remains in the database
    /// but can be filtered out from normal queries.
    ///
    /// ## When to Use
    ///
    /// - Preserve data for compliance/audit requirements
    /// - Enable "undo" or restoration functionality
    /// - Maintain referential integrity
    /// - Keep historical records for analysis
    /// - Prevent accidental permanent deletion
    ///
    /// ## Complete Soft Delete Implementation
    ///
    /// ```swift
    /// @Table("users")
    /// struct User {
    ///     let id: Int
    ///     var name: String
    ///     var email: String
    ///     var deletedAt: Date?  // ← NULL = active, non-NULL = soft-deleted
    /// }
    ///
    /// // Setup (run once):
    /// let trigger = User.createTrigger(
    ///     timing: .before,
    ///     event: .delete,
    ///     function: .softDelete(
    ///         deletedAtColumn: \.deletedAt,
    ///         identifiedBy: \.id
    ///     )
    /// )
    /// try await trigger.execute(db)
    ///
    /// // Application code - DELETE becomes UPDATE:
    /// try await User.where { $0.id == 1 }.delete().execute(db)
    /// // Row NOT deleted - deletedAt set to CURRENT_TIMESTAMP instead
    ///
    /// // Query only active (non-deleted) users:
    /// let activeUsers = try await User
    ///     .where { $0.deletedAt == nil }
    ///     .fetchAll(db)
    ///
    /// // Include soft-deleted users:
    /// let allUsers = try await User.fetchAll(db)
    ///
    /// // Restore a soft-deleted user:
    /// try await User.where { $0.id == 1 }
    ///     .set(\.deletedAt, to: nil)
    ///     .execute(db)
    ///
    /// // Permanently delete (bypasses trigger since it's UPDATE):
    /// try await User.where { $0.id == 1 && $0.deletedAt != nil }
    ///     .delete()  // This will actually delete if you disable trigger first
    /// ```
    ///
    /// ## Generated SQL
    ///
    /// ```sql
    /// CREATE OR REPLACE FUNCTION "soft_delete_users"()
    /// RETURNS TRIGGER AS $$
    /// BEGIN
    ///   UPDATE "users"
    ///   SET "deletedAt" = CURRENT_TIMESTAMP
    ///   WHERE "id" = OLD."id";
    ///   RETURN NULL;  -- Cancels the DELETE operation
    /// END
    /// $$ LANGUAGE plpgsql
    /// ```
    ///
    /// ## How It Works
    ///
    /// 1. **DELETE operation starts** - User executes DELETE statement
    /// 2. **BEFORE trigger intercepts** - Trigger fires before actual deletion
    /// 3. **UPDATE instead** - Sets `deletedAt` timestamp on the row
    /// 4. **RETURN NULL** - Cancels the original DELETE operation
    /// 5. **Row preserved** - Data remains in table with `deletedAt` set
    ///
    /// ## Best Practices
    ///
    /// **Always filter by deletedAt in queries:**
    /// ```swift
    /// // ✅ Explicit filter for active records
    /// User.where { $0.deletedAt == nil }
    ///
    /// // Consider creating a view for convenience:
    /// // CREATE VIEW active_users AS SELECT * FROM users WHERE "deletedAt" IS NULL
    /// ```
    ///
    /// **Add indexes for performance:**
    /// ```sql
    /// CREATE INDEX ON users ("deletedAt") WHERE "deletedAt" IS NULL;
    /// ```
    ///
    /// **Consider combining with WHEN clause:**
    /// ```swift
    /// // Only soft-delete active rows, allow hard delete of already-deleted rows:
    /// User.createTrigger(
    ///     timing: .before,
    ///     event: .delete(when: { old in old.deletedAt == nil }),
    ///     function: .softDelete(deletedAtColumn: \.deletedAt, identifiedBy: \.id)
    /// )
    /// ```
    ///
    /// **Cascade soft deletes to related tables:**
    /// ```swift
    /// // Soft-delete user's posts when user is soft-deleted:
    /// User.createTrigger(
    ///     timing: .before,
    ///     event: .delete,
    ///     function: .define("cascade_soft_delete") {
    ///         #sql("UPDATE posts SET deleted_at = CURRENT_TIMESTAMP WHERE user_id = OLD.id")
    ///         #sql("UPDATE users SET deleted_at = CURRENT_TIMESTAMP WHERE id = OLD.id")
    ///         #sql("RETURN NULL")
    ///     }
    /// )
    /// ```
    ///
    /// ## See Also
    ///
    /// - ``preventDeletion(message:)`` - Block all deletions
    /// - ``preventDeletionWhen(column:equals:message:)`` - Conditional deletion prevention
    ///
    /// - Parameters:
    ///   - deletedAtColumn: The timestamp column marking soft deletion (typically `deletedAt`)
    ///   - identifierColumn: Column uniquely identifying the row (usually primary key `id`)
    ///   - expression: SQL expression for deletion timestamp. Defaults to `CURRENT_TIMESTAMP`.
    /// - Returns: A trigger function that converts DELETE to UPDATE with timestamp
    public static func softDelete<D: _OptionalPromotable<Date?>, I: QueryBindable>(
        deletedAtColumn: KeyPath<On.TableColumns, TableColumn<On, D>>,
        identifiedBy identifierColumn: KeyPath<On.TableColumns, TableColumn<On, I>>,
        to expression: any QueryExpression<D> = SQLQueryExpression("CURRENT_TIMESTAMP")
    ) -> Self {
        let columnName = On.columns[keyPath: deletedAtColumn]._names[0]
        let tableName = On.tableName.quoted()
        let idColumnName = On.columns[keyPath: identifierColumn]._names[0].quoted()
        let functionName = "soft_delete_\(On.tableName)"

        var body: QueryFragment = "UPDATE \(raw: tableName)\nSET \(quote: columnName) = "
        body.append(expression.queryFragment)
        body.append("\nWHERE \(raw: idColumnName) = OLD.\(raw: idColumnName);\nRETURN NULL;")

        return .plpgsql(functionName, body)
    }

    // MARK: - Row-Level Security

    /// Enforces row-level security by verifying a column matches the current user context.
    ///
    /// Implements tenant isolation and data access controls at the database level, preventing
    /// users from modifying rows they don't own. Essential for multi-tenant applications and
    /// systems requiring strict data segregation.
    ///
    /// ## When to Use
    ///
    /// - Multi-tenant SaaS applications (tenant isolation)
    /// - User-owned data (documents, posts, settings)
    /// - Organization-scoped data access
    /// - Healthcare/financial applications with strict privacy requirements
    /// - Any scenario requiring "users can only modify their own data"
    ///
    /// ## Complete Multi-Tenant Example
    ///
    /// ```swift
    /// @Table("documents")
    /// struct Document {
    ///     let id: Int
    ///     var title: String
    ///     var content: String
    ///     var userId: Int  // ← Ownership column
    /// }
    ///
    /// // Setup (run once):
    /// let trigger = Document.createTrigger(
    ///     timing: .before,
    ///     event: [.insert, .update],
    ///     function: .enforceRowLevelSecurity(
    ///         column: \.userId,
    ///         matches: SQLQueryExpression("current_setting('app.current_user_id')::INTEGER")
    ///     )
    /// )
    /// try await trigger.execute(db)
    ///
    /// // Application code - set user context before queries:
    /// try await db.execute(
    ///     "SET LOCAL app.current_user_id = \(userId)"
    /// )
    ///
    /// // Now only the user's documents can be modified:
    /// try await Document(id: 1, title: "My Doc", content: "...", userId: 123)
    ///     .insert().execute(db)  // ✅ Success if current user is 123
    ///
    /// try await Document(id: 2, title: "Their Doc", content: "...", userId: 999)
    ///     .insert().execute(db)  // ❌ Throws: "Access denied: row does not belong to current user"
    ///
    /// try await Document.where { $0.id == someId }
    ///     .set(\.title, to: "Hacked")
    ///     .execute(db)  // ❌ Throws if document belongs to different user
    /// ```
    ///
    /// ## Generated SQL
    ///
    /// ```sql
    /// CREATE OR REPLACE FUNCTION "enforce_rls_documents"()
    /// RETURNS TRIGGER AS $$
    /// BEGIN
    ///   IF NEW."userId" != current_setting('app.current_user_id')::INTEGER THEN
    ///     RAISE EXCEPTION 'Access denied: row does not belong to current user';
    ///   END IF;
    ///   RETURN NEW;
    /// END
    /// $$ LANGUAGE plpgsql
    /// ```
    ///
    /// ## Real-World Examples
    ///
    /// **SaaS Multi-Tenancy (Organization-Level Isolation):**
    /// ```swift
    /// @Table("projects")
    /// struct Project {
    ///     let id: Int
    ///     var name: String
    ///     var organizationId: Int  // Tenant identifier
    /// }
    ///
    /// // Enforce organization-level isolation:
    /// Project.createTrigger(
    ///     timing: .before,
    ///     event: [.insert, .update],
    ///     function: .enforceRowLevelSecurity(
    ///         column: \.organizationId,
    ///         matches: SQLQueryExpression("current_setting('app.organization_id')::INTEGER"),
    ///         message: "Access denied: project belongs to different organization"
    ///     )
    /// )
    ///
    /// // In application code:
    /// try await db.execute("SET LOCAL app.organization_id = \(org.id)")
    /// ```
    ///
    /// **User-Owned Resources:**
    /// ```swift
    /// @Table("posts")
    /// struct Post {
    ///     let id: Int
    ///     var title: String
    ///     var authorId: Int
    /// }
    ///
    /// // Users can only create/edit their own posts:
    /// Post.createTrigger(
    ///     timing: .before,
    ///     event: [.insert, .update],
    ///     function: .enforceRowLevelSecurity(
    ///         column: \.authorId,
    ///         matches: SQLQueryExpression("current_setting('app.user_id')::INTEGER"),
    ///         message: "You can only modify your own posts"
    ///     )
    /// )
    /// ```
    ///
    /// **Healthcare Data Access (Patient Privacy):**
    /// ```swift
    /// @Table("medical_records")
    /// struct MedicalRecord {
    ///     let id: Int
    ///     var patientId: Int
    ///     var diagnosis: String
    ///     var accessibleBy: String  // JSON array of authorized user IDs
    /// }
    ///
    /// // Enforce patient data access controls:
    /// MedicalRecord.createTrigger(
    ///     timing: .before,
    ///     event: [.insert, .update],
    ///     function: .validate("""
    ///         DECLARE
    ///             current_user_id TEXT;
    ///         BEGIN
    ///             current_user_id := current_setting('app.user_id');
    ///
    ///             IF NOT (NEW.accessibleBy::jsonb ? current_user_id) THEN
    ///                 RAISE EXCEPTION 'Access denied: insufficient permissions for patient data';
    ///             END IF;
    ///
    ///             RETURN NEW;
    ///         END;
    ///         """)
    /// )
    /// ```
    ///
    /// ## Setting User Context
    ///
    /// **Using PostgreSQL Configuration Parameters:**
    /// ```swift
    /// // At start of request/transaction:
    /// try await db.execute("SET LOCAL app.current_user_id = \(userId)")
    ///
    /// // All queries in this transaction are now scoped to this user
    /// try await Document.insert(...).execute(db)  // RLS enforced
    /// ```
    ///
    /// **Using Middleware Pattern:**
    /// ```swift
    /// func withUserContext<T>(userId: Int, operation: () async throws -> T) async throws -> T {
    ///     try await db.transaction { db in
    ///         try await db.execute("SET LOCAL app.current_user_id = \(userId)")
    ///         return try await operation()
    ///     }
    /// }
    ///
    /// // Usage:
    /// try await withUserContext(userId: currentUser.id) {
    ///     try await Document.insert(...).execute(db)
    /// }
    /// ```
    ///
    /// ## Best Practices
    ///
    /// **Set context at transaction start:**
    /// ```swift
    /// // ✅ Set once per transaction
    /// try await db.transaction { db in
    ///     try await db.execute("SET LOCAL app.user_id = \(user.id)")
    ///     try await performOperations(db)
    /// }
    ///
    /// // ❌ Don't set globally (affects all connections)
    /// try await db.execute("SET app.user_id = \(user.id)")  // Persists across transactions!
    /// ```
    ///
    /// **Combine with application-level checks:**
    /// ```swift
    /// // Database enforces security (defense in depth):
    /// Document.createTrigger(before: [.insert, .update],
    ///                        function: .enforceRowLevelSecurity(column: \.userId, matches: ...))
    ///
    /// // Application also filters queries:
    /// let docs = try await Document
    ///     .where { $0.userId == currentUser.id }  // Application filter
    ///     .fetchAll(db)  // Database also enforces via trigger
    /// ```
    ///
    /// **Use PostgreSQL's native RLS for SELECT queries:**
    /// ```sql
    /// -- Triggers only enforce INSERT/UPDATE/DELETE
    /// -- For SELECT, use native RLS:
    /// ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
    ///
    /// CREATE POLICY user_isolation ON documents
    ///     FOR ALL
    ///     TO PUBLIC
    ///     USING ("userId" = current_setting('app.current_user_id')::INTEGER);
    /// ```
    ///
    /// **Provide helpful error messages:**
    /// ```swift
    /// // ✅ Clear error with context
    /// .enforceRowLevelSecurity(
    ///     column: \.organizationId,
    ///     matches: ...,
    ///     message: "Access denied: This project belongs to a different organization"
    /// )
    ///
    /// // ❌ Generic error
    /// .enforceRowLevelSecurity(column: \.organizationId, matches: ...) // Uses default message
    /// ```
    ///
    /// **Consider INSERT-only enforcement:**
    /// ```swift
    /// // Prevent changing ownership after creation:
    /// Document.createTrigger(
    ///     timing: .before,
    ///     event: .insert,  // Only on INSERT
    ///     function: .enforceRowLevelSecurity(column: \.userId, matches: ...)
    /// )
    ///
    /// // Prevent any modification of ownership:
    /// Document.createTrigger(
    ///     timing: .before,
    ///     event: .update,
    ///     function: .validate("""
    ///         IF NEW.userId != OLD.userId THEN
    ///             RAISE EXCEPTION 'Cannot change document owner';
    ///         END IF;
    ///         """)
    /// )
    /// ```
    ///
    /// ## Testing RLS Implementation
    ///
    /// ```swift
    /// @Test func testRowLevelSecurity() async throws {
    ///     // Setup: Create trigger
    ///     try await Document.createTrigger(
    ///         timing: .before,
    ///         event: [.insert, .update],
    ///         function: .enforceRowLevelSecurity(column: \.userId, matches: ...)
    ///     ).execute(db)
    ///
    ///     // Test 1: User can insert their own document
    ///     try await db.execute("SET LOCAL app.user_id = '123'")
    ///     try await Document(id: 1, title: "Mine", userId: 123).insert().execute(db)
    ///     // ✅ Should succeed
    ///
    ///     // Test 2: User cannot insert document for another user
    ///     #expect(throws: DatabaseError.self) {
    ///         try await Document(id: 2, title: "Theirs", userId: 999).insert().execute(db)
    ///     }
    ///     // ✅ Should throw
    ///
    ///     // Test 3: User cannot update another user's document
    ///     #expect(throws: DatabaseError.self) {
    ///         try await Document.where { $0.id == someOtherUsersDocId }
    ///             .set(\.userId, to: 123)  // Attempt to take ownership
    ///             .execute(db)
    ///     }
    ///     // ✅ Should throw
    /// }
    /// ```
    ///
    /// ## See Also
    ///
    /// - ``validate(_:)`` - For complex multi-condition security logic
    /// - ``preventDeletionWhen(column:equals:message:)`` - Conditional deletion prevention
    ///
    /// - Parameters:
    ///   - column: The ownership/tenant column (typically `userId`, `organizationId`, `tenantId`)
    ///   - userContext: SQL expression returning the current user/tenant identifier
    ///   - message: Error message shown when access is denied. Should explain what went wrong.
    /// - Returns: A trigger function that enforces row-level security by validating ownership
    public static func enforceRowLevelSecurity<C: QueryBindable>(
        column: KeyPath<On.TableColumns, TableColumn<On, C>>,
        matches userContext: any QueryExpression<C>,
        message: String = "Access denied: row does not belong to current user"
    ) -> Self {
        let columnName = On.columns[keyPath: column]._names[0].quoted()
        let functionName = "enforce_rls_\(On.tableName)"
        let escapedMsg = message.escapedForPostgreSQL()

        var body: QueryFragment = "IF NEW.\(raw: columnName) != "
        body.append(userContext.queryFragment)
        body.append(" THEN\n  RAISE EXCEPTION '\(raw: escapedMsg)';\nEND IF;\nRETURN NEW;")

        return .plpgsql(functionName, body)
    }
}

// AuditTable protocol is defined in AuditTable.swift

// AuditTable protocol is defined in AuditTable.swift
