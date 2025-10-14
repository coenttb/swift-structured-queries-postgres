import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests.Commands.Select {
    @Suite struct SelectionTests {

        @Test func outerJoin() async {
            await assertSQL(
                of:
                    Reminder
                    .limit(2)
                    .leftJoin(User.all) { $0.assignedUserID.eq($1.id) }
                    .select {
                        ReminderTitleAndAssignedUserName.Columns(
                            reminderTitle: $0.title,
                            assignedUserName: $1.name
                        )
                    }
            ) {
                """
                SELECT "reminders"."title" AS "reminderTitle", "users"."name" AS "assignedUserName"
                FROM "reminders"
                LEFT OUTER JOIN "users" ON ("reminders"."assignedUserID") = ("users"."id")
                LIMIT 2
                """
            }
        }

        @Test func date() async {
            await assertSQL(
                of: Reminder.select {
                    ReminderDate.Columns(date: $0.dueDate)
                }
            ) {
                """
                SELECT "reminders"."dueDate" AS "date"
                FROM "reminders"
                """
            }
        }
    }
}

@Selection
struct ReminderDate {
    var date: Date?
}

@Selection
struct ReminderTitleAndAssignedUserName {
    let reminderTitle: String
    let assignedUserName: String?
}

@Selection
struct RemindersListAndReminderCount {
    let remindersList: RemindersList
    let remindersCount: Int
}

@Selection
struct Stats {
    let completedCount: Int
    let flaggedCount: Int
    let totalCount: Int
}
