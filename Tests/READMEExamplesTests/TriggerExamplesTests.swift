import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

/// Tests for Trigger examples shown in README.md
@Suite("README Examples - Triggers")
struct TriggerExamplesTests {

    // MARK: - Test Models

    @Table
    struct Product {
        let id: Int
        var name: String
        var price: Double
        var stock: Int
        var updatedAt: Date?
    }

    @Table
    struct AuditLog {
        let id: Int
        var tableName: String
        var operation: String
        var recordId: Int
        var changedAt: Date
    }

    // MARK: - Basic Triggers

    @Test("README Example: BEFORE UPDATE trigger with timestamp")
    func beforeUpdateTrigger() async {
        let trigger = Product.createTrigger(
            name: "product_update_timestamp",
            timing: .before,
            event: .update,
            function: .plpgsql(
                "update_timestamp",
                """
                NEW."updatedAt" = CURRENT_TIMESTAMP;
                RETURN NEW;
                """
            )
        )

        await assertSQL(of: trigger) {
            """
            CREATE TRIGGER "product_update_timestamp"
            BEFORE UPDATE
            ON "products"
            FOR EACH ROW
            EXECUTE FUNCTION "update_timestamp"()
            """
        }
    }

    @Test("README Example: AFTER INSERT trigger for audit logging")
    func afterInsertAuditTrigger() async {
        let trigger = Product.createTrigger(
            name: "product_audit_insert",
            timing: .after,
            event: .insert,
            function: .plpgsql(
                "audit_insert",
                """
                INSERT INTO audit_logs (table_name, operation, record_id, changed_at)
                VALUES ('products', 'INSERT', NEW.id, CURRENT_TIMESTAMP);
                RETURN NEW;
                """
            )
        )

        await assertSQL(of: trigger) {
            """
            CREATE TRIGGER "product_audit_insert"
            AFTER INSERT
            ON "products"
            FOR EACH ROW
            EXECUTE FUNCTION "audit_insert"()
            """
        }
    }

    @Test("README Example: BEFORE DELETE trigger validation")
    func beforeDeleteTrigger() async {
        let trigger = Product.createTrigger(
            name: "prevent_delete_if_stock",
            timing: .before,
            event: .delete,
            function: .plpgsql(
                "prevent_delete",
                """
                IF OLD.stock > 0 THEN
                  RAISE EXCEPTION 'Cannot delete product with stock > 0';
                END IF;
                RETURN OLD;
                """
            )
        )

        await assertSQL(of: trigger) {
            """
            CREATE TRIGGER "prevent_delete_if_stock"
            BEFORE DELETE
            ON "products"
            FOR EACH ROW
            EXECUTE FUNCTION "prevent_delete"()
            """
        }
    }

    // MARK: - Triggers with WHEN Conditions

    @Test("README Example: Trigger with WHEN condition on NEW record")
    func triggerWithWhenNew() async {
        let trigger = Product.createTrigger(
            name: "low_stock_alert",
            timing: .after,
            event: .update(
                of: { $0.stock },
                when: { new in new.stock < 10 }
            ),
            function: .plpgsql(
                "notify_low_stock",
                """
                PERFORM pg_notify('low_stock', json_build_object('product_id', NEW.id, 'stock', NEW.stock)::text);
                RETURN NEW;
                """
            )
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

    @Test("README Example: Trigger with complex WHEN condition")
    func triggerComplexWhen() async {
        let trigger = Product.createTrigger(
            name: "significant_price_change",
            timing: .after,
            event: .update(
                of: { $0.price },
                when: { new in new.price > 100.0 }
            ),
            function: .plpgsql(
                "log_price_change",
                """
                INSERT INTO price_history (product_id, old_price, new_price, changed_at)
                VALUES (NEW.id, OLD.price, NEW.price, CURRENT_TIMESTAMP);
                RETURN NEW;
                """
            )
        )

        await assertSQL(of: trigger) {
            """
            CREATE TRIGGER "significant_price_change"
            AFTER UPDATE OF "price"
            ON "products"
            FOR EACH ROW
            WHEN ((NEW."price") > (100.0))
            EXECUTE FUNCTION "log_price_change"()
            """
        }
    }

    @Test("README Example: DELETE trigger with OLD record condition")
    func deleteWithOldCondition() async {
        let trigger = Product.createTrigger(
            name: "archive_expensive_products",
            timing: .before,
            event: .delete(when: { old in old.price > 1000.0 }),
            function: .plpgsql(
                "archive_product",
                """
                INSERT INTO archived_products SELECT OLD.*;
                RETURN OLD;
                """
            )
        )

        await assertSQL(of: trigger) {
            """
            CREATE TRIGGER "archive_expensive_products"
            BEFORE DELETE
            ON "products"
            FOR EACH ROW
            WHEN ((OLD."price") > (1000.0))
            EXECUTE FUNCTION "archive_product"()
            """
        }
    }

    // MARK: - PL/pgSQL Function Examples

    @Test("README Example: Trigger function definition")
    func functionDefinition() async {
        let function = Trigger<Product>.Function.plpgsql(
            "update_product_timestamp",
            """
            NEW."updatedAt" = CURRENT_TIMESTAMP;
            RETURN NEW;
            """
        )

        await assertSQL(of: function) {
            """
            CREATE OR REPLACE FUNCTION "update_product_timestamp"()
            RETURNS TRIGGER AS $$
            BEGIN
              NEW."updatedAt" = CURRENT_TIMESTAMP;
              RETURN NEW;
            END
            $$ LANGUAGE plpgsql
            """
        }
    }

    @Test("README Example: Complex PL/pgSQL function with IF statement")
    func complexFunction() async {
        let function = Trigger<Product>.Function.plpgsql(
            "validate_price_change",
            """
            IF NEW.price < OLD.price * 0.5 THEN
              RAISE EXCEPTION 'Price decrease exceeds 50%%';
            END IF;
            IF NEW.price > OLD.price * 2.0 THEN
              RAISE NOTICE 'Significant price increase: % to %', OLD.price, NEW.price;
            END IF;
            NEW."updatedAt" = CURRENT_TIMESTAMP;
            RETURN NEW;
            """
        )

        await assertSQL(of: function) {
            """
            CREATE OR REPLACE FUNCTION "validate_price_change"()
            RETURNS TRIGGER AS $$
            BEGIN
              IF NEW.price < OLD.price * 0.5 THEN
                RAISE EXCEPTION 'Price decrease exceeds 50%%';
              END IF;
              IF NEW.price > OLD.price * 2.0 THEN
                RAISE NOTICE 'Significant price increase: % to %', OLD.price, NEW.price;
              END IF;
              NEW."updatedAt" = CURRENT_TIMESTAMP;
              RETURN NEW;
            END
            $$ LANGUAGE plpgsql
            """
        }
    }

    @Test("README Example: Function using PostgreSQL TG_ variables")
    func functionWithTGVariables() async {
        let function = Trigger<Product>.Function.plpgsql(
            "log_operation_details",
            """
            RAISE NOTICE 'Operation: %, Table: %, Level: %', TG_OP, TG_TABLE_NAME, TG_LEVEL;
            RAISE NOTICE 'Trigger: %, When: %', TG_NAME, TG_WHEN;
            RETURN COALESCE(NEW, OLD);
            """
        )

        await assertSQL(of: function) {
            """
            CREATE OR REPLACE FUNCTION "log_operation_details"()
            RETURNS TRIGGER AS $$
            BEGIN
              RAISE NOTICE 'Operation: %, Table: %, Level: %', TG_OP, TG_TABLE_NAME, TG_LEVEL;
              RAISE NOTICE 'Trigger: %, When: %', TG_NAME, TG_WHEN;
              RETURN COALESCE(NEW, OLD);
            END
            $$ LANGUAGE plpgsql
            """
        }
    }

    // MARK: - Multiple Events

    @Test("README Example: Trigger for multiple events (INSERT, UPDATE, DELETE)")
    func multipleEvents() async {
        let trigger = Product.createTrigger(
            name: "audit_all_changes",
            timing: .after,
            event: .insert, .update(), .delete(),
            function: .plpgsql(
                "audit_changes",
                """
                INSERT INTO audit_logs (table_name, operation, record_id, changed_at)
                VALUES (
                  TG_TABLE_NAME,
                  TG_OP,
                  COALESCE(NEW.id, OLD.id),
                  CURRENT_TIMESTAMP
                );
                RETURN COALESCE(NEW, OLD);
                """
            )
        )

        await assertSQL(of: trigger) {
            """
            CREATE TRIGGER "audit_all_changes"
            AFTER INSERT OR UPDATE OR DELETE
            ON "products"
            FOR EACH ROW
            EXECUTE FUNCTION "audit_changes"()
            """
        }
    }

    // MARK: - Statement-Level Triggers

    @Test("README Example: Statement-level trigger")
    func statementLevelTrigger() async {
        let trigger = Product.createTrigger(
            name: "log_bulk_update",
            timing: .after,
            event: .update,
            level: .statement,
            function: .plpgsql(
                "log_statement",
                """
                RAISE NOTICE 'Bulk update performed on products table';
                RETURN NULL;
                """
            )
        )

        await assertSQL(of: trigger) {
            """
            CREATE TRIGGER "log_bulk_update"
            AFTER UPDATE
            ON "products"
            FOR EACH STATEMENT
            EXECUTE FUNCTION "log_statement"()
            """
        }
    }

    // MARK: - DROP Triggers

    @Test("README Example: Drop trigger")
    func dropTrigger() async {
        let function = Trigger<Product>.Function.plpgsql("my_func", "RETURN NEW;")
        let trigger = Product.createTrigger(
            name: "my_trigger",
            timing: .after,
            event: .insert,
            function: function
        )

        let dropStatement = trigger.dropTrigger(ifExists: true)

        assertInlineSnapshot(of: dropStatement, as: .sql) {
            """
            DROP TRIGGER IF EXISTS "my_trigger" ON "products"
            """
        }
    }

    @Test("README Example: Drop function")
    func dropFunction() async {
        let function = Trigger<Product>.Function.plpgsql("my_function", "RETURN NEW;")
        let dropStatement = function.drop(ifExists: true, cascade: true)

        assertInlineSnapshot(of: dropStatement, as: .sql) {
            """
            DROP FUNCTION IF EXISTS "my_function"() CASCADE
            """
        }
    }
}
