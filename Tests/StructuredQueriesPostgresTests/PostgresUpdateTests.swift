import Foundation
import PostgresNIO
import StructuredQueries
import StructuredQueriesPostgres
import Testing

@Suite("PostgreSQL UPDATE Tests")
struct PostgresUpdateTests {

    @Test("Basic UPDATE with toggle")
    func updateBasicToggle() {
        assertPostgresQuery(
            Reminder.update { $0.isCompleted.toggle() },
            sql: #"UPDATE "reminders" SET "isCompleted" = NOT ("reminders"."isCompleted")"#
        )
    }

    @Test("Basic UPDATE with assignment")
    func updateBasicAssignment() {
        assertPostgresQuery(
            Reminder.update { $0.isCompleted = true },
            sql: #"UPDATE "reminders" SET "isCompleted" = $1"#
        )
    }

    @Test("UPDATE with WHERE clause")
    func updateWithWhere() {
        assertPostgresQuery(
            Reminder
                .where { $0.id == 1 }
                .update { $0.isCompleted = true },
            sql: #"UPDATE "reminders" SET "isCompleted" = $1 WHERE ("reminders"."id" = $2)"#
        )
    }

    @Test("UPDATE multiple columns")
    func updateMultipleColumns() {
        assertPostgresQuery(
            Reminder
                .where { $0.id == 1 }
                .update {
                    $0.title = "Updated Task"
                    $0.isCompleted = true
                    $0.updatedAt = Date(timeIntervalSince1970: 0)
                },
            sql: #"UPDATE "reminders" SET "title" = $1, "isCompleted" = $2, "updatedAt" = $3 WHERE ("reminders"."id" = $4)"#
        )
    }

    @Test("UPDATE with column expression")
    func updateWithExpression() {
        assertPostgresQuery(
            Reminder
                .where { $0.priority == Priority.low }
                .update { $0.title += " (Low Priority)" },
            sql: #"UPDATE "reminders" SET "title" = ("reminders"."title" || $1) WHERE ("reminders"."priority" IS $2)"#
        )
    }

    @Test("UPDATE with RETURNING clause")
    func updateReturning() {
        assertPostgresQuery(
            Reminder
                .where { $0.id == 1 }
                .update { $0.isCompleted = true }
                .returning(\.id),
            sql: #"UPDATE "reminders" SET "isCompleted" = $1 WHERE ("reminders"."id" = $2) RETURNING "id""#
        )
    }

    @Test("UPDATE with RETURNING multiple columns")
    func updateReturningMultiple() {
        assertPostgresQuery(
            Reminder
                .where { $0.id == 1 }
                .update { $0.isCompleted = true }
                .returning { ($0.id, $0.title, $0.isCompleted) },
            sql: #"UPDATE "reminders" SET "isCompleted" = $1 WHERE ("reminders"."id" = $2) RETURNING "id", "title", "isCompleted""#
        )
    }

    @Test("UPDATE with toggle and WHERE")
    func updateToggleWithWhere() {
        assertPostgresQuery(
            Reminder
                .where { $0.priority == nil }
                .update { $0.isCompleted.toggle() },
            sql: #"UPDATE "reminders" SET "isCompleted" = NOT ("reminders"."isCompleted") WHERE ("reminders"."priority" IS NULL)"#
        )
    }

    @Test("UPDATE with NULL values")
    func updateWithNull() {
        assertPostgresQuery(
            Reminder
                .where { $0.id == 1 }
                .update {
                    $0.assignedUserID = nil
                    $0.dueDate = nil
                },
            sql: #"UPDATE "reminders" SET "assignedUserID" = NULL, "dueDate" = NULL WHERE ("reminders"."id" = $1)"#
        )
    }

    @Test("UPDATE with complex WHERE conditions")
    func updateComplexWhere() {
        assertPostgresQuery(
            Reminder
                .where { $0.isCompleted == false && ($0.priority == Priority.high || $0.isFlagged) }
                .update { $0.updatedAt = Date(timeIntervalSince1970: 0) },
            sql: #"UPDATE "reminders" SET "updatedAt" = $1 WHERE (("reminders"."isCompleted" = $2) AND (("reminders"."priority" IS $3) OR "reminders"."isFlagged" != 0))"#
        )
    }

    @Test("UPDATE entire row with primary key")
    func updateEntireRow() {
        let reminder = Reminder(
            id: 1,
            assignedUserID: 2,
            dueDate: Date(timeIntervalSince1970: 0),
            isCompleted: true,
            isFlagged: false,
            notes: "Updated notes",
            priority: .high,
            remindersListID: 1,
            title: "Updated title",
            updatedAt: Date(timeIntervalSince1970: 0)
        )

        assertPostgresQuery(
            Reminder.update(reminder),
            sql: #"UPDATE "reminders" SET "assignedUserID" = $1, "dueDate" = $2, "isCompleted" = $3, "isFlagged" = $4, "notes" = $5, "priority" = $6, "remindersListID" = $7, "title" = $8, "updatedAt" = $9 WHERE ("reminders"."id" = $10)"#
        )
    }

    @Test("UPDATE with raw SQL")
    func updateWithRawSQL() {
        assertPostgresQuery(
            Reminder
                .update { $0.dueDate = #sql("CURRENT_TIMESTAMP") }
                .where { $0.id == 1 },
            sql: #"UPDATE "reminders" SET "dueDate" = CURRENT_TIMESTAMP WHERE ("reminders"."id" = $1)"#
        )
    }

    @Test("UPDATE with WHERE using key path")
    func updateWhereKeyPath() {
        assertPostgresQuery(
            Reminder
                .update { $0.isFlagged.toggle() }
                .where(\.isFlagged),
            sql: #"UPDATE "reminders" SET "isFlagged" = NOT ("reminders"."isFlagged") WHERE "reminders"."isFlagged" != 0"#
        )
    }

    @Test("UPDATE with multiple mutations")
    func updateMultipleMutations() {
        assertPostgresQuery(
            Reminder.update {
                $0.title += "!"
                $0.title += "?"
            },
            sql: #"UPDATE "reminders" SET "title" = ("reminders"."title" || $1), "title" = ("reminders"."title" || $2)"#
        )
    }

    @Test("UPDATE with NOT expression")
    func updateWithNot() {
        assertPostgresQuery(
            Reminder.update {
                $0.isCompleted = !$0.isCompleted
            },
            sql: #"UPDATE "reminders" SET "isCompleted" = NOT ("reminders"."isCompleted")"#
        )
    }

    @Test("Empty UPDATE")
    func emptyUpdate() {
        assertPostgresQuery(
            Reminder.update { _ in },
            sql: ""
        )
    }

    @Test("UPDATE none")
    func updateNone() {
        assertPostgresQuery(
            Reminder.none.update { $0.isCompleted.toggle() },
            sql: ""
        )
    }
}
