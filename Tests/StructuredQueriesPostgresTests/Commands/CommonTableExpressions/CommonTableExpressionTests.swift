import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests {
  @Suite struct CommonTableExpressionTests {

    @Test func insert() async {
      await assertSQL(
        of: With {
          Reminder
            .where { !$0.isCompleted }
            .select {
              IncompleteReminder.Columns(isFlagged: $0.isFlagged, title: $0.title)
            }
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
        }
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
        JOIN "reminders" ON ("incompleteReminders"."title") = ("reminders"."title")
        LIMIT 1
        RETURNING "id", "title"
        """
      }
    }

    @Test func delete() async {
      await assertSQL(
        of: With {
          Reminder
            .where { !$0.isCompleted }
            .select {
              IncompleteReminder.Columns(isFlagged: $0.isFlagged, title: $0.title)
            }
        } query: {
          Reminder
            .where { $0.title.in(IncompleteReminder.select(\.title)) }
            .delete()
            .returning(\.title)
        }
      ) {
        """
        WITH "incompleteReminders" AS (
          SELECT "reminders"."isFlagged" AS "isFlagged", "reminders"."title" AS "title"
          FROM "reminders"
          WHERE NOT ("reminders"."isCompleted")
        )
        DELETE FROM "reminders"
        WHERE ("reminders"."title") IN (SELECT "incompleteReminders"."title"
        FROM "incompleteReminders")
        RETURNING "reminders"."title"
        """
      }
    }

    @Test func emptyWithClauses() async {
      // Test with no rows selected in CTE
      assertInlineSnapshot(
        of: With {
          Reminder
            .where { !$0.isCompleted }
            .select {
              IncompleteReminder.Columns(isFlagged: $0.isFlagged, title: $0.title)
            }
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
            .select {
              IncompleteReminder.Columns(isFlagged: $0.isFlagged, title: $0.title)
            }
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
      await assertSQL(
        of: With {
          Reminder
            .none
            .where { !$0.isCompleted }
            .select {
              IncompleteReminder.Columns(isFlagged: $0.isFlagged, title: $0.title)
            }
          Reminder
            .where { !$0.isCompleted }
            .select {
              IncompleteReminder.Columns(isFlagged: $0.isFlagged, title: $0.title)
            }
        } query: {
          Reminder
            .delete()
            .returning(\.title)
        }
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

    @Test func recursive() async {
      await assertSQL(
        of: With {
          Count(value: 1)
            .union(Count.select { Count.Columns(value: $0.value + 1) })
        } query: {
          Count.limit(4)
        }
      ) {
        """
        WITH RECURSIVE "counts" AS (
          SELECT 1 AS "value"
            UNION
          SELECT ("counts"."value") + (1) AS "value"
          FROM "counts"
        )
        SELECT "counts"."value"
        FROM "counts"
        LIMIT 4
        """
      }
    }

    @Test func fibonacci() async {
      await assertSQL(
        of: With {
          Fibonacci(n: 1, prevFib: 0, fib: 1)
            .union(
              Fibonacci
                .select {
                  Fibonacci.Columns(
                    n: $0.n + 1, prevFib: $0.fib, fib: $0.prevFib + $0.fib)
                }
            )
        } query: {
          Fibonacci
            .select(\.fib)
            .limit(10)
        }
      ) {
        """
        WITH RECURSIVE "fibonaccis" AS (
          SELECT 1 AS "n", 0 AS "prevFib", 1 AS "fib"
            UNION
          SELECT ("fibonaccis"."n") + (1) AS "n", "fibonaccis"."fib" AS "prevFib", ("fibonaccis"."prevFib") + ("fibonaccis"."fib") AS "fib"
          FROM "fibonaccis"
        )
        SELECT "fibonaccis"."fib"
        FROM "fibonaccis"
        LIMIT 10
        """
      }
    }

    @Test func goldenRatioApproximation() async {
      await assertSQL(
        of: With {
          Fibonacci(n: 1, prevFib: 0, fib: 1)
            .union(
              Fibonacci
                .select {
                  Fibonacci.Columns(
                    n: $0.n + 1, prevFib: $0.fib, fib: $0.prevFib + $0.fib)
                }
            )
        } query: {
          Fibonacci
            .select { $0.fib.cast(as: Double.self) / $0.prevFib.cast() }
            .limit(1, offset: 30)
        }
      ) {
        """
        WITH RECURSIVE "fibonaccis" AS (
          SELECT 1 AS "n", 0 AS "prevFib", 1 AS "fib"
            UNION
          SELECT ("fibonaccis"."n") + (1) AS "n", "fibonaccis"."fib" AS "prevFib", ("fibonaccis"."prevFib") + ("fibonaccis"."fib") AS "fib"
          FROM "fibonaccis"
        )
        SELECT (CAST("fibonaccis"."fib" AS DOUBLE PRECISION)) / (CAST("fibonaccis"."prevFib" AS DOUBLE PRECISION))
        FROM "fibonaccis"
        LIMIT 1 OFFSET 30
        """
      }
    }

    @Test func explicitRecursiveOverride() async {
      // Test explicit recursive: true parameter
      // Even without UNION + self-reference, RECURSIVE keyword should be emitted
      await assertSQL(
        of: With(recursive: true) {
          Reminder
            .where { !$0.isCompleted }
            .select {
              IncompleteReminder.Columns(isFlagged: $0.isFlagged, title: $0.title)
            }
        } query: {
          IncompleteReminder.all
        }
      ) {
        """
        WITH RECURSIVE "incompleteReminders" AS (
          SELECT "reminders"."isFlagged" AS "isFlagged", "reminders"."title" AS "title"
          FROM "reminders"
          WHERE NOT ("reminders"."isCompleted")
        )
        SELECT "incompleteReminders"."isFlagged", "incompleteReminders"."title"
        FROM "incompleteReminders"
        """
      }
    }

    @Test func nonRecursiveUnion() async {
      // UNION between different tables should NOT generate RECURSIVE keyword
      // (no self-reference)
      await assertSQL(
        of: With {
          Reminder.select { Name.Columns(type: "reminder", value: $0.title) }
            .union(RemindersList.select { Name.Columns(type: "list", value: $0.title) })
        } query: {
          Name.order { ($0.type.desc(), $0.value.asc()) }
        }
      ) {
        """
        WITH "names" AS (
          SELECT 'reminder' AS "type", "reminders"."title" AS "value"
          FROM "reminders"
            UNION
          SELECT 'list' AS "type", "remindersLists"."title" AS "value"
          FROM "remindersLists"
        )
        SELECT "names"."type", "names"."value"
        FROM "names"
        ORDER BY "names"."type" DESC, "names"."value" ASC
        """
      }
    }
  }
}

// MARK: - Test Support Types

@Selection
private struct Fibonacci {
  let n: Int
  let prevFib: Int
  let fib: Int
}

@Selection
private struct IncompleteReminder {
  let isFlagged: Bool
  let title: String
}

@Selection
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

@Selection
private struct Name {
  let type: String
  let value: String
}

@Table
struct Employee {
  let id: Int
  let name: String
  let bossID: Int?
  var height = 100
}

@Selection
struct EmployeeReport {
  let id: Int
  let height: Int
  let name: String
}

@Selection
struct ReminderCount {
  let count: Int
  var queryOutput: Int {
    count
  }
  init(queryOutput: Int) {
    count = queryOutput
  }
}

@Selection
struct RemindersListCount {
  let count: Int
  var queryOutput: Int {
    count
  }
  init(queryOutput: Int) {
    count = queryOutput
  }
}
