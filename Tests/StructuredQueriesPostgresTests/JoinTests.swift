import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests {
    @Suite struct JoinTests {
        @Test func basics() {
            assertInlineSnapshot(
                of: Reminder
                    .order { $0.dueDate.desc() }
                    .join(RemindersList.all) { $0.remindersListID.eq($1.id) }
                    .select { ($0.title, $1.title) },
                as: .sql
            ) {
                """
                SELECT "reminders"."title", "remindersLists"."title"
                FROM "reminders"
                JOIN "remindersLists" ON ("reminders"."remindersListID" = "remindersLists"."id")
                ORDER BY "reminders"."dueDate" DESC
                """
            }
        }
        
        @Test func outerJoinOptional() {
            assertInlineSnapshot(
                of: RemindersList
                    .leftJoin(Reminder.all) { $0.id.eq($1.remindersListID) }
                    .select {
                        PriorityRow.Columns(value: $1.priority)
                    },
                as: .sql
            ) {
                """
                SELECT "reminders"."priority" AS "value"
                FROM "remindersLists"
                LEFT JOIN "reminders" ON ("remindersLists"."id" = "reminders"."remindersListID")
                """
            }
        }
    }
}

@Selection
private struct PriorityRow {
    let value: Priority?
}
