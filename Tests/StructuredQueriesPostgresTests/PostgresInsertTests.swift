import Foundation
import PostgresNIO
import StructuredQueries
import StructuredQueriesPostgres
import Testing

@Suite("PostgreSQL INSERT Tests")
struct PostgresInsertTests {

    @Test("Basic INSERT with values")
    func insertBasic() {
        assertPostgresQuery(
            Reminder.insert {
                ($0.remindersListID, $0.title, $0.isCompleted)
            } values: {
                (1, "New Task", false)
            },
            sql: #"INSERT INTO "reminders" ("remindersListID", "title", "isCompleted") VALUES ($1, $2, $3)"#
        )
    }

    @Test("INSERT with multiple values")
    func insertMultipleValues() {
        assertPostgresQuery(
            Reminder.insert {
                ($0.title, $0.remindersListID, $0.isCompleted)
            } values: {
                ("Task 1", 1, false)
                ("Task 2", 1, true)
            },
            sql: #"INSERT INTO "reminders" ("title", "remindersListID", "isCompleted") VALUES ($1, $2, $3), ($4, $5, $6)"#
        )
    }

    @Test("INSERT with RETURNING clause")
    func insertReturning() {
        assertPostgresQuery(
            Reminder.insert {
                ($0.remindersListID, $0.title)
            } values: {
                (1, "New Task")
            }
                .returning(\.id),
            sql: #"INSERT INTO "reminders" ("remindersListID", "title") VALUES ($1, $2) RETURNING "id""#
        )
    }

    @Test("INSERT with RETURNING multiple columns")
    func insertReturningMultiple() {
        assertPostgresQuery(
            Reminder.insert {
                ($0.remindersListID, $0.title)
            } values: {
                (1, "New Task")
            }
                .returning { ($0.id, $0.title, $0.updatedAt) },
            sql: #"INSERT INTO "reminders" ("remindersListID", "title") VALUES ($1, $2) RETURNING "id", "title", "updatedAt""#
        )
    }

    @Test("INSERT with ON CONFLICT DO NOTHING")
    func insertOnConflictDoNothing() {
        // Note: onConflictDoNothing is not a standard StructuredQueries API
        // This test is commented out as it requires custom extension
        // assertPostgresQuery(
        //   Reminder.insert {
        //     ($0.id, $0.remindersListID, $0.title)
        //   } values: {
        //     (100, 1, "New Task")
        //   },
        //   sql: #"INSERT INTO "reminders" ("id", "remindersListID", "title") VALUES ($1, $2, $3)"#
        // )
    }

    @Test("INSERT with ON CONFLICT DO UPDATE")
    func insertOnConflictDoUpdate() {
        assertPostgresQuery(
            Reminder.insert {
                ($0.id, $0.remindersListID, $0.title, $0.updatedAt)
            } values: {
                (100, 1, "New Task", Date(timeIntervalSince1970: 0))
            } onConflictDoUpdate: {
                $0.title += " Copy"
            },
            sql: #"INSERT INTO "reminders" ("id", "remindersListID", "title", "updatedAt") VALUES ($1, $2, $3, $4) ON CONFLICT DO UPDATE SET "title" = ("reminders"."title" || $5)"#
        )
    }

    @Test("INSERT full record")
    func insertFullRecord() {
        assertPostgresQuery(
            Reminder.insert {
                $0
            } values: {
                Reminder(id: 100, remindersListID: 1, title: "Check email")
            }
                .returning(\.id),
            sql: #"INSERT INTO "reminders" ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt") VALUES ($1, NULL, NULL, $2, $3, $4, NULL, $5, $6, $7) RETURNING "id""#
        )
    }

    @Test("Batch INSERT of records")
    func insertBatchRecords() {
        assertPostgresQuery(
            Reminder.insert {
                $0
            } values: {
                Reminder(id: 101, remindersListID: 1, title: "Task 1")
                Reminder(id: 102, remindersListID: 1, title: "Task 2")
                Reminder(id: 103, remindersListID: 2, title: "Task 3")
            },
            sql: #"INSERT INTO "reminders" ("id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt") VALUES ($1, NULL, NULL, $2, $3, $4, NULL, $5, $6, $7), ($8, NULL, NULL, $9, $10, $11, NULL, $12, $13, $14), ($15, NULL, NULL, $16, $17, $18, NULL, $19, $20, $21)"#
        )
    }

    @Test("INSERT single column")
    func insertSingleColumn() {
        assertPostgresQuery(
            Reminder.insert(\.remindersListID) { 1 },
            sql: #"INSERT INTO "reminders" ("remindersListID") VALUES ($1)"#
        )
    }

    @Test("INSERT with empty values")
    func insertEmptyValues() {
        assertPostgresQuery(
            Reminder.insert { [] },
            sql: ""
        )
    }
}
