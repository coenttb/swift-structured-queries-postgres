import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests {
  @Suite struct UpdateTests {
    @Test func basics() async {
      await assertSQL(
        of:
          Reminder
          .update { $0.isCompleted.toggle() }
          .returning { ($0.title, $0.priority, $0.isCompleted) }
      ) {
        """
        UPDATE "reminders"
        SET "isCompleted" = NOT ("reminders"."isCompleted")
        RETURNING "reminders"."title", "reminders"."priority", "reminders"."isCompleted"
        """
      }

      await assertSQL(
        of:
          Reminder
          .where { $0.priority == nil }
          .update { $0.isCompleted = true }
          .returning { ($0.title, $0.priority, $0.isCompleted) }
      ) {
        """
        UPDATE "reminders"
        SET "isCompleted" = true
        WHERE ("reminders"."priority") IS NOT DISTINCT FROM (NULL)
        RETURNING "reminders"."title", "reminders"."priority", "reminders"."isCompleted"
        """
      }
    }

    @Test func returningRepresentable() async {
      await assertSQL(
        of:
          Reminder
          .update { $0.isCompleted.toggle() }
          .returning(\.dueDate)
      ) {
        """
        UPDATE "reminders"
        SET "isCompleted" = NOT ("reminders"."isCompleted")
        RETURNING "reminders"."dueDate"
        """
      }
    }

    @Test func toggleAssignment() async {
      await assertSQL(
        of: Reminder.update {
          $0.isCompleted = !$0.isCompleted
        }
      ) {
        """
        UPDATE "reminders"
        SET "isCompleted" = NOT ("reminders"."isCompleted")
        """
      }
    }

    @Test func toggleBoolean() async {
      await assertSQL(
        of: Reminder.update { $0.isCompleted.toggle() }
      ) {
        """
        UPDATE "reminders"
        SET "isCompleted" = NOT ("reminders"."isCompleted")
        """
      }
    }

    @Test func multipleMutations() async {
      await assertSQL(
        of: Reminder.update {
          $0.title += "!"
          $0.title += "?"
        }
      ) {
        """
        UPDATE "reminders"
        SET "title" = ("reminders"."title") || ('!'), "title" = ("reminders"."title") || ('?')
        """
      }
    }

    @Test func rawBind() async {
      await assertSQL(
        of:
          Reminder
          .update { $0.dueDate = #sql("CURRENT_TIMESTAMP") }
          .where { $0.id.eq(1) }
          .returning(\.title)
      ) {
        """
        UPDATE "reminders"
        SET "dueDate" = CURRENT_TIMESTAMP
        WHERE ("reminders"."id") = (1)
        RETURNING "reminders"."title"
        """
      }
    }

    @Test func updateWhereKeyPath() async {
      await assertSQL(
        of:
          Reminder
          .update { $0.isFlagged.toggle() }
          .where(\.isFlagged)
          .returning(\.title)
      ) {
        """
        UPDATE "reminders"
        SET "isFlagged" = NOT ("reminders"."isFlagged")
        WHERE "reminders"."isFlagged"
        RETURNING "reminders"."title"
        """
      }
    }

    @Test func aliasName() async {
      enum R: AliasName {}
      await assertSQL(
        of: Reminder.as(R.self)
          .where { $0.id.eq(1) }
          .update { $0.title += " 2" }
          .returning(\.self)
      ) {
        """
        UPDATE "reminders" AS "rs"
        SET "title" = ("rs"."title") || (' 2')
        WHERE ("rs"."id") = (1)
        RETURNING "rs"."id", "rs"."assignedUserID", "rs"."dueDate", "rs"."isCompleted", "rs"."isFlagged", "rs"."notes", "rs"."priority", "rs"."remindersListID", "rs"."title", "rs"."updatedAt"
        """
      }
    }

    @Test func noPrimaryKey() async {
      await assertSQL(
        of: Item.update {
          $0.title = "Dog"
        }
      ) {
        """
        UPDATE "items"
        SET "title" = 'Dog'
        """
      }
    }

    @Test func emptyUpdate() {
      assertInlineSnapshot(
        of: Item.update { _ in },
        as: .sql
      ) {
        """

        """
      }
    }

    @Test func complexMutation() async {
      await assertSQL(
        of:
          Reminder
          .find(1)
          .update {
            $0.dueDate = Case()
              .when($0.dueDate == nil, then: #sql("'2018-01-29 00:08:00.000'"))
          }
          .returning(\.dueDate)
      ) {
        """
        UPDATE "reminders"
        SET "dueDate" = CASE WHEN ("reminders"."dueDate") IS NOT DISTINCT FROM (NULL) THEN '2018-01-29 00:08:00.000' END
        WHERE ("reminders"."id") IN (1)
        RETURNING "reminders"."dueDate"
        """
      }
    }

    @Test func empty() {
      assertInlineSnapshot(
        of: Reminder.none.update { $0.isCompleted.toggle() },
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
