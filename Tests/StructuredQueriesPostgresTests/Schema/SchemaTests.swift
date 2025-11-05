import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests {
    @Suite struct SchemaNameTests {
        @Test func select() async {
            await assertSQL(of: Reminder.limit(1)) {
                """
                SELECT "main"."reminders"."id", "main"."reminders"."remindersListID"
                FROM "main"."reminders"
                LIMIT 1
                """
            }
        }

        @Test func insert() async {
            await assertSQL(of: Reminder.insert { Reminder.Draft(remindersListID: 1) }) {
                """
                INSERT INTO "main"."reminders"
                ("id", "remindersListID")
                VALUES
                (DEFAULT, 1)
                """
            }
        }

        @Test func update() async {
            await assertSQL(
                of: Reminder.where { $0.remindersListID.eq(1) }.update { $0.remindersListID = 2 }
            ) {
                """
                UPDATE "main"."reminders"
                SET "remindersListID" = 2
                WHERE ("main"."reminders"."remindersListID") = (1)
                """
            }
        }

        @Test func delete() async {
            await assertSQL(of: Reminder.where { $0.remindersListID.eq(1) }.delete()) {
                """
                DELETE FROM "main"."reminders"
                WHERE ("main"."reminders"."remindersListID") = (1)
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
