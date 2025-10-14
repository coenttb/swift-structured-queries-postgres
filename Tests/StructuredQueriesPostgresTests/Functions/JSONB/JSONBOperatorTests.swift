import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests.JSONB {
    @Suite("Operators") struct OperatorTests {

        // MARK: - Containment Operators Tests

        @Test func containsOperator() async {
            // Test @> operator
            let query = TestUser.all
                .where { user in
                    user.settings.contains(["theme": "dark"])
                }

            await assertSQL(
                of: query
            ) {
                """
                SELECT "test_users"."id", "test_users"."name", "test_users"."settings", "test_users"."metadata", "test_users"."preferences", "test_users"."tags"
                FROM "test_users"
                WHERE ("test_users"."settings" @> '{"theme":"dark"}'::jsonb)
                """
            }
        }

        @Test func containedByOperator() async {
            // Test <@ operator
            let query = TestUser.all
                .where { user in
                    user.settings.isContained(by: [
                        "theme": "dark", "language": "en", "timezone": "UTC",
                    ])
                }

            await assertSQL(
                of: query
            ) {
                """
                SELECT "test_users"."id", "test_users"."name", "test_users"."settings", "test_users"."metadata", "test_users"."preferences", "test_users"."tags"
                FROM "test_users"
                WHERE ("test_users"."settings" <@ '{"language":"en","theme":"dark","timezone":"UTC"}'::jsonb)
                """
            }
        }

        // MARK: - Key Existence Operators Tests

        @Test func hasKeyOperator() async {
            // Test ? operator
            let query = TestUser.all
                .where { user in
                    user.settings.hasKey("notifications")
                }

            await assertSQL(
                of: query
            ) {
                """
                SELECT "test_users"."id", "test_users"."name", "test_users"."settings", "test_users"."metadata", "test_users"."preferences", "test_users"."tags"
                FROM "test_users"
                WHERE ("test_users"."settings" ? 'notifications')
                """
            }
        }

        @Test func hasAnyKeysOperator() async {
            // Test ?| operator
            let query = TestUser.all
                .where { user in
                    user.settings.hasAny(of: ["theme", "color_scheme", "appearance"])
                }

            await assertSQL(
                of: query
            ) {
                """
                SELECT "test_users"."id", "test_users"."name", "test_users"."settings", "test_users"."metadata", "test_users"."preferences", "test_users"."tags"
                FROM "test_users"
                WHERE ("test_users"."settings" ?| ARRAY['theme', 'color_scheme', 'appearance'])
                """
            }
        }

        @Test func hasAllKeysOperator() async {
            // Test ?& operator
            let query = TestUser.all
                .where { user in
                    user.settings.hasAll(of: ["theme", "language"])
                }

            await assertSQL(
                of: query
            ) {
                """
                SELECT "test_users"."id", "test_users"."name", "test_users"."settings", "test_users"."metadata", "test_users"."preferences", "test_users"."tags"
                FROM "test_users"
                WHERE ("test_users"."settings" ?& ARRAY['theme', 'language'])
                """
            }
        }

        // MARK: - Path Extraction Operators Tests

        @Test func jsonFieldOperator() async {
            // Test -> operator
            let query = TestUser.select { user in
                (user.id, user.settings.field("theme"))
            }

            await assertSQL(
                of: query
            ) {
                """
                SELECT "test_users"."id", ("test_users"."settings" -> 'theme')
                FROM "test_users"
                """
            }
        }

        @Test func jsonFieldTextOperator() async {
            // Test ->> operator
            let query = TestUser.select { user in
                (user.id, user.settings.fieldAsText("theme"))
            }

            await assertSQL(
                of: query
            ) {
                """
                SELECT "test_users"."id", ("test_users"."settings" ->> 'theme')
                FROM "test_users"
                """
            }
        }

        @Test func jsonElementOperator() async {
            // Test -> with index
            let query = TestUser.select { user in
                (user.id, user.tags.element(at: 0))
            }

            await assertSQL(
                of: query
            ) {
                """
                SELECT "test_users"."id", ("test_users"."tags" -> 0)
                FROM "test_users"
                """
            }
        }

        @Test func jsonElementTextOperator() async {
            // Test ->> with index
            let query = TestUser.select { user in
                (user.id, user.tags.elementAsText(at: 1))
            }

            await assertSQL(
                of: query
            ) {
                """
                SELECT "test_users"."id", ("test_users"."tags" ->> 1)
                FROM "test_users"
                """
            }
        }

        @Test func jsonPathOperator() async {
            // Test #> operator
            let query = TestUser.select { user in
                (user.id, user.metadata.value(at: ["address", "city"]))
            }

            await assertSQL(
                of: query
            ) {
                """
                SELECT "test_users"."id", ("test_users"."metadata" #> '{address,city}')
                FROM "test_users"
                """
            }
        }

        @Test func jsonPathTextOperator() async {
            // Test #>> operator
            let query = TestUser.select { user in
                (user.id, user.metadata.valueAsText(at: ["contact", "email"]))
            }

            await assertSQL(
                of: query
            ) {
                """
                SELECT "test_users"."id", ("test_users"."metadata" #>> '{contact,email}')
                FROM "test_users"
                """
            }
        }

        // MARK: - Complex Query Tests

        @Test func complexJSONBQuery() async {
            // Test combining multiple JSONB operators
            let query = TestUser.all
                .where { user in
                    user.settings.hasKey("theme") && user.settings.contains(["notifications": true])
                        && user.metadata.fieldAsText("status") == "active"
                }

            await assertSQL(
                of: query
            ) {
                """
                SELECT "test_users"."id", "test_users"."name", "test_users"."settings", "test_users"."metadata", "test_users"."preferences", "test_users"."tags"
                FROM "test_users"
                WHERE ((("test_users"."settings" ? 'theme')) AND ("test_users"."settings" @> '{"notifications":true}'::jsonb)) AND (("test_users"."metadata" ->> 'status')) = ('active')
                """
            }
        }

        @Test func nestedJSONExtraction() async {
            // Test chained JSON operations
            let query = TestUser.select { user in
                user.settings
                    .field("preferences")
                    .field("ui")
                    .fieldAsText("theme")
            }

            await assertSQL(
                of: query
            ) {
                """
                SELECT ((("test_users"."settings" -> 'preferences') -> 'ui') ->> 'theme')
                FROM "test_users"
                """
            }
        }

        // MARK: - Disabled Tests (Type Inference Issues with UPDATE)

        /*
         Expected functionality that should be supported for UPDATE operations:
        
         1. Concatenation (|| operator):
         UPDATE "test_users" SET "settings" = ("test_users"."settings" || '{"newField":"value"}'::jsonb)
        
         2. Delete key (- operator):
         UPDATE "test_users" SET "settings" = ("test_users"."settings" - 'obsolete')
        
         3. Delete multiple keys (- operator with array):
         UPDATE "test_users" SET "settings" = ("test_users"."settings" - ARRAY['field1', 'field2', 'field3'])
        
         4. Delete element by index (- operator):
         UPDATE "test_users" SET "tags" = ("test_users"."tags" - 2)
        
         5. Delete at path (#- operator):
         UPDATE "test_users" SET "metadata" = ("test_users"."metadata" #- '{address,street2}')
         */
    }
}
