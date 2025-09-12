import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests {
    @Suite struct SchemaNameTests {
        @Test func select() {
            assertInlineSnapshot(of: Reminder.limit(1), as: .sql) {
                """
                SELECT "main"."reminders"."id", "main"."reminders"."remindersListID"
                FROM "main"."reminders"
                LIMIT 1
                """
            }
        }

        @Test func insert() {
            assertInlineSnapshot(
                of: Reminder.insert { Reminder.Draft(remindersListID: 1) },
                as: .sql
            ) {
                """
                INSERT INTO "main"."reminders"
                ("remindersListID")
                VALUES
                (1)
                """
            }
        }

        @Test func update() {
            assertInlineSnapshot(
                of: Reminder.where { $0.remindersListID.eq(1) }.update { $0.remindersListID = 2 },
                as: .sql
            ) {
                """
                UPDATE "main"."reminders"
                SET "remindersListID" = 2
                WHERE ("main"."reminders"."remindersListID" = 1)
                """
            }
        }

        @Test func delete() {
            assertInlineSnapshot(
                of: Reminder.where { $0.remindersListID.eq(1) }.delete(),
                as: .sql
            ) {
                """
                DELETE FROM "main"."reminders"
                WHERE ("main"."reminders"."remindersListID" = 1)
                """
            }
        }

        @Table("reminders", schema: "main")
        fileprivate struct Reminder {
            let id: Int
            let remindersListID: Int
        }
    }
}
