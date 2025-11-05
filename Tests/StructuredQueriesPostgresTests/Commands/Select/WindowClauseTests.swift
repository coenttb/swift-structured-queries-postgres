import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests.Commands.Select {
    @Suite struct WindowClauseTests {
        /// Test a single named window with basic partition and order
        @Test func singleNamedWindow() async {
            await assertSQL(
                of: Reminder.all
                    .window("list_window") {
                        $0.partition(by: $1.remindersListID)
                            .order(by: $1.title.desc())
                    }
                    .select { ($0.title, rank().over("list_window")) }
            ) {
                """
                SELECT "reminders"."title", RANK() OVER list_window
                FROM "reminders"
                WINDOW list_window AS (PARTITION BY "reminders"."remindersListID" ORDER BY "reminders"."title" DESC)
                """
            }
        }

        /// Test multiple named windows in a single query
        @Test func multipleNamedWindows() async {
            await assertSQL(
                of: Reminder.all
                    .window("list_window") {
                        $0.partition(by: $1.remindersListID)
                            .order(by: $1.title.desc())
                    }
                    .window("overall_window") {
                        $0.order(by: $1.title.desc())
                    }
                    .select {
                        (
                            $0.title,
                            $0.remindersListID,
                            rank().over("list_window"),
                            rank().over("overall_window")
                        )
                    }
            ) {
                """
                SELECT "reminders"."title", "reminders"."remindersListID", RANK() OVER list_window, RANK() OVER overall_window
                FROM "reminders"
                WINDOW list_window AS (PARTITION BY "reminders"."remindersListID" ORDER BY "reminders"."title" DESC), overall_window AS (ORDER BY "reminders"."title" DESC)
                """
            }
        }

        /// Test mixing named windows with inline window specifications
        @Test func mixedNamedAndInlineWindows() async {
            await assertSQL(
                of: Reminder.all
                    .window("list_window") {
                        $0.partition(by: $1.remindersListID)
                            .order(by: $1.title.desc())
                    }
                    .select {
                        let id = $0.id
                        return (
                            $0.title,
                            rank().over("list_window"),
                            rowNumber().over { $0.order(by: id) }
                        )
                    }
            ) {
                """
                SELECT "reminders"."title", RANK() OVER list_window, ROW_NUMBER() OVER (ORDER BY "reminders"."id")
                FROM "reminders"
                WINDOW list_window AS (PARTITION BY "reminders"."remindersListID" ORDER BY "reminders"."title" DESC)
                """
            }
        }

        /// Test that queries without named windows don't emit WINDOW clause
        @Test func noWindowClause() async {
            await assertSQL(
                of: Reminder.all
                    .select {
                        let listID = $0.remindersListID
                        let title = $0.title
                        return (
                            $0.title,
                            rank().over {
                                $0.partition(by: listID)
                                    .order(by: title.desc())
                            }
                        )
                    }
            ) {
                """
                SELECT "reminders"."title", RANK() OVER (PARTITION BY "reminders"."remindersListID" ORDER BY "reminders"."title" DESC)
                FROM "reminders"
                """
            }
        }

        /// Test named window with partition only (no ordering)
        @Test func namedWindowPartitionOnly() async {
            await assertSQL(
                of: Reminder.all
                    .window("list_window") {
                        $0.partition(by: $1.remindersListID)
                    }
                    .select { ($0.title, rowNumber().over("list_window")) }
            ) {
                """
                SELECT "reminders"."title", ROW_NUMBER() OVER list_window
                FROM "reminders"
                WINDOW list_window AS (PARTITION BY "reminders"."remindersListID")
                """
            }
        }

        /// Test named window with ordering only (no partition)
        @Test func namedWindowOrderOnly() async {
            await assertSQL(
                of: Reminder.all
                    .window("title_order") {
                        $0.order(by: $1.title.desc())
                    }
                    .select { ($0.title, rowNumber().over("title_order")) }
            ) {
                """
                SELECT "reminders"."title", ROW_NUMBER() OVER title_order
                FROM "reminders"
                WINDOW title_order AS (ORDER BY "reminders"."title" DESC)
                """
            }
        }

        /// Test reusing a named window across multiple functions
        @Test func reuseNamedWindow() async {
            await assertSQL(
                of: Reminder.all
                    .window("list_title") {
                        $0.partition(by: $1.remindersListID)
                            .order(by: $1.title.desc())
                    }
                    .select {
                        (
                            $0.title,
                            $0.remindersListID,
                            rank().over("list_title"),
                            denseRank().over("list_title"),
                            rowNumber().over("list_title")
                        )
                    }
            ) {
                """
                SELECT "reminders"."title", "reminders"."remindersListID", RANK() OVER list_title, DENSE_RANK() OVER list_title, ROW_NUMBER() OVER list_title
                FROM "reminders"
                WINDOW list_title AS (PARTITION BY "reminders"."remindersListID" ORDER BY "reminders"."title" DESC)
                """
            }
        }

        /// Test window clause with WHERE filter
        @Test func windowWithWhere() async {
            await assertSQL(
                of: Reminder.all
                    .where { $0.isCompleted }
                    .window("title_order") {
                        $0.order(by: $1.title.desc())
                    }
                    .select { ($0.title, rank().over("title_order")) }
            ) {
                """
                SELECT "reminders"."title", RANK() OVER title_order
                FROM "reminders"
                WHERE "reminders"."isCompleted"
                WINDOW title_order AS (ORDER BY "reminders"."title" DESC)
                """
            }
        }

        /// Test window clause with ORDER BY at query level
        @Test func windowWithOrderBy() async {
            await assertSQL(
                of: Reminder.all
                    .window("list_window") {
                        $0.partition(by: $1.remindersListID)
                            .order(by: $1.title.desc())
                    }
                    .select { ($0.title, rank().over("list_window")) }
                    .order { $0.title }
            ) {
                """
                SELECT "reminders"."title", RANK() OVER list_window
                FROM "reminders"
                WINDOW list_window AS (PARTITION BY "reminders"."remindersListID" ORDER BY "reminders"."title" DESC)
                ORDER BY "reminders"."title"
                """
            }
        }

        /// Test window clause with LIMIT
        @Test func windowWithLimit() async {
            await assertSQL(
                of: Reminder.all
                    .window("title_order") {
                        $0.order(by: $1.title.desc())
                    }
                    .select { ($0.title, $0.remindersListID, rank().over("title_order")) }
                    .limit(10)
            ) {
                """
                SELECT "reminders"."title", "reminders"."remindersListID", RANK() OVER title_order
                FROM "reminders"
                WINDOW title_order AS (ORDER BY "reminders"."title" DESC)
                LIMIT 10
                """
            }
        }

        /// Test LAG and LEAD with named windows
        @Test func lagLeadWithNamedWindow() async {
            await assertSQL(
                of: Reminder.all
                    .window("list_order") {
                        $0.partition(by: $1.remindersListID)
                            .order(by: $1.id)
                    }
                    .select {
                        (
                            $0.title,
                            $0.id,
                            $0.id.lag().over("list_order"),
                            $0.id.lead().over("list_order")
                        )
                    }
            ) {
                """
                SELECT "reminders"."title", "reminders"."id", LAG("reminders"."id", 1) OVER list_order, LEAD("reminders"."id", 1) OVER list_order
                FROM "reminders"
                WINDOW list_order AS (PARTITION BY "reminders"."remindersListID" ORDER BY "reminders"."id")
                """
            }
        }

        /// Test that WINDOW clause appears before ORDER BY in SQL output (PostgreSQL compliance)
        @Test func clauseOrderingValidation() async {
            await assertSQL(
                of: Reminder.all
                    .window("w") {
                        $0.order(by: $1.title)
                    }
                    .select { ($0.title, rank().over("w")) }
                    .order { $0.id }
            ) {
                """
                SELECT "reminders"."title", RANK() OVER w
                FROM "reminders"
                WINDOW w AS (ORDER BY "reminders"."title")
                ORDER BY "reminders"."id"
                """
            }
        }
    }
}
