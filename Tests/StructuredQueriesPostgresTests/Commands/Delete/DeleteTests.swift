import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests {
    @Suite struct DeleteTests {

        @Test func deleteWhereKeyPath() async {
            await assertSQL(
                of:
                    Reminder
                    .delete()
                    .where(\.isCompleted)
                    .returning(\.title)
            ) {
                """
                DELETE FROM "reminders"
                WHERE "reminders"."isCompleted"
                RETURNING "reminders"."title"
                """
            }
        }

        @Test func aliasName() async {
            enum R: AliasName {}
            await assertSQL(
                of: RemindersList.as(R.self)
                    .where { $0.id == 1 }
                    .delete()
                    .returning(\.self)
            ) {
                """
                DELETE FROM "remindersLists" AS "rs"
                WHERE ("rs"."id") = (1)
                RETURNING "id", "color", "title", "position"
                """
            }
        }

        @Test func noPrimaryKey() async {
            await assertSQL(
                of: Item.delete()
            ) {
                """
                DELETE FROM "items"
                """
            }
        }

        @Test func empty() {
            assertInlineSnapshot(
                of: Reminder.none.delete(),
                as: .sql
            ) {
                """

                """
            }
        }
    }
}

@Table private struct Item {
    var title = ""
    var quantity = 0
}
