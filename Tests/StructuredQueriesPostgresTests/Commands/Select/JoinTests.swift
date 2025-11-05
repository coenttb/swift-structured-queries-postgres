import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests.Commands.Select {
    @Suite struct JoinTests {
        @Test func basics() async {
            await assertSQL(
                of:
                    Reminder
                    .order { $0.dueDate.desc() }
                    .join(RemindersList.all) { $0.remindersListID.eq($1.id) }
                    .select { ($0.title, $1.title) }
            ) {
                """
                SELECT "reminders"."title", "remindersLists"."title"
                FROM "reminders"
                JOIN "remindersLists" ON ("reminders"."remindersListID") = ("remindersLists"."id")
                ORDER BY "reminders"."dueDate" DESC
                """
            }
        }

        @Test func outerJoinOptional() async {
            await assertSQL(
                of:
                    RemindersList
                    .leftJoin(Reminder.all) { $0.id.eq($1.remindersListID) }
                    .select {
                        PriorityRow.Columns(value: $1.priority)
                    }
            ) {
                """
                SELECT "reminders"."priority" AS "value"
                FROM "remindersLists"
                LEFT OUTER JOIN "reminders" ON ("remindersLists"."id") = ("reminders"."remindersListID")
                """
            }
        }
    }
}

@Selection
private struct PriorityRow {
    let value: Priority?
}
