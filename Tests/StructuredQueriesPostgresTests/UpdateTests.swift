import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests {
  @Suite struct UpdateTests {
    @Test func basics() {
      assertInlineSnapshot(
        of: Reminder
          .update { $0.isCompleted.toggle() }
          .returning { ($0.title, $0.priority, $0.isCompleted) },
        as: .sql
      ) {
        """
        UPDATE "reminders"
        SET "isCompleted" = NOT ("reminders"."isCompleted")
        RETURNING "title", "priority", "isCompleted"
        """
      }

      assertInlineSnapshot(
        of: Reminder
          .where { $0.priority == nil }
          .update { $0.isCompleted = true }
          .returning { ($0.title, $0.priority, $0.isCompleted) },
        as: .sql
      ) {
        """
        UPDATE "reminders"
        SET "isCompleted" = true
        WHERE ("reminders"."priority" IS NULL)
        RETURNING "title", "priority", "isCompleted"
        """
      }
    }

    @Test func returningRepresentable() {
      assertInlineSnapshot(
        of: Reminder
          .update { $0.isCompleted.toggle() }
          .returning(\.dueDate),
        as: .sql
      ) {
        """
        UPDATE "reminders"
        SET "isCompleted" = NOT ("reminders"."isCompleted")
        RETURNING "dueDate"
        """
      }
    }

    @Test func toggleAssignment() {
      assertInlineSnapshot(
        of: Reminder.update {
          $0.isCompleted = !$0.isCompleted
        },
        as: .sql
      ) {
        """
        UPDATE "reminders"
        SET "isCompleted" = NOT ("reminders"."isCompleted")
        """
      }
    }

    @Test func toggleBoolean() {
      assertInlineSnapshot(
        of: Reminder.update { $0.isCompleted.toggle() },
        as: .sql
      ) {
        """
        UPDATE "reminders"
        SET "isCompleted" = NOT ("reminders"."isCompleted")
        """
      }
    }

    @Test func multipleMutations() {
      assertInlineSnapshot(
        of: Reminder.update {
          $0.title += "!"
          $0.title += "?"
        },
        as: .sql
      ) {
        """
        UPDATE "reminders"
        SET "title" = ("reminders"."title" || '!'), "title" = ("reminders"."title" || '?')
        """
      }
    }

    @Test func rawBind() {
      assertInlineSnapshot(
        of: Reminder
          .update { $0.dueDate = #sql("CURRENT_TIMESTAMP") }
          .where { $0.id.eq(1) }
          .returning(\.title),
        as: .sql
      ) {
        """
        UPDATE "reminders"
        SET "dueDate" = CURRENT_TIMESTAMP
        WHERE ("reminders"."id" = 1)
        RETURNING "title"
        """
      }
    }

    @Test func updateWhereKeyPath() {
      assertInlineSnapshot(
        of: Reminder
          .update { $0.isFlagged.toggle() }
          .where(\.isFlagged)
          .returning(\.title),
        as: .sql
      ) {
        """
        UPDATE "reminders"
        SET "isFlagged" = NOT ("reminders"."isFlagged")
        WHERE "reminders"."isFlagged"
        RETURNING "title"
        """
      }
    }

    @Test func aliasName() {
      enum R: AliasName {}
      assertInlineSnapshot(
        of: Reminder.as(R.self)
          .where { $0.id.eq(1) }
          .update { $0.title += " 2" }
          .returning(\.self),
        as: .sql
      ) {
        """
        UPDATE "reminders" AS "rs"
        SET "title" = ("rs"."title" || ' 2')
        WHERE ("rs"."id" = 1)
        RETURNING "id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt"
        """
      }
    }

    @Test func noPrimaryKey() {
      assertInlineSnapshot(
        of: Item.update {
          $0.title = "Dog"
        },
        as: .sql
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

    @Test func complexMutation() {
      assertInlineSnapshot(
        of: Reminder
          .find(1)
          .update {
            $0.dueDate = Case()
              .when($0.dueDate == nil, then: #sql("'2018-01-29 00:08:00.000'"))
          }
          .returning(\.dueDate),
        as: .sql
      ) {
        """
        UPDATE "reminders"
        SET "dueDate" = CASE WHEN ("reminders"."dueDate" IS NULL) THEN '2018-01-29 00:08:00.000' END
        WHERE ("reminders"."id" = 1)
        RETURNING "dueDate"
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
