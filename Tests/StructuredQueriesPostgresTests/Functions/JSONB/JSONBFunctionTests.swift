import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests.JSONB {
    @Suite("Functions") struct FunctionTests {

        // MARK: - Query Function Tests (SELECT)

        @Test func jsonbPrettyFunction() async {
            let query = TestUser.select { user in
                (user.id, user.settings.prettyFormatted())
            }

            await assertSQL(
                of: query
            ) {
                """
                SELECT "test_users"."id", jsonb_pretty("test_users"."settings")
                FROM "test_users"
                """
            }
        }

        @Test func jsonbTypeOfFunction() async {
            let query = TestUser.select { user in
                (user.id, user.metadata.typeString())
            }

            await assertSQL(
                of: query
            ) {
                """
                SELECT "test_users"."id", jsonb_typeof("test_users"."metadata")
                FROM "test_users"
                """
            }
        }

        @Test func jsonbArrayLengthFunction() async {
            let query = TestUser.select { user in
                (user.id, user.tags.arrayLength())
            }

            await assertSQL(
                of: query
            ) {
                """
                SELECT "test_users"."id", jsonb_array_length("test_users"."tags")
                FROM "test_users"
                """
            }
        }

        @Test func jsonbFunctionInWhereClause() async {
            let query = TestUser.all
                .where { user in
                    user.tags.arrayLength() > 5
                }

            await assertSQL(
                of: query
            ) {
                """
                SELECT "test_users"."id", "test_users"."name", "test_users"."settings", "test_users"."metadata", "test_users"."preferences", "test_users"."tags"
                FROM "test_users"
                WHERE (jsonb_array_length("test_users"."tags")) > (5)
                """
            }
        }

        // MARK: - Disabled Tests (Type Inference Issues)
        //
        //         The following tests document the expected SQL output for UPDATE operations with JSONB functions
        //         but are currently disabled due to Swift type inference issues with the update DSL
        //
        //        /*
        //        Expected functionality that should be supported:
        //
        //        1. jsonbSet - Update JSONB at path:
        //           UPDATE "test_users" SET "settings" = jsonb_set("test_users"."settings", '{preferences,theme}', '"dark"'::jsonb, true)
        //
        //        2. jsonbInsert - Insert into JSONB at path:
        //           UPDATE "test_users" SET "tags" = jsonb_insert("test_users"."tags", '{items,0}', '{"name":"swift","version":6}'::jsonb, false)
        //
        //        3. jsonbStripNulls - Remove null values:
        //           UPDATE "test_users" SET "settings" = jsonb_strip_nulls("test_users"."settings")
        //
        //        4. jsonbBuildArray - Create JSONB array:
        //           UPDATE "test_users" SET "tags" = jsonb_build_array('tag1', 'tag2', 'tag3')
        //
        //        5. jsonbObject - Create JSONB object from text array:
        //           UPDATE "test_users" SET "settings" = jsonb_object('{key1,value1,key2,value2,key3,value3}')
        //
        //        6. Chaining JSONB functions:
        //           UPDATE "test_users" SET "settings" = jsonb_strip_nulls(jsonb_set("test_users"."settings", '{new_field}', '"new_value"'::jsonb, true))
        //        */
    }
}
