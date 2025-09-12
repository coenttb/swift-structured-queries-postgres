import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests {
    @Suite struct CommonTableExpressionTests {

        @Test func insert() {
            assertInlineSnapshot(
                of: With {
                    Reminder
                        .where { !$0.isCompleted }
                        .select { IncompleteReminder.Columns(isFlagged: $0.isFlagged, title: $0.title) }
                } query: {
                    Reminder.insert {
                        ($0.remindersListID, $0.title, $0.isFlagged, $0.isCompleted)
                    } select: {
                        IncompleteReminder
                            .join(Reminder.all) { $0.title.eq($1.title) }
                            .select { ($1.remindersListID, $0.title, !$0.isFlagged, true) }
                            .limit(1)
                    }
                    .returning { ($0.id, $0.title) }
                },
                as: .sql
            ) {
                """
                WITH "incompleteReminders" AS (
                  SELECT "reminders"."isFlagged" AS "isFlagged", "reminders"."title" AS "title"
                  FROM "reminders"
                  WHERE NOT ("reminders"."isCompleted")
                )
                INSERT INTO "reminders"
                ("remindersListID", "title", "isFlagged", "isCompleted")
                SELECT "reminders"."remindersListID", "incompleteReminders"."title", NOT ("incompleteReminders"."isFlagged"), true
                FROM "incompleteReminders"
                JOIN "reminders" ON ("incompleteReminders"."title" = "reminders"."title")
                LIMIT 1
                RETURNING "id", "title"
                """
            }
        }

        @Test func delete() {
            assertInlineSnapshot(
                of: With {
                    Reminder
                        .where { !$0.isCompleted }
                        .select { IncompleteReminder.Columns(isFlagged: $0.isFlagged, title: $0.title) }
                } query: {
                    Reminder
                        .where { $0.title.in(IncompleteReminder.select(\.title)) }
                        .delete()
                        .returning(\.title)
                },
                as: .sql
            ) {
        """
        WITH "incompleteReminders" AS (
          SELECT "reminders"."isFlagged" AS "isFlagged", "reminders"."title" AS "title"
          FROM "reminders"
          WHERE NOT ("reminders"."isCompleted")
        )
        DELETE FROM "reminders"
        WHERE ("reminders"."title" IN (SELECT "incompleteReminders"."title"
        FROM "incompleteReminders"))
        RETURNING "reminders"."title"
        """
            }
        }

        @Test func emptyWithClauses() {
            // Test with no rows selected in CTE
            assertInlineSnapshot(
                of: With {
                    Reminder
                        .where { !$0.isCompleted }
                        .select { IncompleteReminder.Columns(isFlagged: $0.isFlagged, title: $0.title) }
                } query: {
                    Reminder
                        .none
                        .delete()
                        .returning(\.title)
                },
                as: .sql
            ) {
        """

        """
            }

            // Test with .none in CTE definition
            assertInlineSnapshot(
                of: With {
                    Reminder
                        .none
                        .where { !$0.isCompleted }
                        .select { IncompleteReminder.Columns(isFlagged: $0.isFlagged, title: $0.title) }
                } query: {
                    Reminder
                        .delete()
                        .returning(\.title)
                },
                as: .sql
            ) {
        """

        """
            }

            // Test with both .none and regular CTE
            assertInlineSnapshot(
                of: With {
                    Reminder
                        .none
                        .where { !$0.isCompleted }
                        .select { IncompleteReminder.Columns(isFlagged: $0.isFlagged, title: $0.title) }
                    Reminder
                        .where { !$0.isCompleted }
                        .select { IncompleteReminder.Columns(isFlagged: $0.isFlagged, title: $0.title) }
                } query: {
                    Reminder
                        .delete()
                        .returning(\.title)
                },
                as: .sql
            ) {
        """
        WITH "incompleteReminders" AS (
          SELECT "reminders"."isFlagged" AS "isFlagged", "reminders"."title" AS "title"
          FROM "reminders"
          WHERE NOT ("reminders"."isCompleted")
        )
        DELETE FROM "reminders"
        RETURNING "reminders"."title"
        """
            }
        }

        @Test func recursive() {
            assertInlineSnapshot(
                of: With {
                    Count(value: 1)
                        .union(Count.select { Count.Columns(value: $0.value + 1) })
                } query: {
                    Count.limit(4)
                },
                as: .sql
            ) {
        """
        WITH "counts" AS (
          SELECT 1 AS "value"
            UNION
          SELECT ("counts"."value" + 1) AS "value"
          FROM "counts"
        )
        SELECT "counts"."value"
        FROM "counts"
        LIMIT 4
        """
            }
        }

        @Test func fibonacci() {
            assertInlineSnapshot(
                of: With {
                    Fibonacci(n: 1, prevFib: 0, fib: 1)
                        .union(
                            Fibonacci
                                .select {
                                    Fibonacci.Columns(n: $0.n + 1, prevFib: $0.fib, fib: $0.prevFib + $0.fib)
                                }
                        )
                } query: {
                    Fibonacci
                        .select(\.fib)
                        .limit(10)
                },
                as: .sql
            ) {
        """
        WITH "fibonaccis" AS (
          SELECT 1 AS "n", 0 AS "prevFib", 1 AS "fib"
            UNION
          SELECT ("fibonaccis"."n" + 1) AS "n", "fibonaccis"."fib" AS "prevFib", ("fibonaccis"."prevFib" + "fibonaccis"."fib") AS "fib"
          FROM "fibonaccis"
        )
        SELECT "fibonaccis"."fib"
        FROM "fibonaccis"
        LIMIT 10
        """
            }
        }

        @Test func goldenRatioApproximation() {
            assertInlineSnapshot(
                of: With {
                    Fibonacci(n: 1, prevFib: 0, fib: 1)
                        .union(
                            Fibonacci
                                .select {
                                    Fibonacci.Columns(n: $0.n + 1, prevFib: $0.fib, fib: $0.prevFib + $0.fib)
                                }
                        )
                } query: {
                    Fibonacci
                        .select { $0.fib.cast(as: Double.self) / $0.prevFib.cast() }
                        .limit(1, offset: 30)
                },
                as: .sql
            ) {
        """
        WITH "fibonaccis" AS (
          SELECT 1 AS "n", 0 AS "prevFib", 1 AS "fib"
            UNION
          SELECT ("fibonaccis"."n" + 1) AS "n", "fibonaccis"."fib" AS "prevFib", ("fibonaccis"."prevFib" + "fibonaccis"."fib") AS "fib"
          FROM "fibonaccis"
        )
        SELECT (CAST("fibonaccis"."fib" AS DOUBLE PRECISION) / CAST("fibonaccis"."prevFib" AS DOUBLE PRECISION))
        FROM "fibonaccis"
        LIMIT 1 OFFSET 30
        """
            }
        }
    }
}

// MARK: - Test Support Types

@Table @Selection
private struct Fibonacci {
    let n: Int
    let prevFib: Int
    let fib: Int
}

@Table @Selection
private struct IncompleteReminder {
    let isFlagged: Bool
    let title: String
}

@Table @Selection
private struct Count {
    let value: Int
}

extension Count {
    init(queryOutput: Int) {
        value = queryOutput
    }
    var queryOutput: Int {
        value
    }
}

@Table
struct Employee {
    let id: Int
    let name: String
    let bossID: Int?
    var height = 100
}

@Table @Selection
struct EmployeeReport {
    let id: Int
    let height: Int
    let name: String
}

@Table @Selection
struct ReminderCount {
    let count: Int
    var queryOutput: Int {
        count
    }
    init(queryOutput: Int) {
        count = queryOutput
    }
}

@Table @Selection
struct RemindersListCount {
    let count: Int
    var queryOutput: Int {
        count
    }
    init(queryOutput: Int) {
        count = queryOutput
    }
}
