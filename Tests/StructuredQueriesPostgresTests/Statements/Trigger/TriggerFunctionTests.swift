import Foundation
import InlineSnapshotTesting
import StructuredQueriesCore
import StructuredQueriesPostgres
import StructuredQueriesPostgresSupport
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests.TriggerTests {
    /// Tests for Trigger.Function helper methods.
    ///
    /// These helpers provide semantic, type-safe ways to create common trigger functions.
    /// Each test demonstrates realistic usage patterns and validates the generated SQL.
    @Suite("Function Helpers")
    struct FunctionHelperTests {

        // MARK: - Test Models

        @Table("users")
        struct User: Identifiable {
            let id: Int
            var email: String
            var role: String
            var createdAt: Date?
            var updatedAt: Date?
            var version: Int
            var deletedAt: Date?
        }

        @Table("posts")
        struct Post: Identifiable {
            let id: Int
            var userId: Int
            var title: String
            var content: String
            var publishedAt: Date?
            var updatedAt: Date?
        }

        @Table("documents")
        struct Document: Identifiable {
            let id: Int
            var ownerId: Int
            var title: String
            var content: String
            var version: Int
            var updatedAt: Date?
        }

        @Table("audit_log")
        struct AuditLog: AuditTable, Identifiable {
            let id: Int
            var tableName: String
            var operation: String
            var oldData: String?
            var newData: String?
            var changedAt: Date
            var changedBy: String
        }

        // MARK: - Timestamp Helpers

        @Test("updateTimestamp() - Auto-update timestamp on row modification")
        func updateTimestamp() async {
            let trigger = User.createTrigger(
                timing: .before,
                event: .update,
                function: .updateTimestamp(column: \.updatedAt)
            )

            await assertSQL(of: trigger) {
                """
                CREATE TRIGGER "users_before_update_update_updatedAt"
                BEFORE UPDATE
                ON "users"
                FOR EACH ROW
                EXECUTE FUNCTION "update_updatedAt_users"()
                """
            }

            await assertSQL(of: trigger.function) {
                """
                CREATE OR REPLACE FUNCTION "update_updatedAt_users"()
                RETURNS TRIGGER AS $$
                BEGIN
                  NEW."updatedAt" = CURRENT_TIMESTAMP;
                  RETURN NEW;
                END
                $$ LANGUAGE plpgsql
                """
            }
        }

        @Test("createdAt() - Set creation timestamp on insert")
        func createdAt() async {
            let trigger = User.createTrigger(
                timing: .before,
                event: .insert,
                function: .createdAt(column: \.createdAt)
            )

            await assertSQL(of: trigger) {
                """
                CREATE TRIGGER "users_before_insert_set_createdAt"
                BEFORE INSERT
                ON "users"
                FOR EACH ROW
                EXECUTE FUNCTION "set_createdAt_users"()
                """
            }

            await assertSQL(of: trigger.function) {
                """
                CREATE OR REPLACE FUNCTION "set_createdAt_users"()
                RETURNS TRIGGER AS $$
                BEGIN
                  NEW."createdAt" = CURRENT_TIMESTAMP;
                  RETURN NEW;
                END
                $$ LANGUAGE plpgsql
                """
            }
        }

        @Test("updateTimestamps() - Update multiple timestamp columns at once")
        func updateTimestamps() async {
            let trigger = Post.createTrigger(
                timing: .before,
                event: .update,
                function: .updateTimestamps(columns: \.updatedAt, \.publishedAt)
            )

            await assertSQL(of: trigger) {
                """
                CREATE TRIGGER "posts_before_update_update_timestamps"
                BEFORE UPDATE
                ON "posts"
                FOR EACH ROW
                EXECUTE FUNCTION "update_timestamps_posts"()
                """
            }

            await assertSQL(of: trigger.function) {
                """
                CREATE OR REPLACE FUNCTION "update_timestamps_posts"()
                RETURNS TRIGGER AS $$
                BEGIN
                  NEW."updatedAt" = CURRENT_TIMESTAMP;
                    NEW."publishedAt" = CURRENT_TIMESTAMP;
                    RETURN NEW;
                END
                $$ LANGUAGE plpgsql
                """
            }
        }

        // MARK: - Version Increment

        @Test("incrementVersion() - Optimistic locking with version column")
        func incrementVersion() async {
            let trigger = Document.createTrigger(
                timing: .before,
                event: .update,
                function: .incrementVersion(column: \.version)
            )

            await assertSQL(of: trigger) {
                """
                CREATE TRIGGER "documents_before_update_increment_version"
                BEFORE UPDATE
                ON "documents"
                FOR EACH ROW
                EXECUTE FUNCTION "increment_version_documents"()
                """
            }

            await assertSQL(of: trigger.function) {
                """
                CREATE OR REPLACE FUNCTION "increment_version_documents"()
                RETURNS TRIGGER AS $$
                BEGIN
                  NEW."version" = OLD."version" + 1;
                  RETURN NEW;
                END
                $$ LANGUAGE plpgsql
                """
            }
        }

        // MARK: - Audit Logging

        @Test("audit() - Log all changes to audit table")
        func auditInsert() async {
            let auditFunc = Trigger<User>.Function.audit(to: AuditLog.self)
            let trigger = User.createTrigger(
                timing: .after,
                event: .insert,
                function: auditFunc
            )

            await assertSQL(of: trigger) {
                """
                CREATE TRIGGER "users_after_insert_audit_to_audit_log"
                AFTER INSERT
                ON "users"
                FOR EACH ROW
                EXECUTE FUNCTION "audit_users_to_audit_log"()
                """
            }

            await assertSQL(of: trigger.function) {
                """
                CREATE OR REPLACE FUNCTION "audit_users_to_audit_log"()
                RETURNS TRIGGER AS $$
                BEGIN
                  INSERT INTO "audit_log" (
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
                END
                $$ LANGUAGE plpgsql
                """
            }
        }

        @Test("audit() - Reusable function for multiple trigger events")
        func auditMultipleEvents() async {
            // Demonstrate that one audit function works for all events
            let auditFunc = Trigger<User>.Function.audit(to: AuditLog.self)

            let insertTrigger = User.createTrigger(
                timing: .after, event: .insert, function: auditFunc)
            let updateTrigger = User.createTrigger(
                timing: .after, event: .update, function: auditFunc)
            let deleteTrigger = User.createTrigger(
                timing: .after, event: .delete, function: auditFunc)

            // All triggers use the same function
            #expect(insertTrigger.function.name == updateTrigger.function.name)
            #expect(updateTrigger.function.name == deleteTrigger.function.name)
            #expect(insertTrigger.function.name == "audit_users_to_audit_log")
        }

        // MARK: - Validation

        @Test("validate() - Custom validation logic with PL/pgSQL")
        func validateEmail() async {
            let trigger = User.createTrigger(
                timing: .before,
                event: .insert,
                function: .validate(
                    """
                    IF NEW.email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}$' THEN
                        RAISE EXCEPTION 'Invalid email format: %', NEW.email;
                    END IF;
                    """)
            )

            await assertSQL(of: trigger) {
                """
                CREATE TRIGGER "users_before_insert_validate"
                BEFORE INSERT
                ON "users"
                FOR EACH ROW
                EXECUTE FUNCTION "validate_users"()
                """
            }

            await assertSQL(of: trigger.function) {
                #"""
                CREATE OR REPLACE FUNCTION "validate_users"()
                RETURNS TRIGGER AS $$
                BEGIN
                  IF NEW.email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$' THEN
                      RAISE EXCEPTION 'Invalid email format: %', NEW.email;
                  END IF;
                  RETURN NEW;
                END
                $$ LANGUAGE plpgsql
                """#
            }
        }

        // MARK: - Deletion Prevention

        @Test("preventDeletion() - Block all deletions with error message")
        func preventDeletion() async {
            let trigger = User.createTrigger(
                timing: .before,
                event: .delete,
                function: .preventDeletion(message: "Users cannot be deleted from the database")
            )

            await assertSQL(of: trigger) {
                """
                CREATE TRIGGER "users_before_delete_prevent_deletion"
                BEFORE DELETE
                ON "users"
                FOR EACH ROW
                EXECUTE FUNCTION "prevent_deletion_users"()
                """
            }

            await assertSQL(of: trigger.function) {
                """
                CREATE OR REPLACE FUNCTION "prevent_deletion_users"()
                RETURNS TRIGGER AS $$
                BEGIN
                  RAISE EXCEPTION 'Users cannot be deleted from the database';
                END
                $$ LANGUAGE plpgsql
                """
            }
        }

        @Test("preventDeletionWhen() - Conditionally prevent deletion based on column value")
        func preventDeletionWhen() async {
            let trigger = User.createTrigger(
                timing: .before,
                event: .delete,
                function: .preventDeletionWhen(
                    column: \.role,
                    equals: "admin",
                    message: "Cannot delete admin users"
                )
            )

            await assertSQL(of: trigger) {
                """
                CREATE TRIGGER "users_before_delete_prevent_deletion_when"
                BEFORE DELETE
                ON "users"
                FOR EACH ROW
                EXECUTE FUNCTION "prevent_deletion_when_users"()
                """
            }

            await assertSQL(of: trigger.function) {
                """
                CREATE OR REPLACE FUNCTION "prevent_deletion_when_users"()
                RETURNS TRIGGER AS $$
                BEGIN
                  IF OLD."role" = 'admin' THEN
                    RAISE EXCEPTION 'Cannot delete admin users';
                  END IF;
                  RETURN OLD;
                END
                $$ LANGUAGE plpgsql
                """
            }
        }

        @Test("softDelete() - Mark rows as deleted instead of removing them")
        func softDelete() async {
            let trigger = User.createTrigger(
                timing: .before,
                event: .delete,
                function: .softDelete(
                    deletedAtColumn: \.deletedAt,
                    identifiedBy: \.id
                )
            )

            await assertSQL(of: trigger) {
                """
                CREATE TRIGGER "users_before_delete_soft_delete"
                BEFORE DELETE
                ON "users"
                FOR EACH ROW
                EXECUTE FUNCTION "soft_delete_users"()
                """
            }

            await assertSQL(of: trigger.function) {
                """
                CREATE OR REPLACE FUNCTION "soft_delete_users"()
                RETURNS TRIGGER AS $$
                BEGIN
                  UPDATE "users"
                  SET "deletedAt" = CURRENT_TIMESTAMP
                  WHERE "id" = OLD."id";
                  RETURN NULL;
                END
                $$ LANGUAGE plpgsql
                """
            }
        }

        // MARK: - Row-Level Security

        @Test("enforceRowLevelSecurity() - Ensure users can only modify their own rows")
        func enforceRowLevelSecurity() async {
            let trigger = Document.createTrigger(
                timing: .before,
                event: .update,
                function: .enforceRowLevelSecurity(
                    column: \.ownerId,
                    matches: SQLQueryExpression("current_setting('app.current_user_id')::INT"),
                    message: "Access denied: document does not belong to current user"
                )
            )

            await assertSQL(of: trigger) {
                """
                CREATE TRIGGER "documents_before_update_enforce_rls"
                BEFORE UPDATE
                ON "documents"
                FOR EACH ROW
                EXECUTE FUNCTION "enforce_rls_documents"()
                """
            }

            await assertSQL(of: trigger.function) {
                """
                CREATE OR REPLACE FUNCTION "enforce_rls_documents"()
                RETURNS TRIGGER AS $$
                BEGIN
                  IF NEW."ownerId" != current_setting('app.current_user_id')::INT THEN
                    RAISE EXCEPTION 'Access denied: document does not belong to current user';
                  END IF;
                  RETURN NEW;
                END
                $$ LANGUAGE plpgsql
                """
            }
        }

        // MARK: - Real-World Scenarios

        @Test("Scenario: Complete audit trail for user table")
        func completeAuditTrail() async {
            // One function handles all events
            let auditFunc = Trigger<User>.Function.audit(to: AuditLog.self)

            let insertTrigger = User.createTrigger(
                name: "audit_user_insert", timing: .after, event: .insert, function: auditFunc)
            let updateTrigger = User.createTrigger(
                name: "audit_user_update", timing: .after, event: .update, function: auditFunc)
            let deleteTrigger = User.createTrigger(
                name: "audit_user_delete", timing: .after, event: .delete, function: auditFunc)

            // Verify all triggers use same function (efficient - one function, multiple triggers)
            #expect(insertTrigger.function.name == "audit_users_to_audit_log")
            #expect(updateTrigger.function.name == "audit_users_to_audit_log")
            #expect(deleteTrigger.function.name == "audit_users_to_audit_log")
        }

        @Test("Scenario: Document with timestamp, version, and security")
        func documentWithMultipleFeatures() async {
            // Multiple triggers for different concerns
            let timestampTrigger = Document.createTrigger(
                timing: .before,
                event: .update,
                function: .updateTimestamp(column: \.updatedAt)
            )

            let versionTrigger = Document.createTrigger(
                timing: .before,
                event: .update,
                function: .incrementVersion(column: \.version)
            )

            let securityTrigger = Document.createTrigger(
                timing: .before,
                event: .update,
                function: .enforceRowLevelSecurity(
                    column: \.ownerId,
                    matches: SQLQueryExpression("current_setting('app.current_user_id')::INT")
                )
            )

            // Each trigger has its own function (separation of concerns)
            #expect(timestampTrigger.function.name == "update_updatedAt_documents")
            #expect(versionTrigger.function.name == "increment_version_documents")
            #expect(securityTrigger.function.name == "enforce_rls_documents")
        }

        @Test("Scenario: User lifecycle with timestamps and soft delete")
        func userLifecycle() async {
            // Creation timestamp
            let createTrigger = User.createTrigger(
                timing: .before,
                event: .insert,
                function: .createdAt(column: \.createdAt)
            )

            // Update timestamp
            let updateTrigger = User.createTrigger(
                timing: .before,
                event: .update,
                function: .updateTimestamp(column: \.updatedAt)
            )

            // Soft delete instead of hard delete
            let deleteTrigger = User.createTrigger(
                timing: .before,
                event: .delete,
                function: .softDelete(
                    deletedAtColumn: \.deletedAt,
                    identifiedBy: \.id
                )
            )

            #expect(createTrigger.function.name == "set_createdAt_users")
            #expect(updateTrigger.function.name == "update_updatedAt_users")
            #expect(deleteTrigger.function.name == "soft_delete_users")
        }
    }
}
