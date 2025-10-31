import Dependencies
import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests {
  @Suite struct ViewsTests {
    @Test func basics() async {
      let query = CompletedReminder.createTemporaryView(
        as:
          Reminder
          .where(\.isCompleted)
          .select { CompletedReminder.Columns(reminderID: $0.id, title: $0.title) }
      )
      assertInlineSnapshot(of: query, as: .sql) {
        """
        CREATE TEMP VIEW
        "completedReminders"
        ("reminderID", "title")
        AS
        SELECT "reminders"."id" AS "reminderID", "reminders"."title" AS "title"
        FROM "reminders"
        WHERE "reminders"."isCompleted"
        """
      }
      await assertSQL(of: CompletedReminder.limit(2)) {
        """
        SELECT "completedReminders"."reminderID", "completedReminders"."title"
        FROM "completedReminders"
        LIMIT 2
        """
      }
      assertInlineSnapshot(of: query.drop(), as: .sql) {
        """
        DROP VIEW "completedReminders"
        """
      }
    }

    @Test func orReplace() async {
      let query = CompletedReminder.createTemporaryView(
        orReplace: true,
        as:
          Reminder
          .where(\.isCompleted)
          .select { CompletedReminder.Columns(reminderID: $0.id, title: $0.title) }
      )
      await assertSQL(of: query) {
        """
        CREATE OR REPLACE TEMP VIEW
        "completedReminders"
        ("reminderID", "title")
        AS
        SELECT "reminders"."id" AS "reminderID", "reminders"."title" AS "title"
        FROM "reminders"
        WHERE "reminders"."isCompleted"
        """
      }
    }

    @Test func dropIfExists() {
      let query = CompletedReminder.createTemporaryView(
        as:
          Reminder
          .where(\.isCompleted)
          .select { CompletedReminder.Columns(reminderID: $0.id, title: $0.title) }
      )
      assertInlineSnapshot(of: query.drop(ifExists: true), as: .sql) {
        """
        DROP VIEW IF EXISTS "completedReminders"
        """
      }
    }

    @Test func ctes() async {
      await assertSQL(
        of: CompletedReminder.createTemporaryView(
          as: With {
            Reminder
              .where(\.isCompleted)
              .select {
                CompletedReminder.Columns(reminderID: $0.id, title: $0.title)
              }
          } query: {
            CompletedReminder.all
          }
        )
      ) {
        """
        CREATE TEMP VIEW
        "completedReminders"
        ("reminderID", "title")
        AS
        WITH "completedReminders" AS (
          SELECT "reminders"."id" AS "reminderID", "reminders"."title" AS "title"
          FROM "reminders"
          WHERE "reminders"."isCompleted"
        )
        SELECT "completedReminders"."reminderID", "completedReminders"."title"
        FROM "completedReminders"
        """
      }
    }

    @Test func reminderWithList() async {
      assertInlineSnapshot(
        of: ReminderWithList.createTemporaryView(
          as:
            Reminder
            .join(RemindersList.all) { $0.remindersListID.eq($1.id) }
            .select {
              ReminderWithList.Columns(
                reminderID: $0.id,
                reminderTitle: $0.title,
                remindersListTitle: $1.title
              )
            }
        ),
        as: .sql
      ) {
        """
        CREATE TEMP VIEW
        "reminderWithLists"
        ("reminderID", "reminderTitle", "remindersListTitle")
        AS
        SELECT "reminders"."id" AS "reminderID", "reminders"."title" AS "reminderTitle", "remindersLists"."title" AS "remindersListTitle"
        FROM "reminders"
        JOIN "remindersLists" ON ("reminders"."remindersListID") = ("remindersLists"."id")
        """
      }

      await assertSQL(of: ReminderWithList.find(1)) {
        """
        SELECT "reminderWithLists"."reminderID", "reminderWithLists"."reminderTitle", "reminderWithLists"."remindersListTitle"
        FROM "reminderWithLists"
        WHERE ("reminderWithLists"."reminderID") IN (1)
        """
      }

      await assertSQL(
        of:
          ReminderWithList
          .order(by: { ($0.remindersListTitle, $0.reminderTitle) })
          .limit(3)
      ) {
        """
        SELECT "reminderWithLists"."reminderID", "reminderWithLists"."reminderTitle", "reminderWithLists"."remindersListTitle"
        FROM "reminderWithLists"
        ORDER BY "reminderWithLists"."remindersListTitle", "reminderWithLists"."reminderTitle"
        LIMIT 3
        """
      }
    }
  }
}

@Table
private struct CompletedReminder {
  let reminderID: Reminder.ID
  let title: String
}

@Table
private struct ReminderWithList {
  @Column(primaryKey: true)
  let reminderID: Reminder.ID
  let reminderTitle: String
  let remindersListTitle: String
}
