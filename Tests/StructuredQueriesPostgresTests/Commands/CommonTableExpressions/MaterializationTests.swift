import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests {
    @Suite struct MaterializationTests {

        @Test func materialized() async {
            await assertSQL(
                of: With {
                    Reminder
                        .where { $0.isCompleted }
                        .select {
                            CompletedReminder.Columns(title: $0.title, updatedAt: $0.updatedAt)
                        }
                        .materialized()
                } query: {
                    CompletedReminder.all
                }
            ) {
                """
                WITH "completedReminders" AS MATERIALIZED (
                  SELECT "reminders"."title" AS "title", "reminders"."updatedAt" AS "updatedAt"
                  FROM "reminders"
                  WHERE "reminders"."isCompleted"
                )
                SELECT "completedReminders"."title", "completedReminders"."updatedAt"
                FROM "completedReminders"
                """
            }
        }

        @Test func notMaterialized() async {
            await assertSQL(
                of: With {
                    Reminder
                        .where { $0.id == 1 }
                        .select { SingleReminder.Columns(id: $0.id, title: $0.title) }
                        .notMaterialized()
                } query: {
                    SingleReminder.all
                }
            ) {
                """
                WITH "singleReminders" AS NOT MATERIALIZED (
                  SELECT "reminders"."id" AS "id", "reminders"."title" AS "title"
                  FROM "reminders"
                  WHERE ("reminders"."id") = (1)
                )
                SELECT "singleReminders"."id", "singleReminders"."title"
                FROM "singleReminders"
                """
            }
        }

        @Test func mixedMaterialization() async {
            // Multiple CTEs with different materialization hints
            await assertSQL(
                of: With {
                    Reminder
                        .where { $0.isCompleted }
                        .select {
                            CompletedReminder.Columns(title: $0.title, updatedAt: $0.updatedAt)
                        }
                        .materialized()
                    Reminder
                        .where { !$0.isCompleted }
                        .select { IncompleteReminder.Columns(title: $0.title) }
                        .notMaterialized()
                } query: {
                    CompletedReminder.all
                        .select { ($0.title, "completed") }
                        .union(
                            IncompleteReminder.all
                                .select { ($0.title, "incomplete") }
                        )
                }
            ) {
                """
                WITH "completedReminders" AS MATERIALIZED (
                  SELECT "reminders"."title" AS "title", "reminders"."updatedAt" AS "updatedAt"
                  FROM "reminders"
                  WHERE "reminders"."isCompleted"
                ), "incompleteReminders" AS NOT MATERIALIZED (
                  SELECT "reminders"."title" AS "title"
                  FROM "reminders"
                  WHERE NOT ("reminders"."isCompleted")
                )
                SELECT "completedReminders"."title", 'completed'
                FROM "completedReminders"
                  UNION
                SELECT "incompleteReminders"."title", 'incomplete'
                FROM "incompleteReminders"
                """
            }
        }

        @Test func recursiveAndMaterialized() async {
            // Recursive CTE with materialization hint
            // SQL should have both RECURSIVE and MATERIALIZED
            await assertSQL(
                of: With {
                    Count(value: 1)
                        .union(Count.select { Count.Columns(value: $0.value + 1) })
                        .materialized()
                } query: {
                    Count.where { $0.value <= 100 }
                }
            ) {
                """
                WITH RECURSIVE "counts" AS MATERIALIZED (
                  SELECT 1 AS "value"
                    UNION
                  SELECT ("counts"."value") + (1) AS "value"
                  FROM "counts"
                )
                SELECT "counts"."value"
                FROM "counts"
                WHERE ("counts"."value") <= (100)
                """
            }
        }

        @Test func noMaterializationHint() async {
            // Regular CTE without materialization hint (default behavior)
            await assertSQL(
                of: With {
                    Reminder
                        .where { $0.isCompleted }
                        .select {
                            CompletedReminder.Columns(title: $0.title, updatedAt: $0.updatedAt)
                        }
                } query: {
                    CompletedReminder.all
                }
            ) {
                """
                WITH "completedReminders" AS (
                  SELECT "reminders"."title" AS "title", "reminders"."updatedAt" AS "updatedAt"
                  FROM "reminders"
                  WHERE "reminders"."isCompleted"
                )
                SELECT "completedReminders"."title", "completedReminders"."updatedAt"
                FROM "completedReminders"
                """
            }
        }
    }
}

// MARK: - Test Support Types

@Selection
private struct CompletedReminder {
    let title: String
    let updatedAt: Date
}

@Selection
private struct IncompleteReminder {
    let title: String
}

@Selection
private struct SingleReminder {
    let id: Int
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
