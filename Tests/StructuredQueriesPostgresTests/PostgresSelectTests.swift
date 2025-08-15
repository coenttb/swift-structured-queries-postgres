import Foundation
import PostgresNIO
import StructuredQueries
import StructuredQueriesPostgres
import Testing

@Suite("PostgreSQL SELECT Tests")
struct PostgresSelectTests {

    @Test("Basic SELECT all columns")
    func selectAll() {
        assertPostgresQuery(
            Tag.all,
            sql: #"SELECT "tags"."id", "tags"."title" FROM "tags""#
        )
    }

    @Test("SELECT with DISTINCT")
    func selectDistinct() {
        assertPostgresQuery(
            Reminder.distinct().select(\.priority),
            sql: #"SELECT DISTINCT "reminders"."priority" FROM "reminders""#
        )
    }

    @Test("SELECT specific columns")
    func selectColumns() {
        assertPostgresQuery(
            Reminder.select { ($0.id, $0.title) },
            sql: #"SELECT "reminders"."id", "reminders"."title" FROM "reminders""#
        )
    }

    @Test("SELECT with WHERE clause")
    func selectWithWhere() {
        assertPostgresQuery(
            Reminder.where { $0.isCompleted },
            sql: #"SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt" FROM "reminders" WHERE "reminders"."isCompleted" != 0"#
        )
    }

    @Test("SELECT with complex WHERE")
    func selectWithComplexWhere() {
        assertPostgresQuery(
            Reminder.where { $0.isCompleted && $0.priority == Priority.high },
            sql: #"SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt" FROM "reminders" WHERE ("reminders"."isCompleted" != 0 AND ("reminders"."priority" IS $1))"#
        )
    }

    @Test("SELECT with ORDER BY")
    func selectWithOrderBy() {
        assertPostgresQuery(
            Reminder.all.order(by: \.title),
            sql: #"SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt" FROM "reminders" ORDER BY "reminders"."title""#
        )
    }

    @Test("SELECT with ORDER BY DESC")
    func selectWithOrderByDesc() {
        assertPostgresQuery(
            Reminder.all.order { $0.title.desc() },
            sql: #"SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt" FROM "reminders" ORDER BY "reminders"."title" DESC"#
        )
    }

    @Test("SELECT with LIMIT")
    func selectWithLimit() {
        assertPostgresQuery(
            Reminder.all.limit(5),
            sql: #"SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt" FROM "reminders" LIMIT $1"#
        )
    }

    @Test("SELECT with LIMIT and OFFSET")
    func selectWithLimitOffset() {
        assertPostgresQuery(
            Reminder.all.limit(5, offset: 10),
            sql: #"SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt" FROM "reminders" LIMIT $1 OFFSET $2"#
        )
    }

    @Test("SELECT with GROUP BY")
    func selectWithGroupBy() {
        assertPostgresQuery(
            Reminder.group(by: \.remindersListID).select { $0.remindersListID },
            sql: #"SELECT "reminders"."remindersListID" FROM "reminders" GROUP BY "reminders"."remindersListID""#
        )
    }

    @Test("SELECT with aggregate functions")
    func selectWithAggregates() {
        assertPostgresQuery(
            Reminder.select { $0.id.count() },
            sql: #"SELECT count("reminders"."id") FROM "reminders""#
        )

        assertPostgresQuery(
            Reminder.select { $0.priority.max() },
            sql: #"SELECT max("reminders"."priority") FROM "reminders""#
        )
    }

    @Test("SELECT with HAVING clause")
    func selectWithHaving() {
        assertPostgresQuery(
            Reminder
                .group(by: \.remindersListID)
                .having { $0.id.count() > 2 }
                .select { ($0.remindersListID, $0.id.count()) },
            sql: #"SELECT "reminders"."remindersListID", count("reminders"."id") FROM "reminders" GROUP BY "reminders"."remindersListID" HAVING (count("reminders"."id") > $1)"#
        )
    }

    @Test("SELECT with subquery")
    func selectWithSubquery() {
        let maxPriority = Reminder.select { $0.priority.max() }
        assertPostgresQuery(
            Reminder.where { $0.priority == maxPriority },
            sql: #"SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt" FROM "reminders" WHERE ("reminders"."priority" IS (  SELECT max("reminders"."priority")  FROM "reminders" ))"#
        )
    }

    @Test("SELECT with NULL checks")
    func selectWithNullChecks() {
        assertPostgresQuery(
            Reminder.where { $0.assignedUserID == nil },
            sql: #"SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt" FROM "reminders" WHERE ("reminders"."assignedUserID" IS NULL)"#
        )

        assertPostgresQuery(
            Reminder.where { $0.assignedUserID != nil },
            sql: #"SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt" FROM "reminders" WHERE ("reminders"."assignedUserID" IS NOT NULL)"#
        )
    }

    @Test("SELECT with IN clause")
    func selectWithIn() {
        let priorities: [Priority?] = [.low, .high]
        assertPostgresQuery(
            Reminder.where { $0.priority.in(priorities) },
            sql: #"SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt" FROM "reminders" WHERE ("reminders"."priority" IN ($1, $2))"#
        )
    }

    @Test("SELECT with BETWEEN")
    func selectWithBetween() {
        assertPostgresQuery(
            Reminder.where { $0.id.between(1, and: 10) },
            sql: #"SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt" FROM "reminders" WHERE ("reminders"."id" BETWEEN $1 AND $2)"#
        )
    }

    @Test("SELECT with LIKE pattern")
    func selectWithLike() {
        assertPostgresQuery(
            Reminder.where { $0.title.like("%groceries%") },
            sql: #"SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt" FROM "reminders" WHERE ("reminders"."title" LIKE $1)"#
        )
    }
}
