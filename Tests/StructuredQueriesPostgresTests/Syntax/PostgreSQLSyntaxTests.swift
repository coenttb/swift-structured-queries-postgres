import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests {
    @Suite struct PostgreSQLSyntaxTests {

        @Test func distinctOnSQL() async {
            // PostgreSQL's DISTINCT ON - NOT available in SQLite or standard SQL
            await assertSQL(
                of: #sql(
                    """
                    SELECT DISTINCT ON ("remindersListID")
                    "id", "title", "updatedAt"
                    FROM "reminders"
                    ORDER BY "remindersListID", "updatedAt" DESC
                    """)
            ) {
                """
                SELECT DISTINCT ON ("remindersListID")
                "id", "title", "updatedAt"
                FROM "reminders"
                ORDER BY "remindersListID", "updatedAt" DESC
                """
            }
        }

        @Test func arrayOperations() async {
            // PostgreSQL array syntax with ANY - PostgreSQL-specific
            await assertSQL(
                of: Reminder.where { reminder in
                    #sql("\(reminder.priority) = ANY(ARRAY[1, 2, 3])")
                }
            ) {
                """
                SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt"
                FROM "reminders"
                WHERE "reminders"."priority" = ANY(ARRAY[1, 2, 3])
                """
            }

            // Array unnest
            await assertSQL(
                of: #sql(
                    """
                    SELECT unnest(ARRAY['a', 'b', 'c']) as element
                    """)
            ) {
                """
                SELECT unnest(ARRAY['a', 'b', 'c']) as element
                """
            }
        }

        @Test func postgresqlSpecificFunctions() async {
            // gen_random_uuid() - PostgreSQL-specific function
            await assertSQL(
                of: #sql(
                    """
                    INSERT INTO "reminders" ("id", "remindersListID", "title")
                    VALUES (gen_random_uuid(), 1, 'Random UUID')
                    """)
            ) {
                """
                INSERT INTO "reminders" ("id", "remindersListID", "title")
                VALUES (gen_random_uuid(), 1, 'Random UUID')
                """
            }

            // INTERVAL arithmetic - PostgreSQL-specific syntax
            await assertSQL(
                of: #sql(
                    """
                    SELECT * FROM "reminders"
                    WHERE "dueDate" > NOW() - INTERVAL '7 days'
                    """)
            ) {
                """
                SELECT * FROM "reminders"
                WHERE "dueDate" > NOW() - INTERVAL '7 days'
                """
            }

        }

        @Test func aggregateFilters() async {
            // FILTER clause on aggregates - PostgreSQL 9.4+ specific
            await assertSQL(
                of: #sql(
                    """
                    SELECT
                        "remindersListID",
                        COUNT(*) as total,
                        COUNT(*) FILTER (WHERE "isCompleted" = true) as completed
                    FROM "reminders"
                    GROUP BY "remindersListID"
                    """)
            ) {
                """
                SELECT
                    "remindersListID",
                    COUNT(*) as total,
                    COUNT(*) FILTER (WHERE "isCompleted" = true) as completed
                FROM "reminders"
                GROUP BY "remindersListID"
                """
            }
        }

        @Test func upsertWithPostgreSQLFunctions() async {
            // Using EXCLUDED table with GREATEST - PostgreSQL-specific
            await assertSQL(
                of: Reminder.insert {
                    Reminder(id: 1, remindersListID: 1, title: "Test")
                } onConflict: { columns in
                    columns.id
                } doUpdate: { row, excluded in
                    row.title = #sql("\(excluded.title) || ' (updated)'")
                    row.updatedAt = #sql("GREATEST(\(row.updatedAt), \(excluded.updatedAt))")
                }
            ) {
                """
                INSERT INTO "reminders"
                ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
                VALUES
                (1, NULL, NULL, false, false, '', NULL, 1, 'Test', '2040-02-14 23:31:30.000')
                ON CONFLICT ("id")
                DO UPDATE SET "title" = "excluded"."title" || ' (updated)', "updatedAt" = GREATEST("reminders"."updatedAt", "excluded"."updatedAt")
                """
            }
        }

        @Test func lateralJoin() async {
            // LATERAL join - PostgreSQL-specific
            await assertSQL(
                of: #sql(
                    """
                    SELECT r.*, latest.*
                    FROM "remindersLists" r
                    LEFT JOIN LATERAL (
                        SELECT * FROM "reminders"
                        WHERE "remindersListID" = r."id"
                        ORDER BY "updatedAt" DESC
                        LIMIT 1
                    ) latest ON true
                    """)
            ) {
                """
                SELECT r.*, latest.*
                FROM "remindersLists" r
                LEFT JOIN LATERAL (
                    SELECT * FROM "reminders"
                    WHERE "remindersListID" = r."id"
                    ORDER BY "updatedAt" DESC
                    LIMIT 1
                ) latest ON true
                """
            }
        }

        @Test func returningWithExpressions() async {
            // RETURNING with PostgreSQL-specific expressions
            await assertSQL(
                of: #sql(
                    """
                    INSERT INTO "reminders" ("remindersListID", "title")
                    VALUES (1, 'Test')
                    RETURNING
                        "id",
                        currval(pg_get_serial_sequence('reminders', 'id')) as current_sequence,
                        to_char("updatedAt", 'YYYY-MM-DD') as formatted_date
                    """)
            ) {
                """
                INSERT INTO "reminders" ("remindersListID", "title")
                VALUES (1, 'Test')
                RETURNING
                    "id",
                    currval(pg_get_serial_sequence('reminders', 'id')) as current_sequence,
                    to_char("updatedAt", 'YYYY-MM-DD') as formatted_date
                """
            }
        }
    }
}
