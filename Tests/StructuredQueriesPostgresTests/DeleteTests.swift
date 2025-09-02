import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests {
    @Suite struct DeleteTests {

        @Test func deleteWhereKeyPath() {
            assertInlineSnapshot(
                of: Reminder
                    .delete()
                    .where(\.isCompleted)
                    .returning(\.title),
                as: .sql
            ) {
                """
                DELETE FROM "reminders"
                WHERE "reminders"."isCompleted"
                RETURNING "reminders"."title"
                """
            }
        }

        @Test func aliasName() {
            enum R: AliasName {}
            assertInlineSnapshot(
                of: RemindersList.as(R.self)
                    .where { $0.id == 1 }
                    .delete()
                    .returning(\.self),
                as: .sql
            ) {
                """
                DELETE FROM "remindersLists" AS "rs"
                WHERE ("rs"."id" = 1)
                RETURNING "id", "color", "title", "position"
                """
            }
        }

        @Test func noPrimaryKey() {
            assertInlineSnapshot(
                of: Item.delete(),
                as: .sql
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
