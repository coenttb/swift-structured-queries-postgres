import Testing
import StructuredQueries
import StructuredQueriesPostgres
import PostgresNIO
import Foundation

@Suite("PostgreSQL JOIN Tests")
struct PostgresJoinTests {
    
    @Test("Basic INNER JOIN")
    func innerJoin() {
        assertPostgresQuery(
            Reminder
                .join(RemindersList.all) { $0.remindersListID.eq($1.id) }
                .select { ($0.title, $1.title) },
            sql: #"SELECT "reminders"."title", "remindersLists"."title" FROM "reminders" JOIN "remindersLists" ON ("reminders"."remindersListID" = "remindersLists"."id")"#
        )
    }
    
    @Test("LEFT JOIN with optional handling")
    func leftJoin() {
        assertPostgresQuery(
            Reminder
                .leftJoin(User.all) { $0.assignedUserID.eq($1.id) }
                .select { JoinedRow.Columns(reminderTitle: $0.title, userName: $1.name) },
            sql: #"SELECT "reminders"."title" AS "reminderTitle", "users"."name" AS "userName" FROM "reminders" LEFT JOIN "users" ON ("reminders"."assignedUserID" = "users"."id")"#
        )
    }
    
    @Test("Multiple JOINs")
    func multipleJoins() {
        assertPostgresQuery(
            Reminder
                .join(RemindersList.all) { $0.remindersListID.eq($1.id) }
                .leftJoin(User.all) { $0.assignedUserID.eq($2.id) }
                .select { MultiJoinRow.Columns(reminderTitle: $0.title, listTitle: $1.title, userName: $2.name) },
            sql: #"SELECT "reminders"."title" AS "reminderTitle", "remindersLists"."title" AS "listTitle", "users"."name" AS "userName" FROM "reminders" JOIN "remindersLists" ON ("reminders"."remindersListID" = "remindersLists"."id") LEFT JOIN "users" ON ("reminders"."assignedUserID" = "users"."id")"#
        )
    }
    
    @Test("JOIN with WHERE clause")
    func joinWithWhere() {
        assertPostgresQuery(
            Reminder
                .join(RemindersList.all) { $0.remindersListID.eq($1.id) }
                .where { !$0.isCompleted && $1.title == "Work" }
                .select { reminder, _ in reminder.title },
            sql: #"SELECT "reminders"."title" FROM "reminders" JOIN "remindersLists" ON ("reminders"."remindersListID" = "remindersLists"."id") WHERE (NOT ("reminders"."isCompleted" != 0) AND ("remindersLists"."title" = $1))"#
        )
    }
    
    @Test("JOIN with complex conditions")
    func joinComplexConditions() {
        assertPostgresQuery(
            Reminder
                .join(RemindersList.all) { $0.remindersListID.eq($1.id) && $1.position > 0 }
                .select { reminder, _ in reminder.title },
            sql: #"SELECT "reminders"."title" FROM "reminders" JOIN "remindersLists" ON (("reminders"."remindersListID" = "remindersLists"."id") AND ("remindersLists"."position" > $1))"#
        )
    }
    
    @Test("JOIN with aggregates")
    func joinWithAggregates() {
        assertPostgresQuery(
            RemindersList
                .group(by: \.id)
                .leftJoin(Reminder.all) { $0.id.eq($1.remindersListID) }
                .select { AggregateRow.Columns(title: $0.title, count: $1.id.count()) },
            sql: #"SELECT "remindersLists"."title" AS "title", count("reminders"."id") AS "count" FROM "remindersLists" LEFT JOIN "reminders" ON ("remindersLists"."id" = "reminders"."remindersListID") GROUP BY "remindersLists"."id""#
        )
    }
    
    @Test("JOIN with ORDER BY")
    func joinWithOrderBy() {
        assertPostgresQuery(
            Reminder
                .join(RemindersList.all) { $0.remindersListID.eq($1.id) }
                .order(by: { _, list in list.position })
                .order(by: { reminder, _ in reminder.title })
                .select { reminder, _ in reminder.title },
            sql: #"SELECT "reminders"."title" FROM "reminders" JOIN "remindersLists" ON ("reminders"."remindersListID" = "remindersLists"."id") ORDER BY "remindersLists"."position", "reminders"."title""#
        )
    }
    
    @Test("Many-to-many JOIN through junction table")
    func manyToManyJoin() {
        assertPostgresQuery(
            Reminder
                .join(ReminderTag.all) { $0.id.eq($1.reminderID) }
                .join(Tag.all) { $1.tagID.eq($2.id) }
                .select { ($0.title, $2.title) },
            sql: #"SELECT "reminders"."title", "tags"."title" FROM "reminders" JOIN "remindersTags" ON ("reminders"."id" = "remindersTags"."reminderID") JOIN "tags" ON ("remindersTags"."tagID" = "tags"."id")"#
        )
    }
    
    @Test("JOIN with LIMIT")
    func joinWithLimit() {
        assertPostgresQuery(
            Reminder
                .join(RemindersList.all) { $0.remindersListID.eq($1.id) }
                .limit(5)
                .select { ($0.title, $1.title) },
            sql: #"SELECT "reminders"."title", "remindersLists"."title" FROM "reminders" JOIN "remindersLists" ON ("reminders"."remindersListID" = "remindersLists"."id") LIMIT $1"#
        )
    }
    
    @Test("RIGHT JOIN with optional handling")
    func rightJoin() {
        assertPostgresQuery(
            Reminder
                .rightJoin(RemindersList.all) { $0.remindersListID.eq($1.id) }
                .select { RightJoinRow.Columns(reminderTitle: $0.title, listTitle: $1.title) },
            sql: #"SELECT "reminders"."title" AS "reminderTitle", "remindersLists"."title" AS "listTitle" FROM "reminders" RIGHT JOIN "remindersLists" ON ("reminders"."remindersListID" = "remindersLists"."id")"#
        )
    }
    
    @Test("FULL OUTER JOIN with optional handling")
    func fullOuterJoin() {
        assertPostgresQuery(
            Reminder
                .fullJoin(User.all) { $0.assignedUserID.eq($1.id) }
                .select { FullJoinRow.Columns(reminderTitle: $0.title, userName: $1.name) },
            sql: #"SELECT "reminders"."title" AS "reminderTitle", "users"."name" AS "userName" FROM "reminders" FULL JOIN "users" ON ("reminders"."assignedUserID" = "users"."id")"#
        )
    }
    
    @Test("JOIN with HAVING clause")
    func joinWithHaving() {
        assertPostgresQuery(
            RemindersList
                .group(by: \.id)
                .leftJoin(Reminder.all) { $0.id.eq($1.remindersListID) }
                .having { $1.id.count() > 2 }
                .select { HavingRow.Columns(title: $0.title, count: $1.id.count()) },
            sql: #"SELECT "remindersLists"."title" AS "title", count("reminders"."id") AS "count" FROM "remindersLists" LEFT JOIN "reminders" ON ("remindersLists"."id" = "reminders"."remindersListID") GROUP BY "remindersLists"."id" HAVING (count("reminders"."id") > $1)"#
        )
    }
    
    @Test("JOIN with DISTINCT")
    func joinWithDistinct() {
        assertPostgresQuery(
            Reminder
                .join(RemindersList.all) { $0.remindersListID.eq($1.id) }
                .distinct()
                .select { $1.title },
            sql: #"SELECT DISTINCT "remindersLists"."title" FROM "reminders" JOIN "remindersLists" ON ("reminders"."remindersListID" = "remindersLists"."id")"#
        )
    }
}

// Helper types for selections with optional values
@Selection
private struct JoinedRow {
    let reminderTitle: String
    let userName: String?
}

@Selection
private struct MultiJoinRow {
    let reminderTitle: String
    let listTitle: String
    let userName: String?
}

@Selection
private struct AggregateRow {
    let title: String
    let count: Int
}

@Selection
private struct RightJoinRow {
    let reminderTitle: String?
    let listTitle: String
}

@Selection
private struct FullJoinRow {
    let reminderTitle: String?
    let userName: String?
}

@Selection
private struct HavingRow {
    let title: String
    let count: Int
}
