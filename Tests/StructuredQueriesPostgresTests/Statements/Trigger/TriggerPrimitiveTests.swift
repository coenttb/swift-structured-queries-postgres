import Foundation
import InlineSnapshotTesting
import StructuredQueriesCore
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests.TriggerTests {
    /// Tests for low-level trigger primitives and core functionality.
    ///
    /// These tests validate the fundamental building blocks of the trigger system:
    /// - Event types and combinations
    /// - Timing (BEFORE, AFTER, INSTEAD OF)
    /// - Level (ROW, STATEMENT)
    /// - WHEN conditions with NEW/OLD pseudo-records
    /// - DROP statements
    /// - Custom PL/pgSQL functions
    @Suite("Primitives")
    struct PrimitiveTests {

        // MARK: - Test Models

        @Table("reminders")
        struct Reminder {
            let id: Int
            var title: String
            var isCompleted: Bool
            var priority: Int
            var createdAt: Date?
            var updatedAt: Date?
        }

        @Table("products")
        struct Product {
            let id: Int
            var name: String
            var price: Double
            var stock: Int
        }

        // MARK: - Basic Trigger Creation

        @Test("Basic trigger with explicit function reference")
        func basicTrigger() async {
            let function = Trigger<Reminder>.Function.plpgsql(
                "update_reminder_timestamp",
                """
                NEW."updatedAt" = CURRENT_TIMESTAMP;
                RETURN NEW;
                """
            )

            let trigger = Reminder.createTrigger(
                name: "reminder_update_timestamp",
                timing: .before,
                event: .update,
                function: function
            )

            await assertSQL(of: trigger) {
                """
                CREATE TRIGGER "reminder_update_timestamp"
                BEFORE UPDATE
                ON "reminders"
                FOR EACH ROW
                EXECUTE FUNCTION "update_reminder_timestamp"()
                """
            }
        }

        @Test("Function definition generates CREATE OR REPLACE FUNCTION")
        func functionDefinition() async {
            let function = Trigger<Reminder>.Function.plpgsql(
                "my_custom_function",
                "RETURN NEW;"
            )

            await assertSQL(of: function) {
                """
                CREATE OR REPLACE FUNCTION "my_custom_function"()
                RETURNS TRIGGER AS $$
                BEGIN
                  RETURN NEW;
                END
                $$ LANGUAGE plpgsql
                """
            }
        }

        // MARK: - Event Types

        @Test("INSERT event")
        func insertEvent() async {
            let function = Trigger<Reminder>.Function.plpgsql("on_insert", "RETURN NEW;")
            let trigger = Reminder.createTrigger(
                name: "reminder_insert",
                timing: .after,
                event: .insert,
                function: function
            )

            await assertSQL(of: trigger) {
                """
                CREATE TRIGGER "reminder_insert"
                AFTER INSERT
                ON "reminders"
                FOR EACH ROW
                EXECUTE FUNCTION "on_insert"()
                """
            }
        }

        @Test("UPDATE event")
        func updateEvent() async {
            let function = Trigger<Reminder>.Function.plpgsql("on_update", "RETURN NEW;")
            let trigger = Reminder.createTrigger(
                name: "reminder_update",
                timing: .before,
                event: .update,
                function: function
            )

            await assertSQL(of: trigger) {
                """
                CREATE TRIGGER "reminder_update"
                BEFORE UPDATE
                ON "reminders"
                FOR EACH ROW
                EXECUTE FUNCTION "on_update"()
                """
            }
        }

        @Test("DELETE event")
        func deleteEvent() async {
            let function = Trigger<Reminder>.Function.plpgsql("on_delete", "RETURN OLD;")
            let trigger = Reminder.createTrigger(
                name: "reminder_delete",
                timing: .after,
                event: .delete,
                function: function
            )

            await assertSQL(of: trigger) {
                """
                CREATE TRIGGER "reminder_delete"
                AFTER DELETE
                ON "reminders"
                FOR EACH ROW
                EXECUTE FUNCTION "on_delete"()
                """
            }
        }

        @Test("TRUNCATE event")
        func truncateEvent() async {
            let function = Trigger<Reminder>.Function.plpgsql("on_truncate", "RETURN NULL;")
            let trigger = Reminder.createTrigger(
                name: "reminder_truncate",
                timing: .after,
                event: .truncate,
                level: .statement,
                function: function
            )

            await assertSQL(of: trigger) {
                """
                CREATE TRIGGER "reminder_truncate"
                AFTER TRUNCATE
                ON "reminders"
                FOR EACH STATEMENT
                EXECUTE FUNCTION "on_truncate"()
                """
            }
        }

        @Test("UPDATE OF specific columns")
        func updateOfColumns() async {
            let function = Trigger<Reminder>.Function.plpgsql("on_title_change", "RETURN NEW;")
            let trigger = Reminder.createTrigger(
                name: "reminder_title_change",
                timing: .after,
                event: .update(of: { ($0.title, $0.priority) }),
                function: function
            )

            await assertSQL(of: trigger) {
                """
                CREATE TRIGGER "reminder_title_change"
                AFTER UPDATE OF "title", "priority"
                ON "reminders"
                FOR EACH ROW
                EXECUTE FUNCTION "on_title_change"()
                """
            }
        }

        // NOTE: Multiple events in a single trigger are no longer supported through the public API.
        // The new unified API takes a single `event` parameter instead of `events: [Event]`.
        // To handle multiple events, create separate triggers for each event type.
        //
        // @Test("Multiple events (INSERT OR UPDATE OR DELETE)")
        // func multipleEvents() async {
        //     let function = Trigger<Reminder>.Function.plpgsql("on_change", "RETURN COALESCE(NEW, OLD);")
        //     let trigger = Reminder.createTrigger(
        //         name: "reminder_all_changes",
        //         timing: .after,
        //         event: .insert,  // Now single event only
        //         function: function
        //     )
        // }

        // MARK: - Timing

        @Test("BEFORE timing")
        func beforeTiming() async {
            let function = Trigger<Reminder>.Function.plpgsql("before_func", "RETURN NEW;")
            let trigger = Reminder.createTrigger(
                name: "before_trigger",
                timing: .before,
                event: .insert,
                function: function
            )

            await assertSQL(of: trigger) {
                """
                CREATE TRIGGER "before_trigger"
                BEFORE INSERT
                ON "reminders"
                FOR EACH ROW
                EXECUTE FUNCTION "before_func"()
                """
            }
        }

        @Test("AFTER timing")
        func afterTiming() async {
            let function = Trigger<Reminder>.Function.plpgsql("after_func", "RETURN NEW;")
            let trigger = Reminder.createTrigger(
                name: "after_trigger",
                timing: .after,
                event: .insert,
                function: function
            )

            await assertSQL(of: trigger) {
                """
                CREATE TRIGGER "after_trigger"
                AFTER INSERT
                ON "reminders"
                FOR EACH ROW
                EXECUTE FUNCTION "after_func"()
                """
            }
        }

        @Test("INSTEAD OF timing (for views)")
        func insteadOfTiming() async {
            let function = Trigger<Reminder>.Function.plpgsql("instead_func", "RETURN NEW;")
            let trigger = Reminder.createTrigger(
                name: "instead_trigger",
                timing: .insteadOf,
                event: .update,
                function: function
            )

            await assertSQL(of: trigger) {
                """
                CREATE TRIGGER "instead_trigger"
                INSTEAD OF UPDATE
                ON "reminders"
                FOR EACH ROW
                EXECUTE FUNCTION "instead_func"()
                """
            }
        }

        // MARK: - Level

        @Test("FOR EACH ROW level (default)")
        func rowLevel() async {
            let function = Trigger<Reminder>.Function.plpgsql("row_func", "RETURN NEW;")
            let trigger = Reminder.createTrigger(
                name: "row_trigger",
                timing: .after,
                event: .insert,
                level: .row,
                function: function
            )

            await assertSQL(of: trigger) {
                """
                CREATE TRIGGER "row_trigger"
                AFTER INSERT
                ON "reminders"
                FOR EACH ROW
                EXECUTE FUNCTION "row_func"()
                """
            }
        }

        @Test("FOR EACH STATEMENT level")
        func statementLevel() async {
            let function = Trigger<Reminder>.Function.plpgsql("statement_func", "RETURN NULL;")
            let trigger = Reminder.createTrigger(
                name: "statement_trigger",
                timing: .after,
                event: .update,
                level: .statement,
                function: function
            )

            await assertSQL(of: trigger) {
                """
                CREATE TRIGGER "statement_trigger"
                AFTER UPDATE
                ON "reminders"
                FOR EACH STATEMENT
                EXECUTE FUNCTION "statement_func"()
                """
            }
        }

        // MARK: - WHEN Conditions

        @Test("WHEN condition with NEW pseudo-record (INSERT)")
        func whenConditionNew() async {
            let trigger = Reminder.createTrigger(
                name: "high_priority_insert",
                timing: .after,
                event: .insert(when: { new in new.priority > 5 }),
                function: .plpgsql("high_priority", "RETURN NEW;")
            )

            await assertSQL(of: trigger) {
                """
                CREATE TRIGGER "high_priority_insert"
                AFTER INSERT
                ON "reminders"
                FOR EACH ROW
                WHEN ((NEW."priority") > (5))
                EXECUTE FUNCTION "high_priority"()
                """
            }
        }

        @Test("WHEN condition with OLD pseudo-record (DELETE)")
        func whenConditionOld() async {
            let function = Trigger<Reminder>.Function.plpgsql("completed_only", "RETURN OLD;")
            let trigger = Reminder.createTrigger(
                name: "delete_completed",
                timing: .before,
                event: .delete(when: { old in old.isCompleted == true }),
                function: function
            )

            await assertSQL(of: trigger) {
                """
                CREATE TRIGGER "delete_completed"
                BEFORE DELETE
                ON "reminders"
                FOR EACH ROW
                WHEN ((OLD."isCompleted") = (true))
                EXECUTE FUNCTION "completed_only"()
                """
            }
        }

        @Test("WHEN condition with NEW on UPDATE")
        func whenConditionUpdate() async {
            let function = Trigger<Product>.Function.plpgsql("price_increase", "RETURN NEW;")
            let trigger = Product.createTrigger(
                name: "track_price_increase",
                timing: .after,
                event: .update(of: { $0.price }, when: { new in new.price > 100 }),
                function: function
            )

            await assertSQL(of: trigger) {
                """
                CREATE TRIGGER "track_price_increase"
                AFTER UPDATE OF "price"
                ON "products"
                FOR EACH ROW
                WHEN ((NEW."price") > (100.0))
                EXECUTE FUNCTION "price_increase"()
                """
            }
        }

        @Test("WHEN condition with complex expression")
        func whenConditionComplex() async {
            let function = Trigger<Reminder>.Function.plpgsql("urgent_incomplete", "RETURN NEW;")
            let trigger = Reminder.createTrigger(
                name: "urgent_reminder",
                timing: .after,
                event: .insert(when: { new in new.priority > 7 && new.isCompleted == false }),
                function: function
            )

            await assertSQL(of: trigger) {
                """
                CREATE TRIGGER "urgent_reminder"
                AFTER INSERT
                ON "reminders"
                FOR EACH ROW
                WHEN (((NEW."priority") > (7)) AND (NEW."isCompleted") = (false))
                EXECUTE FUNCTION "urgent_incomplete"()
                """
            }
        }

        // MARK: - DROP Statements

        @Test("DROP TRIGGER")
        func dropTrigger() async {
            let function = Trigger<Reminder>.Function.plpgsql("my_func", "RETURN NEW;")
            let trigger = Reminder.createTrigger(
                name: "my_trigger", timing: .after, event: .insert, function: function)

            let dropStatement = trigger.dropTrigger()

            assertInlineSnapshot(of: dropStatement, as: .sql) {
                """
                DROP TRIGGER "my_trigger" ON "reminders"
                """
            }
        }

        @Test("DROP TRIGGER IF EXISTS")
        func dropTriggerIfExists() async {
            let function = Trigger<Reminder>.Function.plpgsql("my_func", "RETURN NEW;")
            let trigger = Reminder.createTrigger(
                name: "my_trigger", timing: .after, event: .insert, function: function)

            let dropStatement = trigger.dropTrigger(ifExists: true)

            assertInlineSnapshot(of: dropStatement, as: .sql) {
                """
                DROP TRIGGER IF EXISTS "my_trigger" ON "reminders"
                """
            }
        }

        @Test("DROP TRIGGER CASCADE")
        func dropTriggerCascade() async {
            let function = Trigger<Reminder>.Function.plpgsql("my_func", "RETURN NEW;")
            let trigger = Reminder.createTrigger(
                name: "my_trigger", timing: .after, event: .insert, function: function)

            let dropStatement = trigger.dropTrigger(cascade: true)

            assertInlineSnapshot(of: dropStatement, as: .sql) {
                """
                DROP TRIGGER "my_trigger" ON "reminders" CASCADE
                """
            }
        }

        @Test("DROP both trigger and function")
        func dropBoth() async {
            let function = Trigger<Reminder>.Function.plpgsql("my_func", "RETURN NEW;")
            let trigger = Reminder.createTrigger(
                name: "my_trigger", timing: .after, event: .insert, function: function)

            let dropStatements = trigger.drop(ifExists: true, cascade: false)

            #expect(dropStatements.count == 2)

            // Convert to concrete types for snapshot testing
            let dropTrigger = trigger.dropTrigger(ifExists: true)
            let dropFunction = function.drop(ifExists: true)

            assertInlineSnapshot(of: dropTrigger, as: .sql) {
                """
                DROP TRIGGER IF EXISTS "my_trigger" ON "reminders"
                """
            }

            assertInlineSnapshot(of: dropFunction, as: .sql) {
                """
                DROP FUNCTION IF EXISTS "my_func"()
                """
            }
        }

        @Test("DROP FUNCTION")
        func dropFunction() async {
            let function = Trigger<Reminder>.Function.plpgsql("standalone_func", "RETURN NEW;")

            let dropStatement = function.drop()

            assertInlineSnapshot(of: dropStatement, as: .sql) {
                """
                DROP FUNCTION "standalone_func"()
                """
            }
        }

        @Test("DROP FUNCTION IF EXISTS CASCADE")
        func dropFunctionIfExistsCascade() async {
            let function = Trigger<Reminder>.Function.plpgsql("shared_func", "RETURN NEW;")

            let dropStatement = function.drop(ifExists: true, cascade: true)

            assertInlineSnapshot(of: dropStatement, as: .sql) {
                """
                DROP FUNCTION IF EXISTS "shared_func"() CASCADE
                """
            }
        }

        // MARK: - Custom PL/pgSQL Functions

        @Test("Custom function with multiple statements")
        func customFunctionMultipleStatements() async {
            let function = Trigger<Reminder>.Function.plpgsql(
                "complex_function",
                """
                IF NEW.priority > OLD.priority THEN
                  NEW."updatedAt" = CURRENT_TIMESTAMP;
                END IF;
                RETURN NEW;
                """
            )

            await assertSQL(of: function) {
                """
                CREATE OR REPLACE FUNCTION "complex_function"()
                RETURNS TRIGGER AS $$
                BEGIN
                  IF NEW.priority > OLD.priority THEN
                    NEW."updatedAt" = CURRENT_TIMESTAMP;
                  END IF;
                  RETURN NEW;
                END
                $$ LANGUAGE plpgsql
                """
            }
        }

        @Test("Function using PostgreSQL special variables")
        func functionWithSpecialVariables() async {
            let function = Trigger<Reminder>.Function.plpgsql(
                "log_operation",
                """
                RAISE NOTICE 'Operation % on table % at level %', TG_OP, TG_TABLE_NAME, TG_LEVEL;
                RETURN COALESCE(NEW, OLD);
                """
            )

            await assertSQL(of: function) {
                """
                CREATE OR REPLACE FUNCTION "log_operation"()
                RETURNS TRIGGER AS $$
                BEGIN
                  RAISE NOTICE 'Operation % on table % at level %', TG_OP, TG_TABLE_NAME, TG_LEVEL;
                  RETURN COALESCE(NEW, OLD);
                END
                $$ LANGUAGE plpgsql
                """
            }
        }

        @Test("Function with RETURN NULL (cancels operation in BEFORE)")
        func functionReturnNull() async {
            let function = Trigger<Reminder>.Function.plpgsql(
                "cancel_operation",
                """
                IF NEW.priority < 0 THEN
                  RETURN NULL;
                END IF;
                RETURN NEW;
                """
            )

            await assertSQL(of: function) {
                """
                CREATE OR REPLACE FUNCTION "cancel_operation"()
                RETURNS TRIGGER AS $$
                BEGIN
                  IF NEW.priority < 0 THEN
                    RETURN NULL;
                  END IF;
                  RETURN NEW;
                END
                $$ LANGUAGE plpgsql
                """
            }
        }

        // MARK: - Real-World Scenarios

        @Test("Scenario: Audit trigger capturing operation type")
        func auditTriggerOperationType() async {
            let function = Trigger<Product>.Function.plpgsql(
                "audit_product_changes",
                """
                INSERT INTO audit_log (table_name, operation, row_data, changed_at)
                VALUES (TG_TABLE_NAME, TG_OP, to_jsonb(NEW), CURRENT_TIMESTAMP);
                RETURN NEW;
                """
            )

            // NOTE: Multiple events are no longer supported in the public API.
            // Create separate triggers for each event instead.
            let trigger = Product.createTrigger(
                name: "product_audit_insert",
                timing: .after,
                event: .insert,
                function: function
            )

            await assertSQL(of: trigger.function) {
                """
                CREATE OR REPLACE FUNCTION "audit_product_changes"()
                RETURNS TRIGGER AS $$
                BEGIN
                  INSERT INTO audit_log (table_name, operation, row_data, changed_at)
                  VALUES (TG_TABLE_NAME, TG_OP, to_jsonb(NEW), CURRENT_TIMESTAMP);
                  RETURN NEW;
                END
                $$ LANGUAGE plpgsql
                """
            }
        }

        @Test("Scenario: Conditional notification based on column change")
        func conditionalNotification() async {
            let function = Trigger<Product>.Function.plpgsql(
                "notify_low_stock",
                """
                IF NEW.stock < 10 THEN
                  PERFORM pg_notify('low_stock', json_build_object('product_id', NEW.id, 'stock', NEW.stock)::text);
                END IF;
                RETURN NEW;
                """
            )

            let trigger = Product.createTrigger(
                name: "low_stock_alert",
                timing: .after,
                event: .update(of: { $0.stock }, when: { new in new.stock < 10 }),
                function: function
            )

            await assertSQL(of: trigger) {
                """
                CREATE TRIGGER "low_stock_alert"
                AFTER UPDATE OF "stock"
                ON "products"
                FOR EACH ROW
                WHEN ((NEW."stock") < (10))
                EXECUTE FUNCTION "notify_low_stock"()
                """
            }
        }

        // MARK: - Type Safety Tests

        @Test("Type safety: INSERT WHEN uses only NEW pseudo-record")
        func typeSafetyInsertUsesNew() async {
            let function = Trigger<Product>.Function.plpgsql("validate", "RETURN NEW;")

            // ✅ This compiles - INSERT can access NEW
            let trigger = Product.createTrigger(
                timing: .before,
                event: .insert(when: { new in new.price > 0 }),
                function: function
            )

            await assertSQL(of: trigger) {
                """
                CREATE TRIGGER "products_before_insert_validate"
                BEFORE INSERT
                ON "products"
                FOR EACH ROW
                WHEN ((NEW."price") > (0.0))
                EXECUTE FUNCTION "validate"()
                """
            }
        }

        @Test("Type safety: DELETE WHEN uses only OLD pseudo-record")
        func typeSafetyDeleteUsesOld() async {
            let function = Trigger<Product>.Function.plpgsql("archive", "RETURN OLD;")

            // ✅ This compiles - DELETE can access OLD
            let trigger = Product.createTrigger(
                timing: .before,
                event: .delete(when: { old in old.price > 100 }),
                function: function
            )

            await assertSQL(of: trigger) {
                """
                CREATE TRIGGER "products_before_delete_archive"
                BEFORE DELETE
                ON "products"
                FOR EACH ROW
                WHEN ((OLD."price") > (100.0))
                EXECUTE FUNCTION "archive"()
                """
            }
        }

        @Test("Type safety: UPDATE WHEN uses NEW pseudo-record")
        func typeSafetyUpdateUsesNew() async {
            let function = Trigger<Product>.Function.plpgsql("validate", "RETURN NEW;")

            // ✅ This compiles - UPDATE uses NEW for WHEN clause
            let trigger = Product.createTrigger(
                timing: .before,
                event: .update(when: { new in new.price > 0 }),
                function: function
            )

            await assertSQL(of: trigger) {
                """
                CREATE TRIGGER "products_before_update_validate"
                BEFORE UPDATE
                ON "products"
                FOR EACH ROW
                WHEN ((NEW."price") > (0.0))
                EXECUTE FUNCTION "validate"()
                """
            }
        }

        @Test("Type safety: Multiple events without WHEN clauses")
        func typeSafetyMultipleEventsNoWhen() async {
            let function = Trigger<Product>.Function.plpgsql("audit", "RETURN COALESCE(NEW, OLD);")

            // ✅ This compiles - Multiple events without WHEN is allowed
            let trigger = Product.createTrigger(
                name: "audit_all_changes",
                timing: .after,
                event: .insert, .update(), .delete(),
                function: function
            )

            await assertSQL(of: trigger) {
                """
                CREATE TRIGGER "audit_all_changes"
                AFTER INSERT OR UPDATE OR DELETE
                ON "products"
                FOR EACH ROW
                EXECUTE FUNCTION "audit"()
                """
            }
        }

        @Test("Type safety: Multiple compatible events with same WHEN")
        func typeSafetyMultipleEventsWithSameWhen() async {
            let function = Trigger<Product>.Function.plpgsql("validate", "RETURN NEW;")

            // ✅ This compiles - INSERT and UPDATE both use NEW
            let trigger = Product.createTrigger(
                name: "validate_price",
                timing: .before,
                event: .insert(when: { new in new.price > 0 }),
                .update(when: { new in new.price > 0 }),
                function: function
            )

            await assertSQL(of: trigger) {
                """
                CREATE TRIGGER "validate_price"
                BEFORE INSERT OR UPDATE
                ON "products"
                FOR EACH ROW
                WHEN ((NEW."price") > (0.0))
                EXECUTE FUNCTION "validate"()
                """
            }
        }
    }
}
