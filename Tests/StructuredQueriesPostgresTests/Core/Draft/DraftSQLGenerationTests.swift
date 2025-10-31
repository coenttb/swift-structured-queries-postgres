import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests {
  @Suite struct DraftSQLGenerationTests {

    @Test func draftWithExplicitId() {
      // When Draft has explicit ID, it should be included
      assertInlineSnapshot(
        of: Reminder.insert {
          Reminder.Draft(
            id: 42,
            remindersListID: 1,
            title: "With explicit ID"
          )
        },
        as: .sql
      ) {
        """
        INSERT INTO "reminders"
        ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
        VALUES
        (42, NULL, NULL, false, false, '', NULL, 1, 'With explicit ID', '2040-02-14 23:31:30.000')
        """
      }
    }

    @Test func draftWithOnConflict() {
      // Draft with ON CONFLICT includes id with DEFAULT (conservative approach for PostgreSQL)
      assertInlineSnapshot(
        of: Reminder.insert {
          Reminder.Draft(
            remindersListID: 1,
            title: "Upsert draft"
          )
        } onConflict: { columns in
          (columns.remindersListID, columns.title)
        } doUpdate: { row, excluded in
          row.updatedAt = excluded.updatedAt
        },
        as: .sql
      ) {
        """
        INSERT INTO "reminders"
        ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
        VALUES
        (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Upsert draft', '2040-02-14 23:31:30.000')
        ON CONFLICT ("remindersListID", "title")
        DO UPDATE SET "updatedAt" = "excluded"."updatedAt"
        """
      }
    }

    @Test func mixedDraftsWithAndWithoutIds() {
      // When mixing Drafts, use DEFAULT for NULL ids
      assertInlineSnapshot(
        of: Reminder.insert {
          Reminder.Draft(
            id: 100,
            remindersListID: 1,
            title: "Has ID"
          )
          Reminder.Draft(
            remindersListID: 1,
            title: "No ID - should use DEFAULT"
          )
          Reminder.Draft(
            id: 101,
            remindersListID: 1,
            title: "Also has ID"
          )
        },
        as: .sql
      ) {
        """
        INSERT INTO "reminders"
        ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
        VALUES
        (100, NULL, NULL, false, false, '', NULL, 1, 'Has ID', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'No ID - should use DEFAULT', '2040-02-14 23:31:30.000'), (101, NULL, NULL, false, false, '', NULL, 1, 'Also has ID', '2040-02-14 23:31:30.000')
        """
      }
    }

    @Test func draftUpsertSQL() {
      // Test the upsert method on Draft
      assertInlineSnapshot(
        of: Reminder.upsert {
          Reminder.Draft(
            remindersListID: 1,
            title: "Upsert without ID"
          )
        },
        as: .sql
      ) {
        """
        INSERT INTO "reminders"
        ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
        VALUES
        (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Upsert without ID', '2040-02-14 23:31:30.000')
        ON CONFLICT ("id")
        DO UPDATE SET "assignedUserID" = "excluded"."assignedUserID", "dueDate" = "excluded"."dueDate", "isCompleted" = "excluded"."isCompleted", "isFlagged" = "excluded"."isFlagged", "notes" = "excluded"."notes", "priority" = "excluded"."priority", "remindersListID" = "excluded"."remindersListID", "title" = "excluded"."title", "updatedAt" = "excluded"."updatedAt"
        """
      }
    }

    @Test func draftBatchInsertAllWithoutIds() {
      // Multiple drafts without IDs should exclude id column entirely
      assertInlineSnapshot(
        of: Reminder.insert {
          for i in 1...3 {
            Reminder.Draft(
              remindersListID: 1,
              title: "Task \(i)"
            )
          }
        },
        as: .sql
      ) {
        """
        INSERT INTO "reminders"
        ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
        VALUES
        (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Task 1', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Task 2', '2040-02-14 23:31:30.000'), (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Task 3', '2040-02-14 23:31:30.000')
        """
      }
    }

    @Test func draftWithComplexConflictResolution() {
      // Test ON CONFLICT with WHERE clause
      assertInlineSnapshot(
        of: Reminder.insert {
          Reminder.Draft(
            isCompleted: false,
            remindersListID: 1,
            title: "Complex conflict"
          )
        } onConflict: { columns in
          (columns.remindersListID, columns.title)
        } where: { columns in
          columns.isCompleted.eq(false)
        } doUpdate: { row, excluded in
          row.updatedAt = excluded.updatedAt
          row.notes = excluded.notes
        } where: { columns in
          columns.updatedAt.lt(Date(timeIntervalSinceReferenceDate: 1_234_567_890))
        },
        as: .sql
      ) {
        """
        INSERT INTO "reminders"
        ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt")
        VALUES
        (DEFAULT, NULL, NULL, false, false, '', NULL, 1, 'Complex conflict', '2040-02-14 23:31:30.000')
        ON CONFLICT ("remindersListID", "title")
        WHERE ("reminders"."isCompleted") = (false)
        DO UPDATE SET "updatedAt" = "excluded"."updatedAt", "notes" = "excluded"."notes"
        WHERE ("reminders"."updatedAt") < ('2040-02-14 23:31:30.000')
        """
      }
    }
  }
}
