import Testing
import StructuredQueries
import StructuredQueriesPostgres
import PostgresNIO
import Foundation

@Suite("PostgreSQL DELETE Tests")
struct PostgresDeleteTests {
    
    @Test("Basic DELETE all rows")
    func deleteAll() {
        assertPostgresQuery(
            Reminder.delete(),
            sql: #"DELETE FROM "reminders""#
        )
    }
    
    @Test("DELETE with WHERE clause")
    func deleteWithWhere() {
        assertPostgresQuery(
            Reminder
                .where { $0.id == 1 }
                .delete(),
            sql: #"DELETE FROM "reminders" WHERE ("reminders"."id" = $1)"#
        )
    }
    
    @Test("DELETE with complex WHERE")
    func deleteComplexWhere() {
        assertPostgresQuery(
            Reminder
                .where { $0.isCompleted && $0.updatedAt < Date(timeIntervalSince1970: 0) }
                .delete(),
            sql: #"DELETE FROM "reminders" WHERE ("reminders"."isCompleted" != 0 AND ("reminders"."updatedAt" < $1))"#
        )
    }
    
    @Test("DELETE with RETURNING clause")
    func deleteReturning() {
        assertPostgresQuery(
            Reminder
                .where { $0.id == 1 }
                .delete()
                .returning(\.id),
            sql: #"DELETE FROM "reminders" WHERE ("reminders"."id" = $1) RETURNING "reminders"."id""#
        )
    }
    
    @Test("DELETE with RETURNING multiple columns")
    func deleteReturningMultiple() {
        assertPostgresQuery(
            Reminder
                .where { $0.isCompleted }
                .delete()
                .returning { ($0.id, $0.title) },
            sql: #"DELETE FROM "reminders" WHERE "reminders"."isCompleted" != 0 RETURNING "reminders"."id", "reminders"."title""#
        )
    }
    
    @Test("DELETE with IN subquery")
    func deleteWithInSubquery() {
        let completedIDs = Reminder
            .where { $0.isCompleted }
            .select(\.id)
        
        assertPostgresQuery(
            ReminderTag
                .where { $0.reminderID.in(completedIDs) }
                .delete(),
            sql: #"DELETE FROM "remindersTags" WHERE ("remindersTags"."reminderID" IN (SELECT "reminders"."id" FROM "reminders" WHERE "reminders"."isCompleted" != 0))"#
        )
    }
    
    @Test("DELETE with primary key")
    func deleteWithPrimaryKey() {
        let reminder = Reminder(
            id: 1,
            remindersListID: 1
        )
        
        assertPostgresQuery(
            Reminder.delete(reminder),
            sql: #"DELETE FROM "reminders" WHERE ("reminders"."id" = $1)"#
        )
    }
    
    @Test("DELETE with WHERE using key path")
    func deleteWhereKeyPath() {
        assertPostgresQuery(
            Reminder
                .delete()
                .where(\.isCompleted),
            sql: #"DELETE FROM "reminders" WHERE "reminders"."isCompleted" != 0"#
        )
    }
    
    @Test("DELETE with LIMIT (through subquery)")
    func deleteWithLimit() {
        let oldestReminders = Reminder
            .order(by: \.updatedAt)
            .limit(10)
            .select(\.id)
        
        assertPostgresQuery(
            Reminder
                .where { $0.id.in(oldestReminders) }
                .delete(),
            sql: #"DELETE FROM "reminders" WHERE ("reminders"."id" IN (SELECT "reminders"."id" FROM "reminders" ORDER BY "reminders"."updatedAt" LIMIT $1))"#
        )
    }
    
    @Test("Cascading DELETE")
    func cascadingDelete() {
        assertPostgresQuery(
            RemindersList
                .where { $0.id == 1 }
                .delete(),
            sql: #"DELETE FROM "remindersLists" WHERE ("remindersLists"."id" = $1)"#
        )
    }
    
    @Test("DELETE with multiple conditions")
    func deleteMultipleConditions() {
        assertPostgresQuery(
            Reminder
                .where { 
                    $0.isCompleted && 
                    $0.priority == nil && 
                    $0.updatedAt < Date(timeIntervalSince1970: 0) 
                }
                .delete(),
            sql: #"DELETE FROM "reminders" WHERE (("reminders"."isCompleted" != 0 AND ("reminders"."priority" IS NULL)) AND ("reminders"."updatedAt" < $1))"#
        )
    }
    
    @Test("DELETE none")
    func deleteNone() {
        assertPostgresQuery(
            Reminder.none.delete(),
            sql: ""
        )
    }
    
    @Test("DELETE with RETURNING full row")
    func deleteReturningFull() {
        assertPostgresQuery(
            Reminder
                .where { $0.id == 1 }
                .delete()
                .returning(\.self),
            sql: #"DELETE FROM "reminders" WHERE ("reminders"."id" = $1) RETURNING "id", "assignedUserID", "dueDate", "isCompleted", "isFlagged", "notes", "priority", "remindersListID", "title", "updatedAt""#
        )
    }
}
