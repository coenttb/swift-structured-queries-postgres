import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests {
  @Suite struct SQLMacroTests {
    @Test func rawSelect() async {
      await assertSQL(
        of: #sql(
          """
          SELECT \(Reminder.columns)
          FROM \(Reminder.self)
          ORDER BY \(Reminder.id)
          LIMIT 1
          """,
          as: Reminder.self
        )
      ) {
        """
        SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt"
        FROM "reminders"
        ORDER BY "reminders"."id"
        LIMIT 1
        """
      }
    }

    @Test func join() async {
      await assertSQL(
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
        )
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

    @Test func selection() async {
      await assertSQL(
        of: #sql(
          """
          SELECT \(Reminder.columns), \(RemindersList.columns)
          FROM \(Reminder.self) \
          JOIN \(RemindersList.self) \
          ON \(Reminder.remindersListID) = \(RemindersList.id) \
          LIMIT 1
          """,
          as: ReminderWithList.self
        )
      ) {
        """
        SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt", "remindersLists"."id", "remindersLists"."color", "remindersLists"."title", "remindersLists"."position"
        FROM "reminders" JOIN "remindersLists" ON "reminders"."remindersListID" = "remindersLists"."id" LIMIT 1
        """
      }
    }

    @Test func customDecoding() async {
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

      await assertSQL(
        of: #sql(
          #"SELECT "title", "isCompleted" FROM "reminders" LIMIT 4"#,
          as: ReminderResult.self)
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
