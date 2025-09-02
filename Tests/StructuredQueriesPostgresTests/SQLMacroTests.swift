import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests {
    @Suite struct SQLMacroTests {
        @Test func rawSelect() {
            assertInlineSnapshot(
                of: #sql(
                      """
                      SELECT \(Reminder.columns)
                      FROM \(Reminder.self)
                      ORDER BY \(Reminder.id)
                      LIMIT 1
                      """,
                      as: Reminder.self
                ),
                as: .sql
            ) {
                """
                SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt"
                FROM "reminders"
                ORDER BY "reminders"."id"
                LIMIT 1
                """
            }
        }

        @Test func join() {
            assertInlineSnapshot(
                of: #sql(
                      """
                      SELECT
                        \(Reminder.columns),
                        \(RemindersList.columns)
                      FROM \(Reminder.self)
                      JOIN \(RemindersList.self)
                        ON \(Reminder.remindersListID) = \(RemindersList.id)
                      LIMIT 1
                      """,
                      as: (Reminder, RemindersList).self
                ),
                as: .sql
            ) {
                """
                SELECT
                  "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt",
                  "remindersLists"."id", "remindersLists"."color", "remindersLists"."title", "remindersLists"."position"
                FROM "reminders"
                JOIN "remindersLists"
                  ON "reminders"."remindersListID" = "remindersLists"."id"
                LIMIT 1
                """
            }
        }

        @Test func selection() {
            assertInlineSnapshot(
                of: #sql(
                      """
                      SELECT \(Reminder.columns), \(RemindersList.columns)
                      FROM \(Reminder.self) \
                      JOIN \(RemindersList.self) \
                      ON \(Reminder.remindersListID) = \(RemindersList.id) \
                      LIMIT 1
                      """,
                      as: ReminderWithList.self
                ),
                as: .sql
            ) {
                """
                SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt", "remindersLists"."id", "remindersLists"."color", "remindersLists"."title", "remindersLists"."position"
                FROM "reminders" JOIN "remindersLists" ON "reminders"."remindersListID" = "remindersLists"."id" LIMIT 1
                """
            }
        }

        @Test func customDecoding() {
            struct ReminderResult: QueryRepresentable {
                let title: String
                let isCompleted: Bool

                init(decoder: inout some QueryDecoder) throws {
                    guard let title = try decoder.decode(String.self)
                    else { throw QueryDecodingError.missingRequiredColumn }
                    guard let isCompleted = try decoder.decode(Bool.self)
                    else { throw QueryDecodingError.missingRequiredColumn }
                    self.isCompleted = isCompleted
                    self.title = title
                }
            }

            assertInlineSnapshot(
                of: #sql(#"SELECT "title", "isCompleted" FROM "reminders" LIMIT 4"#, as: ReminderResult.self),
                as: .sql
            ) {
                """
                SELECT "title", "isCompleted" FROM "reminders" LIMIT 4
                """
            }
        }
    }
}

@Selection
private struct ReminderWithList {
    let reminder: Reminder
    let list: RemindersList
}
