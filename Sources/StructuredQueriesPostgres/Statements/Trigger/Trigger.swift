import Foundation
import StructuredQueriesCore
import StructuredQueriesPostgresSupport

// MARK: - PostgreSQL Triggers

/// # Type-Safe PostgreSQL Triggers
///
/// A comprehensive, type-safe API for creating and managing PostgreSQL triggers and trigger functions.
///
/// ## Overview
///
/// PostgreSQL triggers automatically execute functions in response to database events like INSERT, UPDATE,
/// or DELETE. This package provides a Swift-native API that brings compile-time safety and clarity to
/// trigger creation, eliminating common errors and making triggers as approachable as any other Swift code.
///
/// ### Quick Start
///
/// ```swift
/// // Automatically update a timestamp on every modification
/// let trigger = User.createTrigger(
///     timing: .before,
///     event: .update,
///     function: .updateTimestamp(column: \.updatedAt)
/// )
/// try await trigger.execute(db)
///
/// // SQL Generated:
/// // CREATE TRIGGER "users_before_update_update_updatedAt"
/// // BEFORE UPDATE ON "users"
/// // FOR EACH ROW
/// // EXECUTE FUNCTION "update_updatedAt_users"()
/// ```
///
/// ## Two-Tier Architecture
///
/// PostgreSQL uses a two-tier trigger system that separates **what to execute** from **when to execute it**:
///
/// ### Tier 1: Trigger Functions
///
/// Reusable PL/pgSQL functions that contain the logic to execute:
///
/// ```swift
/// let auditFunc = Trigger.Function<User>.audit(to: AuditLog.self)
/// // CREATE OR REPLACE FUNCTION "audit_users_to_audit_log"()...
/// ```
///
/// ### Tier 2: Triggers
///
/// Event definitions that invoke functions at specific times:
///
/// ```swift
/// User.createTrigger(timing: .after, event: .insert, function: auditFunc)
/// User.createTrigger(timing: .after, event: .update, function: auditFunc)
/// User.createTrigger(timing: .after, event: .delete, function: auditFunc)
/// ```
///
/// **Key Advantage**: One function can be reused across multiple triggers, reducing code duplication
/// and ensuring consistency.
///
/// ## Key Features
///
/// ### 1. Type-Safe WHEN Clauses
///
/// Each event type provides only the pseudo-records valid for that event, preventing invalid SQL at compile time:
///
/// ```swift
/// // ✅ INSERT provides only NEW
/// .insert(when: { new in new.price > 0 })
///
/// // ✅ UPDATE provides only NEW
/// .update(when: { new in new.status == "active" })
///
/// // ✅ DELETE provides only OLD
/// .delete(when: { old in old.isArchived == true })
///
/// // ❌ This won't compile:
/// .insert(when: { new, old in ... })  // Compile error!
/// ```
///
/// ### 2. Pre-Built Helper Functions
///
/// Common patterns codified as convenient, semantic APIs:
///
/// ```swift
/// // Timestamps
/// .updateTimestamp(column: \.updatedAt)
/// .createdAt(column: \.createdAt)
///
/// // Audit logging
/// .audit(to: AuditLog.self)
///
/// // Soft deletion
/// .softDelete(deletedAtColumn: \.deletedAt, identifiedBy: \.id)
///
/// // Version management
/// .incrementVersion(column: \.version)
///
/// // Data validation
/// .validate("IF NEW.email !~ '^[A-Z0-9._%+-]+@...' THEN ...")
/// ```
///
/// See ``Trigger/Function`` for the complete list of helpers.
///
/// ### 3. Auto-Generated Stable Names
///
/// Trigger names are automatically generated following a stable, predictable pattern:
///
/// ```
/// {table}_{timing}_{event}_{function_descriptor}
/// ```
///
/// Examples:
/// - `users_before_update_update_updatedAt`
/// - `posts_after_insert_audit_to_audit_log`
/// - `documents_before_delete_soft_delete`
///
/// **Benefits**:
/// - Stable (no hashes or line numbers) - safe for migrations
/// - Descriptive - self-documenting in PostgreSQL catalog
/// - Predictable - easy to find in database tools
///
/// ### 4. PostgreSQL-Native NEW/OLD
///
/// Correctly handles PostgreSQL's unquoted NEW and OLD keywords:
///
/// ```swift
/// // Generates: WHEN (NEW."price" > 100)
/// .update(when: { new in new.price > 100 })
///
/// // Generates: WHEN (OLD."status" = 'archived')
/// .delete(when: { old in old.status == "archived" })
/// ```
///
/// Unlike SQLite's quoted `"new"` and `"old"`, PostgreSQL requires unquoted `NEW` and `OLD`.
/// This is handled automatically through a technical implementation using `AliasName.shouldQuote = false`.
///
/// ## Common Patterns
///
/// ### Timestamps
///
/// Automatically track when records are created and modified:
///
/// ```swift
/// // Set creation timestamp
/// User.createTrigger(
///     timing: .before,
///     event: .insert,
///     function: .createdAt(column: \.createdAt)
/// )
///
/// // Update modification timestamp
/// User.createTrigger(
///     timing: .before,
///     event: .update,
///     function: .updateTimestamp(column: \.updatedAt)
/// )
/// ```
///
/// ### Audit Logging
///
/// Track all changes to a table in an audit log:
///
/// ```swift
/// let auditFunc = Trigger.Function<User>.audit(to: UserAudit.self)
///
/// User.createTrigger(timing: .after, event: .insert, function: auditFunc)
/// User.createTrigger(timing: .after, event: .update, function: auditFunc)
/// User.createTrigger(timing: .after, event: .delete, function: auditFunc)
/// ```
///
/// ### Soft Deletes
///
/// Mark records as deleted instead of removing them:
///
/// ```swift
/// User.createTrigger(
///     timing: .before,
///     event: .delete,
///     function: .softDelete(
///         deletedAtColumn: \.deletedAt,
///         identifiedBy: \.id
///     )
/// )
/// ```
///
/// ### Data Validation
///
/// Enforce business rules at the database level:
///
/// ```swift
/// User.createTrigger(
///     timing: .before,
///     event: .insert,
///     function: .validate("""
///         IF NEW.email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}$' THEN
///             RAISE EXCEPTION 'Invalid email format: %', NEW.email;
///         END IF;
///         """)
/// )
/// ```
///
/// ### Optimistic Locking
///
/// Detect concurrent modifications using version numbers:
///
/// ```swift
/// Document.createTrigger(
///     timing: .before,
///     event: .update,
///     function: .incrementVersion(column: \.version)
/// )
///
/// // In application code:
/// let doc = try await Document
///     .where { $0.id == id && $0.version == expectedVersion }
///     .update { $0.content = newContent }
/// // Version automatically increments, preventing lost updates
/// ```
///
/// ## When to Use Triggers
///
/// ### ✅ Use Triggers For:
///
/// - **Automatic timestamps** - Set createdAt/updatedAt automatically
/// - **Audit trails** - Log all changes for compliance or debugging
/// - **Data validation** - Enforce complex business rules at the database level
/// - **Derived values** - Automatically calculate fields based on other columns
/// - **Cross-table updates** - Maintain denormalized data or caches
/// - **Notifications** - Alert external systems via `pg_notify`
/// - **Row-level security** - Enforce access control at the database level
///
/// ### ❌ Avoid Triggers For:
///
/// - **Complex business logic** - Keep it in application code where it's testable and debuggable
/// - **External API calls** - Use application code or message queues instead
/// - **Long-running operations** - Triggers block the transaction
/// - **Conditional logic based on user context** - Use application code for clarity
///
/// ### ⚠️ Use With Caution:
///
/// - **Trigger chains** - Triggers firing other triggers can be hard to debug
/// - **Performance-critical paths** - Row-level triggers fire for every row
/// - **Frequently changing logic** - Triggers require migrations to modify
///
/// ## Best Practices
///
/// ### Naming
///
/// Let the auto-generated names do the work, or use descriptive custom names:
///
/// ```swift
/// // ✅ Auto-generated (recommended)
/// User.createTrigger(timing: .before, event: .update, function: .updateTimestamp(column: \.updatedAt))
/// // → "users_before_update_update_updatedAt"
///
/// // ✅ Custom name (when order matters)
/// User.createTrigger(name: "0_validate_user", timing: .before, event: .insert, function: validateFunc)
/// User.createTrigger(name: "1_set_defaults", timing: .before, event: .insert, function: defaultsFunc)
/// ```
///
/// ### Function Reuse
///
/// Create functions once, use them across multiple triggers:
///
/// ```swift
/// // ✅ Do this - One function, many triggers
/// let auditFunc = Trigger.Function<User>.audit(to: AuditLog.self)
/// User.createTrigger(timing: .after, event: .insert, function: auditFunc)
/// User.createTrigger(timing: .after, event: .update, function: auditFunc)
/// User.createTrigger(timing: .after, event: .delete, function: auditFunc)
///
/// // ❌ Not this - Duplicate functions
/// User.createTrigger(timing: .after, event: .insert, function: .audit(to: AuditLog.self))
/// User.createTrigger(timing: .after, event: .update, function: .audit(to: AuditLog.self))
/// ```
///
/// ### Trigger Ordering
///
/// PostgreSQL fires triggers in **alphabetical order by name**. Use this to control execution:
///
/// ```swift
/// // Fires first (validates)
/// User.createTrigger(name: "0_validate", timing: .before, event: .update, function: validateFunc)
///
/// // Fires second (sets timestamp)
/// User.createTrigger(name: "1_timestamp", timing: .before, event: .update, function: timestampFunc)
/// ```
///
/// ### Performance
///
/// - **Use BEFORE triggers** for data validation and modification
/// - **Use AFTER triggers** for logging and notifications
/// - **Prefer statement-level** triggers for bulk operations when possible
/// - **Add WHEN clauses** to reduce unnecessary trigger executions
/// - **Keep functions simple** - complex logic slows down every operation
///
/// ## See Also
///
/// - ``Trigger`` - The trigger type for managing trigger definitions
/// - ``Trigger/Function`` - Trigger function creation and helpers
/// - ``TriggerEvent`` - Type-safe event definitions with WHEN clauses
/// - ``AuditTable`` - Protocol for audit logging tables
/// - ``NEW`` and ``OLD`` - Pseudo-record types for accessing row data
///
/// ## Topics
///
/// ### Creating Triggers
///
/// - ``Table/createTrigger(name:timing:event:ifNotExists:level:function:)``
///
/// ### Trigger Functions
///
/// - ``Trigger/Function``
/// - ``Trigger/Function/updateTimestamp(column:to:)``
/// - ``Trigger/Function/createdAt(column:to:)``
/// - ``Trigger/Function/audit(to:)``
/// - ``Trigger/Function/softDelete(deletedAtColumn:identifiedBy:to:)``
/// - ``Trigger/Function/incrementVersion(column:)``
///
/// ### Events and Conditions
///
/// - ``TriggerEvent``
/// - ``TriggerEvent/insert(when:)``
/// - ``TriggerEvent/update(when:)``
/// - ``TriggerEvent/delete(when:)``
///
/// ### Pseudo-Records
///
/// - ``NEW``
/// - ``OLD``

// MARK: - Trigger Pseudo-Records

/// Pseudo-record for NEW in PostgreSQL triggers.
///
/// In PostgreSQL triggers, `NEW` represents the new database row for INSERT/UPDATE operations.
/// Unlike regular table aliases, NEW and OLD are PostgreSQL keywords and must NOT be quoted.
///
/// **Key difference from SQLite**: PostgreSQL uses unquoted `NEW` and `OLD`, while SQLite
/// uses quoted lowercase `"new"` and `"old"`.
///
/// **Implementation**: NEW conforms to `AliasName` with `shouldQuote = false`, ensuring the
/// QueryFragment interpolation system generates unquoted `NEW` instead of quoted `"NEW"`.
public enum NEW: AliasName {
    /// Returns the alias name "NEW" for use in the TableAlias machinery.
    ///
    /// NEW is a PostgreSQL keyword for trigger pseudo-records and must not be quoted.
    public static var aliasName: String { "NEW" }

    /// PostgreSQL trigger pseudo-records must not be quoted.
    public static var shouldQuote: Bool { false }
}

/// Pseudo-record for OLD in PostgreSQL triggers.
///
/// In PostgreSQL triggers, `OLD` represents the old database row for UPDATE/DELETE operations.
/// Unlike regular table aliases, NEW and OLD are PostgreSQL keywords and must NOT be quoted.
///
/// **Key difference from SQLite**: PostgreSQL uses unquoted `NEW` and `OLD`, while SQLite
/// uses quoted lowercase `"new"` and `"old"`.
///
/// **Implementation**: OLD conforms to `AliasName` with `shouldQuote = false`, ensuring the
/// QueryFragment interpolation system generates unquoted `OLD` instead of quoted `"OLD"`.
public enum OLD: AliasName {
    /// Returns the alias name "OLD" for use in the TableAlias machinery.
    ///
    /// OLD is a PostgreSQL keyword for trigger pseudo-records and must not be quoted.
    public static var aliasName: String { "OLD" }

    /// PostgreSQL trigger pseudo-records must not be quoted.
    public static var shouldQuote: Bool { false }
}

// MARK: - Trigger

/// A PostgreSQL trigger that executes a trigger function.
///
/// Triggers are the second tier of PostgreSQL's two-tier trigger system. A trigger references
/// a trigger function and defines when and how that function should be executed.
///
/// ## Example
///
/// ```swift
/// // Create a function
/// let updateTimestamp = Trigger.Function<User>.updateTimestamp(column: \.updatedAt)
///
/// // Create a trigger that uses the function
/// let trigger = User.createTrigger(
///   "update_users_timestamp",
///   timing: .before,
///   events: [.update],
///   function: updateTimestamp
/// )
/// ```
public struct Trigger<On: Table>: Sendable, Statement {
    public typealias From = Never
    public typealias Joins = ()
    public typealias QueryValue = ()

    /// The trigger name
    public let name: String

    /// When the trigger fires
    public let timing: Timing

    /// What events fire the trigger (internal representation - use TriggerEvent for creation)
    package let events: [Event]

    /// Row-level or statement-level
    public let level: Level

    /// The function to execute
    public let function: Trigger<On>.Function

    /// Whether to handle "trigger already exists" errors at application level.
    ///
    /// Note: PostgreSQL does NOT support `IF NOT EXISTS` for CREATE TRIGGER.
    /// This property is stored for application-level handling only (e.g., to catch
    /// and ignore "already exists" errors). It does not affect SQL generation.
    public let ifNotExists: Bool

    /// When a trigger fires relative to the triggering event
    public enum Timing: String, Sendable {
        case before = "BEFORE"
        case after = "AFTER"
        case insteadOf = "INSTEAD OF"
    }

    /// The execution level of a trigger
    public enum Level: String, Sendable {
        case row = "FOR EACH ROW"
        case statement = "FOR EACH STATEMENT"
    }

    /// A database event that can trigger a function (internal representation - use TriggerEvent for creation)
    package struct Event: Sendable {
        package let kind: Kind
        package let columns: [String]?
        package let whenClause: QueryFragment?

        package enum Kind: String, Sendable {
            case insert = "INSERT"
            case update = "UPDATE"
            case delete = "DELETE"
            case truncate = "TRUNCATE"
        }

        var queryFragment: QueryFragment {
            var query: QueryFragment = "\(raw: kind.rawValue)"
            if let columns, !columns.isEmpty {
                let columnList = columns.map { QueryFragment(quote: $0) }.joined(separator: ", ")
                query.append(" OF \(columnList)")
            }
            return query
        }
    }

    /// Type-safe trigger event with event-scoped WHEN clauses.
    ///
    /// Each event type provides only the pseudo-records valid for that event:
    /// - INSERT: Only `NEW` is available
    /// - UPDATE: Only `NEW` is available (PostgreSQL uses NEW for UPDATE WHEN clauses)
    /// - DELETE: Only `OLD` is available
    /// - TRUNCATE: No pseudo-records (WHEN not supported)
    ///
    /// This design makes it impossible to reference invalid pseudo-records at compile time.
    public struct TriggerEvent: Sendable {
        public typealias Old = TableAlias<On, OLD>.TableColumns
        public typealias New = TableAlias<On, NEW>.TableColumns

        package let event: Event

        /// An INSERT event that fires when a new row is inserted.
        ///
        /// - Parameter condition: Optional WHEN clause using the NEW pseudo-record.
        /// - Returns: An INSERT trigger event.
        public static func insert(
            when condition: ((_ new: New) -> any QueryExpression<Bool>)? = nil
        ) -> TriggerEvent {
            TriggerEvent(
                event: Event(
                    kind: .insert,
                    columns: nil,
                    whenClause: condition?(On.as(NEW.self).columns).queryFragment
                )
            )
        }

        public static var insert: TriggerEvent { .insert() }

        /// An UPDATE event that fires when any column is updated.
        ///
        /// - Parameter condition: Optional WHEN clause using the NEW pseudo-record.
        /// - Returns: An UPDATE trigger event.
        public static func update(
            when condition: ((_ new: New) -> any QueryExpression<Bool>)? = nil
        ) -> TriggerEvent {
            TriggerEvent(
                event: Event(
                    kind: .update,
                    columns: nil,
                    whenClause: condition?(On.as(NEW.self).columns).queryFragment
                )
            )
        }

        public static var update: TriggerEvent { .update() }

        /// An UPDATE event that fires only when specific columns are modified.
        ///
        /// - Parameters:
        ///   - columns: The columns to monitor for changes.
        ///   - condition: Optional WHEN clause using the NEW pseudo-record.
        /// - Returns: An UPDATE trigger event.
        public static func update<each Column: _TableColumnExpression>(
            of columns: (On.TableColumns) -> (repeat each Column),
            when condition: ((_ new: New) -> any QueryExpression<Bool>)? = nil
        ) -> TriggerEvent {
            var columnNames: [String] = []
            for column in repeat each columns(On.columns) {
                columnNames.append(contentsOf: column._names)
            }

            return TriggerEvent(
                event: Event(
                    kind: .update,
                    columns: columnNames,
                    whenClause: condition?(On.as(NEW.self).columns).queryFragment
                )
            )
        }

        public static var delete: TriggerEvent { .delete() }

        /// A DELETE event that fires when a row is deleted.
        ///
        /// - Parameter condition: Optional WHEN clause using the OLD pseudo-record.
        /// - Returns: A DELETE trigger event.
        public static func delete(
            when condition: ((_ old: Old) -> any QueryExpression<Bool>)? = nil
        ) -> TriggerEvent {
            TriggerEvent(
                event: Event(
                    kind: .delete,
                    columns: nil,
                    whenClause: condition?(On.as(OLD.self).columns).queryFragment
                )
            )
        }

        /// A TRUNCATE event that fires when a table is truncated.
        ///
        /// Note: TRUNCATE triggers do not support WHEN clauses.
        public static var truncate: TriggerEvent {
            TriggerEvent(
                event: Event(kind: .truncate, columns: nil, whenClause: nil)
            )
        }
    }

    init(
        name: String,
        timing: Timing,
        events: [Event],
        level: Level,
        function: Trigger<On>.Function,
        ifNotExists: Bool = false
    ) {
        self.name = name
        self.timing = timing
        self.events = events
        self.level = level
        self.function = function
        self.ifNotExists = ifNotExists
    }

    public var query: QueryFragment {
        // Note: PostgreSQL does NOT support IF NOT EXISTS for CREATE TRIGGER
        // The ifNotExists property is stored for application-level handling only
        var query: QueryFragment = "CREATE TRIGGER"
        query.append(" \(quote: name)")

        // BEFORE/AFTER/INSTEAD OF
        query.append("\(.newline)\(raw: timing.rawValue)")

        // Events (INSERT OR UPDATE OR DELETE)
        let eventFragments = events.map(\.queryFragment)
        query.append(" \(eventFragments.joined(separator: " OR "))")

        // ON table
        query.append("\(.newline)ON \(On.self)")

        // FOR EACH ROW/STATEMENT
        query.append("\(.newline)\(raw: level.rawValue)")

        // WHEN condition (optional)
        // Extract WHEN clause from events - all events must share the same WHEN clause
        // (or have no WHEN clause) per PostgreSQL's trigger syntax
        let whenClauses = events.compactMap(\.whenClause)
        if let firstWhen = whenClauses.first {
            // Use the first WHEN clause - validation should ensure they're all identical
            query.append("\(.newline)WHEN (\(firstWhen))")
        }

        // EXECUTE FUNCTION
        query.append("\(.newline)EXECUTE FUNCTION \(quote: function.name)()")

        return query
    }

    /// Returns DROP statements for both trigger and function
    ///
    /// - Parameters:
    ///   - ifExists: Adds an `IF EXISTS` condition to the `DROP` statements.
    ///   - cascade: Adds `CASCADE` to automatically drop dependent objects.
    /// - Returns: An array containing DROP TRIGGER and DROP FUNCTION statements.
    public func drop(ifExists: Bool = false, cascade: Bool = false) -> [any Statement<()>] {
        [
            dropTrigger(ifExists: ifExists, cascade: cascade),
            function.drop(ifExists: ifExists, cascade: cascade),
        ]
    }

    /// Returns a `DROP TRIGGER` statement (without dropping the function)
    ///
    /// Use this if the trigger function is shared by multiple triggers and you don't
    /// want to drop it.
    ///
    /// - Parameters:
    ///   - ifExists: Adds an `IF EXISTS` condition to the `DROP TRIGGER`.
    ///   - cascade: Adds `CASCADE` to automatically drop dependent objects.
    /// - Returns: A `DROP TRIGGER` statement for this trigger.
    public func dropTrigger(ifExists: Bool = false, cascade: Bool = false) -> some Statement<()> {
        var query: QueryFragment = "DROP TRIGGER"
        if ifExists {
            query.append(" IF EXISTS")
        }
        query.append(" \(quote: name) ON \(On.self)")
        if cascade {
            query.append(" CASCADE")
        }
        return SQLQueryExpression(query)
    }

}

// MARK: - Table Extensions

extension Table {
    /// Creates a type-safe PostgreSQL trigger that executes a function in response to database events.
    ///
    /// This is the primary API for creating triggers. It provides compile-time guarantees through type-safe
    /// event-scoped WHEN clauses and automatically generates stable, descriptive trigger names.
    ///
    /// ## Overview
    ///
    /// ```swift
    /// // Basic trigger with auto-generated name
    /// let trigger = User.createTrigger(
    ///     timing: .before,
    ///     event: .update,
    ///     function: .updateTimestamp(column: \.updatedAt)
    /// )
    /// try await trigger.execute(db)
    /// // Generates: CREATE TRIGGER "users_before_update_update_updatedAt" ...
    /// ```
    ///
    /// ## Parameters
    ///
    /// ### `name` - Trigger Name (Optional)
    ///
    /// The trigger identifier in PostgreSQL. If `nil`, a stable name is auto-generated following this pattern:
    ///
    /// ```
    /// {table}_{timing}_{event}_{function_descriptor}
    /// ```
    ///
    /// **Auto-Generated Examples**:
    /// - `users_before_update_update_updatedAt`
    /// - `posts_after_insert_audit_to_audit_log`
    /// - `documents_before_delete_soft_delete`
    ///
    /// **When to provide a custom name**:
    /// - To control trigger execution order (PostgreSQL fires triggers alphabetically by name)
    /// - For organizational preferences or naming standards
    ///
    /// ```swift
    /// // ✅ Auto-generated (recommended for most cases)
    /// User.createTrigger(timing: .before, event: .update, function: .updateTimestamp(column: \.updatedAt))
    ///
    /// // ✅ Custom name for execution ordering
    /// User.createTrigger(name: "0_validate_first", timing: .before, event: .insert, function: validateFunc)
    /// User.createTrigger(name: "1_set_defaults", timing: .before, event: .insert, function: defaultsFunc)
    /// ```
    ///
    /// ### `timing` - Trigger Timing (Required)
    ///
    /// When the trigger executes relative to the database operation:
    ///
    /// - **`.before`** - Fires before the operation. Use for:
    ///   - Data validation and modification
    ///   - Setting default values
    ///   - Canceling operations (by returning `NULL`)
    ///   - Updating timestamps
    ///
    /// - **`.after`** - Fires after the operation commits. Use for:
    ///   - Audit logging
    ///   - Notifications (via `pg_notify`)
    ///   - Cascading updates to other tables
    ///   - Operations that shouldn't affect the current row
    ///
    /// - **`.insteadOf`** - Replaces the operation entirely. Use for:
    ///   - Making views updatable
    ///   - Redirecting operations to different tables
    ///   - Custom handling of INSERT/UPDATE/DELETE on views
    ///
    /// ```swift
    /// // BEFORE: Modify data before it's saved
    /// User.createTrigger(timing: .before, event: .update, function: .updateTimestamp(column: \.updatedAt))
    ///
    /// // AFTER: Log changes after they're committed
    /// User.createTrigger(timing: .after, event: .insert, function: .audit(to: AuditLog.self))
    ///
    /// // INSTEAD OF: Handle view operations
    /// UserView.createTrigger(timing: .insteadOf, event: .delete, function: handleViewDelete)
    /// ```
    ///
    /// ### `event` - Trigger Events (Variadic, Required)
    ///
    /// One or more database events that fire the trigger. Each event can optionally include a type-safe
    /// WHEN clause that filters when the trigger executes.
    ///
    /// **Available Events**:
    ///
    /// - **`.insert`** / **`.insert(when:)`**
    ///   - Fires when rows are inserted
    ///   - WHEN clause has access to `NEW` pseudo-record
    ///   - Example: `.insert(when: { new in new.price > 0 })`
    ///
    /// - **`.update`** / **`.update(when:)`** / **`.update(of:when:)`**
    ///   - Fires when rows are updated
    ///   - Optionally specify columns with `of:` parameter
    ///   - WHEN clause has access to `NEW` pseudo-record
    ///   - Example: `.update(of: { $0.status }, when: { new in new.status == "active" })`
    ///
    /// - **`.delete`** / **`.delete(when:)`**
    ///   - Fires when rows are deleted
    ///   - WHEN clause has access to `OLD` pseudo-record
    ///   - Example: `.delete(when: { old in old.isArchived == true })`
    ///
    /// - **`.truncate`**
    ///   - Fires when the table is truncated
    ///   - WHEN clauses not supported (PostgreSQL limitation)
    ///   - Typically used with statement-level triggers
    ///
    /// **Type Safety**: WHEN clauses are event-scoped - INSERT and UPDATE provide `NEW`, DELETE provides `OLD`.
    /// This prevents invalid pseudo-record access at compile time.
    ///
    /// **Multiple Events**: Provide multiple events to fire the same function for different operations:
    ///
    /// ```swift
    /// // One trigger, multiple events
    /// let auditFunc = Trigger.Function<User>.audit(to: AuditLog.self)
    /// User.createTrigger(
    ///     timing: .after,
    ///     event: .insert, .update(), .delete(),
    ///     function: auditFunc
    /// )
    /// // Generates: AFTER INSERT OR UPDATE OR DELETE
    /// ```
    ///
    /// **WHEN Clause Examples**:
    ///
    /// ```swift
    /// // Only fire for high-priority items
    /// Task.createTrigger(
    ///     timing: .after,
    ///     event: .insert(when: { new in new.priority > 7 }),
    ///     function: notifyFunc
    /// )
    ///
    /// // Only fire when specific columns change
    /// Product.createTrigger(
    ///     timing: .before,
    ///     event: .update(of: { ($0.price, $0.stock) }, when: { new in new.price > 0 }),
    ///     function: validateFunc
    /// )
    ///
    /// // Only fire for archived deletions
    /// Document.createTrigger(
    ///     timing: .before,
    ///     event: .delete(when: { old in old.isArchived == false }),
    ///     function: preventDeleteFunc
    /// )
    /// ```
    ///
    /// ### `ifNotExists` - Application-Level Error Handling (Optional)
    ///
    /// **Important**: PostgreSQL does **NOT** support `IF NOT EXISTS` for `CREATE TRIGGER`. This parameter
    /// is stored in the `Trigger` struct for application-level error handling only and does not affect
    /// SQL generation.
    ///
    /// **Default**: `false`
    ///
    /// **Use Case**: Store this flag to catch and ignore "already exists" errors in your application code:
    ///
    /// ```swift
    /// let trigger = User.createTrigger(
    ///     timing: .before,
    ///     event: .update,
    ///     ifNotExists: true,
    ///     function: .updateTimestamp(column: \.updatedAt)
    /// )
    ///
    /// do {
    ///     try await trigger.execute(db)
    /// } catch {
    ///     if trigger.ifNotExists && error.isAlreadyExistsError {
    ///         // Ignore - trigger already exists
    ///     } else {
    ///         throw error
    ///     }
    /// }
    /// ```
    ///
    /// **Why not in SQL?**: PostgreSQL added `OR REPLACE` for functions but never added `IF NOT EXISTS`
    /// for triggers. Use `DROP TRIGGER IF EXISTS` followed by `CREATE TRIGGER` if you need idempotent
    /// trigger creation.
    ///
    /// ### `level` - Execution Level (Optional)
    ///
    /// Whether the trigger fires for each row or once per statement.
    ///
    /// **Default**: `.row`
    ///
    /// - **`.row`** (default) - Fires once for each affected row
    ///   - Most common for BEFORE/AFTER triggers
    ///   - Can access NEW/OLD pseudo-records
    ///   - Example: Update timestamp on every modified row
    ///
    /// - **`.statement`** - Fires once per SQL statement, regardless of rows affected
    ///   - Use for operations independent of row count
    ///   - Cannot access NEW/OLD (no specific row context)
    ///   - Better performance for bulk operations
    ///   - Example: Log that a bulk update occurred
    ///
    /// ```swift
    /// // Row-level: Fires once per row (default)
    /// User.createTrigger(
    ///     timing: .before,
    ///     event: .update,
    ///     level: .row,
    ///     function: .updateTimestamp(column: \.updatedAt)
    /// )
    /// // UPDATE users SET status = 'active' WHERE ... fires trigger N times (N = affected rows)
    ///
    /// // Statement-level: Fires once per statement
    /// User.createTrigger(
    ///     timing: .after,
    ///     event: .update,
    ///     level: .statement,
    ///     function: bulkUpdateLogFunc
    /// )
    /// // UPDATE users SET status = 'active' WHERE ... fires trigger once
    /// ```
    ///
    /// **Note**: TRUNCATE only supports statement-level triggers (PostgreSQL limitation).
    ///
    /// ### `function` - Trigger Function (Required)
    ///
    /// The PL/pgSQL function to execute when the trigger fires. Use helper methods for common patterns
    /// or create custom functions for complex logic.
    ///
    /// **Helper Functions** (see ``Trigger/Function`` for complete list):
    ///
    /// ```swift
    /// // Timestamps
    /// .updateTimestamp(column: \.updatedAt)
    /// .createdAt(column: \.createdAt)
    ///
    /// // Audit logging
    /// .audit(to: AuditLog.self)
    ///
    /// // Soft deletion
    /// .softDelete(deletedAtColumn: \.deletedAt, identifiedBy: \.id)
    ///
    /// // Version management
    /// .incrementVersion(column: \.version)
    ///
    /// // Custom PL/pgSQL
    /// .define("custom_function") {
    ///     #sql("NEW.updated_at = CURRENT_TIMESTAMP")
    ///     #sql("RETURN NEW")
    /// }
    /// ```
    ///
    /// **Function Reuse**: Create a function once and use it across multiple triggers for efficiency:
    ///
    /// ```swift
    /// let auditFunc = Trigger.Function<User>.audit(to: AuditLog.self)
    /// User.createTrigger(timing: .after, event: .insert, function: auditFunc)
    /// User.createTrigger(timing: .after, event: .update, function: auditFunc)
    /// User.createTrigger(timing: .after, event: .delete, function: auditFunc)
    /// ```
    ///
    /// ## Type-Safe WHEN Clauses
    ///
    /// Each event type provides only the pseudo-records valid for that event, preventing invalid SQL
    /// at compile time:
    ///
    /// ```swift
    /// // ✅ INSERT provides only NEW
    /// .insert(when: { new in new.price > 0 })
    ///
    /// // ✅ UPDATE provides only NEW
    /// .update(when: { new in new.status == "active" })
    ///
    /// // ✅ DELETE provides only OLD
    /// .delete(when: { old in old.isArchived == true })
    ///
    /// // ❌ This won't compile - INSERT doesn't have OLD:
    /// .insert(when: { new, old in ... })  // Compile error!
    ///
    /// // ❌ This won't compile - DELETE doesn't have NEW:
    /// .delete(when: { new in ... })  // Compile error!
    /// ```
    ///
    /// ## Complete Examples
    ///
    /// ### Example 1: Automatic Timestamps
    ///
    /// ```swift
    /// // Set creation timestamp
    /// let createTrigger = User.createTrigger(
    ///     timing: .before,
    ///     event: .insert,
    ///     function: .createdAt(column: \.createdAt)
    /// )
    ///
    /// // Update modification timestamp
    /// let updateTrigger = User.createTrigger(
    ///     timing: .before,
    ///     event: .update,
    ///     function: .updateTimestamp(column: \.updatedAt)
    /// )
    ///
    /// try await createTrigger.execute(db)
    /// try await updateTrigger.execute(db)
    /// ```
    ///
    /// ### Example 2: Complete Audit Trail
    ///
    /// ```swift
    /// let auditFunc = Trigger.Function<User>.audit(to: UserAudit.self)
    ///
    /// // Track all operations with one function
    /// try await User.createTrigger(timing: .after, event: .insert, function: auditFunc).execute(db)
    /// try await User.createTrigger(timing: .after, event: .update, function: auditFunc).execute(db)
    /// try await User.createTrigger(timing: .after, event: .delete, function: auditFunc).execute(db)
    /// ```
    ///
    /// ### Example 3: Soft Delete with Conditional Trigger
    ///
    /// ```swift
    /// // Prevent hard deletes, mark as deleted instead
    /// let softDeleteTrigger = User.createTrigger(
    ///     timing: .before,
    ///     event: .delete(when: { old in old.deletedAt == nil }),  // Only soft-delete active rows
    ///     function: .softDelete(
    ///         deletedAtColumn: \.deletedAt,
    ///         identifiedBy: \.id
    ///     )
    /// )
    /// try await softDeleteTrigger.execute(db)
    /// ```
    ///
    /// ### Example 4: Optimistic Locking
    ///
    /// ```swift
    /// let versionTrigger = Document.createTrigger(
    ///     timing: .before,
    ///     event: .update,
    ///     function: .incrementVersion(column: \.version)
    /// )
    /// try await versionTrigger.execute(db)
    ///
    /// // Application code checks version to detect concurrent modifications:
    /// let updated = try await Document
    ///     .where { $0.id == docId && $0.version == expectedVersion }
    ///     .update { $0.content = newContent }
    /// guard updated > 0 else {
    ///     throw ConcurrentModificationError()
    /// }
    /// ```
    ///
    /// ### Example 5: Conditional Notification
    ///
    /// ```swift
    /// let notifyFunc = Trigger.Function<Task>.define("notify_high_priority") {
    ///     #sql("PERFORM pg_notify('high_priority_task', NEW.id::text)")
    ///     #sql("RETURN NEW")
    /// }
    ///
    /// let trigger = Task.createTrigger(
    ///     timing: .after,
    ///     event: .insert(when: { new in new.priority > 7 }),
    ///     function: notifyFunc
    /// )
    /// try await trigger.execute(db)
    /// ```
    ///
    /// ### Example 6: Multiple Events, One Trigger
    ///
    /// ```swift
    /// let auditFunc = Trigger.Function<Product>.audit(to: ProductAudit.self)
    ///
    /// let trigger = Product.createTrigger(
    ///     name: "audit_product_changes",
    ///     timing: .after,
    ///     event: .insert, .update(), .delete(),  // Multiple events
    ///     function: auditFunc
    /// )
    /// try await trigger.execute(db)
    /// // Generates: AFTER INSERT OR UPDATE OR DELETE
    /// ```
    ///
    /// ### Example 7: Controlling Execution Order
    ///
    /// ```swift
    /// // PostgreSQL fires triggers alphabetically by name
    /// let validateTrigger = User.createTrigger(
    ///     name: "0_validate_user",  // Fires first
    ///     timing: .before,
    ///     event: .insert,
    ///     function: validateFunc
    /// )
    ///
    /// let timestampTrigger = User.createTrigger(
    ///     name: "1_set_timestamps",  // Fires second
    ///     timing: .before,
    ///     event: .insert,
    ///     function: .createdAt(column: \.createdAt)
    /// )
    ///
    /// try await validateTrigger.execute(db)
    /// try await timestampTrigger.execute(db)
    /// ```
    ///
    /// ## Execution and Lifecycle
    ///
    /// ```swift
    /// let trigger = User.createTrigger(
    ///     timing: .before,
    ///     event: .update,
    ///     function: .updateTimestamp(column: \.updatedAt)
    /// )
    ///
    /// // Create both trigger and function
    /// try await trigger.execute(db)
    ///
    /// // Or execute them separately:
    /// try await trigger.function.execute(db)  // Create function first
    /// try await trigger.execute(db)           // Then create trigger
    ///
    /// // Drop trigger only (keep function for reuse)
    /// try await trigger.dropTrigger().execute(db)
    ///
    /// // Drop both trigger and function
    /// for statement in trigger.drop(ifExists: true) {
    ///     try await statement.execute(db)
    /// }
    /// ```
    ///
    /// ## Generated SQL
    ///
    /// ```swift
    /// let trigger = User.createTrigger(
    ///     timing: .before,
    ///     event: .update(of: { $0.email }, when: { new in new.email != nil }),
    ///     function: .updateTimestamp(column: \.updatedAt)
    /// )
    ///
    /// print(trigger.query.sql)
    /// // CREATE TRIGGER "users_before_update_update_updatedAt"
    /// // BEFORE UPDATE OF "email"
    /// // ON "users"
    /// // FOR EACH ROW
    /// // WHEN (NEW."email" IS NOT NULL)
    /// // EXECUTE FUNCTION "update_updatedAt_users"()
    /// ```
    ///
    /// ## See Also
    ///
    /// - ``Trigger`` - The trigger type
    /// - ``Trigger/Function`` - Trigger function creation and helpers
    /// - ``TriggerEvent`` - Type-safe event definitions
    /// - ``NEW`` and ``OLD`` - Pseudo-record types
    ///
    /// - Parameters:
    ///   - name: Optional trigger name. If `nil`, generates a stable, descriptive name automatically.
    ///   - timing: When the trigger fires (`.before`, `.after`, or `.insteadOf`).
    ///   - event: One or more trigger events with optional type-safe WHEN clauses.
    ///   - ifNotExists: Application-level error handling flag. Does NOT affect SQL generation.
    ///   - level: Row-level (`.row`, default) or statement-level (`.statement`).
    ///   - function: The trigger function to execute.
    /// - Returns: A trigger statement ready for execution.
    public static func createTrigger(
        name: String? = nil,
        timing: Trigger<Self>.Timing,
        event: Trigger<Self>.TriggerEvent...,
        ifNotExists: Bool = false,
        level: Trigger<Self>.Level = .row,
        function: Trigger<Self>.Function
    ) -> Trigger<Self> {
        let events = event.map(\.event)

        let triggerName: String
        if let name = name {
            triggerName = name
        } else {
            let timingStr: String
            switch timing {
            case .before: timingStr = "before"
            case .after: timingStr = "after"
            case .insteadOf: timingStr = "instead_of"
            }

            // Use first event for name generation
            triggerName = generateTriggerName(
                timing: timingStr,
                event: events.first!,
                function: function
            )
        }

        return Trigger(
            name: triggerName,
            timing: timing,
            events: events,
            level: level,
            function: function,
            ifNotExists: ifNotExists
        )
    }

    /// Generates a unique trigger name based on table, timing, event, and function.
    ///
    /// The generated name follows the pattern: `{table}_{timing}_{event}_{function_descriptor}`
    ///
    /// For example:
    /// - `users_before_update_update_updatedAt`
    /// - `posts_after_insert_audit_to_audit_log`
    /// - `documents_before_delete_soft_delete`
    ///
    /// This naming is stable across code edits (no line numbers or hashes) and provides
    /// clear, descriptive names that indicate what the trigger does.
    private static func generateTriggerName(
        timing: String,
        event: Trigger<Self>.Event,
        function: Trigger<Self>.Function
    ) -> String {
        let eventDesc: String
        switch event.kind {
        case .insert: eventDesc = "insert"
        case .update: eventDesc = "update"
        case .delete: eventDesc = "delete"
        case .truncate: eventDesc = "truncate"
        }

        // Extract function descriptor from function name
        // Function names like "update_updatedAt_users" → "update_updatedAt"
        // Function names like "audit_users_to_audit_log" → "audit_to_audit_log"
        let functionDesc = function.name
            .replacingOccurrences(of: "_\(Self.tableName)", with: "")

        return "\(Self.tableName)_\(timing)_\(eventDesc)_\(functionDesc)"
    }
}
