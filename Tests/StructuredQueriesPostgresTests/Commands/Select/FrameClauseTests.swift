import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests.Commands.Select {
    @Suite struct FrameClauseTests {

        // MARK: - ROWS Frame Type Tests

        /// Test ROWS frame with BETWEEN...AND using UNBOUNDED PRECEDING
        @Test func rowsUnboundedPrecedingToCurrentRow() async {
            await assertSQL(
                of: Reminder.all
                    .select {
                        let listID = $0.remindersListID
                        let id = $0.id
                        return (
                            $0.title,
                            rowNumber().over {
                                $0.partition(by: listID)
                                    .order(by: id)
                                    .rows(
                                        between: FrameBound.unboundedPreceding,
                                        and: FrameBound.currentRow)
                            }
                        )
                    }
            ) {
                """
                SELECT "reminders"."title", ROW_NUMBER() OVER (PARTITION BY "reminders"."remindersListID" ORDER BY "reminders"."id" ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
                FROM "reminders"
                """
            }
        }

        /// Test ROWS frame with BETWEEN...AND using N PRECEDING
        @Test func rowsNPrecedingToCurrentRow() async {
            await assertSQL(
                of: Reminder.all
                    .select {
                        let id = $0.id
                        return (
                            $0.title,
                            rowNumber().over {
                                $0.order(by: id)
                                    .rows(
                                        between: FrameBound.preceding(2), and: FrameBound.currentRow
                                    )
                            }
                        )
                    }
            ) {
                """
                SELECT "reminders"."title", ROW_NUMBER() OVER (ORDER BY "reminders"."id" ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
                FROM "reminders"
                """
            }
        }

        /// Test ROWS frame with CURRENT ROW to N FOLLOWING
        @Test func rowsCurrentRowToNFollowing() async {
            await assertSQL(
                of: Reminder.all
                    .select {
                        let id = $0.id
                        return (
                            $0.title,
                            rank().over {
                                $0.order(by: id)
                                    .rows(
                                        between: FrameBound.currentRow, and: FrameBound.following(3)
                                    )
                            }
                        )
                    }
            ) {
                """
                SELECT "reminders"."title", RANK() OVER (ORDER BY "reminders"."id" ROWS BETWEEN CURRENT ROW AND 3 FOLLOWING)
                FROM "reminders"
                """
            }
        }

        /// Test ROWS frame with CURRENT ROW to UNBOUNDED FOLLOWING
        @Test func rowsCurrentRowToUnboundedFollowing() async {
            await assertSQL(
                of: Reminder.all
                    .select {
                        let id = $0.id
                        return (
                            $0.title,
                            denseRank().over {
                                $0.order(by: id)
                                    .rows(
                                        between: FrameBound.currentRow,
                                        and: FrameBound.unboundedFollowing)
                            }
                        )
                    }
            ) {
                """
                SELECT "reminders"."title", DENSE_RANK() OVER (ORDER BY "reminders"."id" ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
                FROM "reminders"
                """
            }
        }

        /// Test ROWS frame with UNBOUNDED PRECEDING to UNBOUNDED FOLLOWING (entire partition)
        @Test func rowsEntirePartition() async {
            await assertSQL(
                of: Reminder.all
                    .select {
                        let listID = $0.remindersListID
                        let id = $0.id
                        return (
                            $0.title,
                            rowNumber().over {
                                $0.partition(by: listID)
                                    .order(by: id)
                                    .rows(
                                        between: FrameBound.unboundedPreceding,
                                        and: FrameBound.unboundedFollowing)
                            }
                        )
                    }
            ) {
                """
                SELECT "reminders"."title", ROW_NUMBER() OVER (PARTITION BY "reminders"."remindersListID" ORDER BY "reminders"."id" ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
                FROM "reminders"
                """
            }
        }

        /// Test ROWS frame with N PRECEDING to N FOLLOWING (symmetric window)
        @Test func rowsSymmetricWindow() async {
            await assertSQL(
                of: Reminder.all
                    .select {
                        let id = $0.id
                        return (
                            $0.title,
                            rank().over {
                                $0.order(by: id)
                                    .rows(
                                        between: FrameBound.preceding(2),
                                        and: FrameBound.following(2))
                            }
                        )
                    }
            ) {
                """
                SELECT "reminders"."title", RANK() OVER (ORDER BY "reminders"."id" ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING)
                FROM "reminders"
                """
            }
        }

        // MARK: - ROWS Shorthand Syntax Tests

        /// Test ROWS shorthand with N PRECEDING
        @Test func rowsShorthandPreceding() async {
            await assertSQL(
                of: Reminder.all
                    .select {
                        let id = $0.id
                        return (
                            $0.title,
                            rowNumber().over {
                                $0.order(by: id)
                                    .rows(FrameBound.preceding(5))
                            }
                        )
                    }
            ) {
                """
                SELECT "reminders"."title", ROW_NUMBER() OVER (ORDER BY "reminders"."id" ROWS 5 PRECEDING)
                FROM "reminders"
                """
            }
        }

        /// Test ROWS shorthand with UNBOUNDED PRECEDING
        @Test func rowsShorthandUnboundedPreceding() async {
            await assertSQL(
                of: Reminder.all
                    .select {
                        let id = $0.id
                        return (
                            $0.title,
                            rank().over {
                                $0.order(by: id)
                                    .rows(FrameBound.unboundedPreceding)
                            }
                        )
                    }
            ) {
                """
                SELECT "reminders"."title", RANK() OVER (ORDER BY "reminders"."id" ROWS UNBOUNDED PRECEDING)
                FROM "reminders"
                """
            }
        }

        /// Test ROWS shorthand with CURRENT ROW
        @Test func rowsShorthandCurrentRow() async {
            await assertSQL(
                of: Reminder.all
                    .select {
                        let id = $0.id
                        return (
                            $0.title,
                            rowNumber().over {
                                $0.order(by: id)
                                    .rows(FrameBound.currentRow)
                            }
                        )
                    }
            ) {
                """
                SELECT "reminders"."title", ROW_NUMBER() OVER (ORDER BY "reminders"."id" ROWS CURRENT ROW)
                FROM "reminders"
                """
            }
        }

        // MARK: - RANGE Frame Type Tests

        /// Test RANGE frame with BETWEEN...AND
        @Test func rangeUnboundedPrecedingToCurrentRow() async {
            await assertSQL(
                of: Reminder.all
                    .select {
                        let id = $0.id
                        return (
                            $0.title,
                            rank().over {
                                $0.order(by: id)
                                    .range(
                                        between: FrameBound.unboundedPreceding,
                                        and: FrameBound.currentRow)
                            }
                        )
                    }
            ) {
                """
                SELECT "reminders"."title", RANK() OVER (ORDER BY "reminders"."id" RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
                FROM "reminders"
                """
            }
        }

        /// Test RANGE frame with entire partition
        @Test func rangeEntirePartition() async {
            await assertSQL(
                of: Reminder.all
                    .select {
                        let listID = $0.remindersListID
                        let id = $0.id
                        return (
                            $0.title,
                            rowNumber().over {
                                $0.partition(by: listID)
                                    .order(by: id)
                                    .range(
                                        between: FrameBound.unboundedPreceding,
                                        and: FrameBound.unboundedFollowing)
                            }
                        )
                    }
            ) {
                """
                SELECT "reminders"."title", ROW_NUMBER() OVER (PARTITION BY "reminders"."remindersListID" ORDER BY "reminders"."id" RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
                FROM "reminders"
                """
            }
        }

        /// Test RANGE shorthand
        @Test func rangeShorthand() async {
            await assertSQL(
                of: Reminder.all
                    .select {
                        let id = $0.id
                        return (
                            $0.title,
                            rank().over {
                                $0.order(by: id)
                                    .range(FrameBound.unboundedPreceding)
                            }
                        )
                    }
            ) {
                """
                SELECT "reminders"."title", RANK() OVER (ORDER BY "reminders"."id" RANGE UNBOUNDED PRECEDING)
                FROM "reminders"
                """
            }
        }

        // MARK: - GROUPS Frame Type Tests

        /// Test GROUPS frame with BETWEEN...AND
        @Test func groupsUnboundedPrecedingToCurrentRow() async {
            await assertSQL(
                of: Reminder.all
                    .select {
                        let priority = $0.priority
                        return (
                            $0.title,
                            rank().over {
                                $0.order(by: priority)
                                    .groups(
                                        between: FrameBound.unboundedPreceding,
                                        and: FrameBound.currentRow)
                            }
                        )
                    }
            ) {
                """
                SELECT "reminders"."title", RANK() OVER (ORDER BY "reminders"."priority" GROUPS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
                FROM "reminders"
                """
            }
        }

        /// Test GROUPS frame with N PRECEDING
        @Test func groupsNPrecedingToCurrentRow() async {
            await assertSQL(
                of: Reminder.all
                    .select {
                        let priority = $0.priority
                        return (
                            $0.title,
                            denseRank().over {
                                $0.order(by: priority)
                                    .groups(
                                        between: FrameBound.preceding(1), and: FrameBound.currentRow
                                    )
                            }
                        )
                    }
            ) {
                """
                SELECT "reminders"."title", DENSE_RANK() OVER (ORDER BY "reminders"."priority" GROUPS BETWEEN 1 PRECEDING AND CURRENT ROW)
                FROM "reminders"
                """
            }
        }

        /// Test GROUPS shorthand
        @Test func groupsShorthand() async {
            await assertSQL(
                of: Reminder.all
                    .select {
                        let priority = $0.priority
                        return (
                            $0.title,
                            rank().over {
                                $0.order(by: priority)
                                    .groups(FrameBound.preceding(2))
                            }
                        )
                    }
            ) {
                """
                SELECT "reminders"."title", RANK() OVER (ORDER BY "reminders"."priority" GROUPS 2 PRECEDING)
                FROM "reminders"
                """
            }
        }

        // MARK: - Integration with Window Functions

        /// Test lastValue() with proper frame (requires UNBOUNDED FOLLOWING)
        @Test func lastValueWithCorrectFrame() async {
            await assertSQL(
                of: Reminder.all
                    .select {
                        let title = $0.title
                        let listID = $0.remindersListID
                        let id = $0.id
                        return (
                            $0.id,
                            title.lastValue().over {
                                $0.partition(by: listID)
                                    .order(by: id)
                                    .rows(
                                        between: FrameBound.unboundedPreceding,
                                        and: FrameBound.unboundedFollowing)
                            }
                        )
                    }
            ) {
                """
                SELECT "reminders"."id", LAST_VALUE("reminders"."title") OVER (PARTITION BY "reminders"."remindersListID" ORDER BY "reminders"."id" ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
                FROM "reminders"
                """
            }
        }

        /// Test firstValue() with frame
        @Test func firstValueWithFrame() async {
            await assertSQL(
                of: Reminder.all
                    .select {
                        let title = $0.title
                        let listID = $0.remindersListID
                        let id = $0.id
                        return (
                            $0.id,
                            title.firstValue().over {
                                $0.partition(by: listID)
                                    .order(by: id)
                                    .rows(
                                        between: FrameBound.unboundedPreceding,
                                        and: FrameBound.currentRow)
                            }
                        )
                    }
            ) {
                """
                SELECT "reminders"."id", FIRST_VALUE("reminders"."title") OVER (PARTITION BY "reminders"."remindersListID" ORDER BY "reminders"."id" ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
                FROM "reminders"
                """
            }
        }

        /// Test nthValue() with frame
        @Test func nthValueWithFrame() async {
            await assertSQL(
                of: Reminder.all
                    .select {
                        let title = $0.title
                        let listID = $0.remindersListID
                        let id = $0.id
                        return (
                            $0.id,
                            title.nthValue(3).over {
                                $0.partition(by: listID)
                                    .order(by: id)
                                    .rows(
                                        between: FrameBound.unboundedPreceding,
                                        and: FrameBound.unboundedFollowing)
                            }
                        )
                    }
            ) {
                """
                SELECT "reminders"."id", NTH_VALUE("reminders"."title", 3) OVER (PARTITION BY "reminders"."remindersListID" ORDER BY "reminders"."id" ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
                FROM "reminders"
                """
            }
        }

        // MARK: - Frame with Named Windows

        /// Test frame clause with named window
        @Test func frameWithNamedWindow() async {
            await assertSQL(
                of: Reminder.all
                    .window("frame_window") { spec, cols in
                        spec.partition(by: cols.remindersListID)
                            .order(by: cols.id)
                            .rows(
                                between: FrameBound.unboundedPreceding, and: FrameBound.currentRow)
                    }
                    .select { ($0.title, rowNumber().over("frame_window")) }
            ) {
                """
                SELECT "reminders"."title", ROW_NUMBER() OVER frame_window
                FROM "reminders"
                WINDOW frame_window AS (PARTITION BY "reminders"."remindersListID" ORDER BY "reminders"."id" ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
                """
            }
        }

        /// Test frame clause without PARTITION BY
        @Test func frameWithoutPartition() async {
            await assertSQL(
                of: Reminder.all
                    .select {
                        let id = $0.id
                        return (
                            $0.title,
                            rowNumber().over {
                                $0.order(by: id)
                                    .rows(
                                        between: FrameBound.unboundedPreceding,
                                        and: FrameBound.currentRow)
                            }
                        )
                    }
            ) {
                """
                SELECT "reminders"."title", ROW_NUMBER() OVER (ORDER BY "reminders"."id" ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
                FROM "reminders"
                """
            }
        }

        /// Test frame clause without ORDER BY (less common but valid)
        @Test func frameWithoutOrderBy() async {
            await assertSQL(
                of: Reminder.all
                    .select {
                        let listID = $0.remindersListID
                        return (
                            $0.title,
                            rowNumber().over {
                                $0.partition(by: listID)
                                    .rows(
                                        between: FrameBound.unboundedPreceding,
                                        and: FrameBound.unboundedFollowing)
                            }
                        )
                    }
            ) {
                """
                SELECT "reminders"."title", ROW_NUMBER() OVER (PARTITION BY "reminders"."remindersListID" ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
                FROM "reminders"
                """
            }
        }

        // MARK: - Edge Cases

        /// Test CURRENT ROW to CURRENT ROW (single-row frame)
        @Test func singleRowFrame() async {
            await assertSQL(
                of: Reminder.all
                    .select {
                        let id = $0.id
                        return (
                            $0.title,
                            rank().over {
                                $0.order(by: id)
                                    .rows(
                                        between: FrameBound.currentRow, and: FrameBound.currentRow)
                            }
                        )
                    }
            ) {
                """
                SELECT "reminders"."title", RANK() OVER (ORDER BY "reminders"."id" ROWS BETWEEN CURRENT ROW AND CURRENT ROW)
                FROM "reminders"
                """
            }
        }

        /// Test frame with all three window components (partition, order, frame)
        @Test func completeWindowSpecification() async {
            await assertSQL(
                of: Reminder.all
                    .select {
                        let listID = $0.remindersListID
                        let priority = $0.priority
                        return (
                            $0.title,
                            rowNumber().over {
                                $0.partition(by: listID)
                                    .order(by: priority, .desc)
                                    .rows(
                                        between: FrameBound.preceding(3),
                                        and: FrameBound.following(1))
                            }
                        )
                    }
            ) {
                """
                SELECT "reminders"."title", ROW_NUMBER() OVER (PARTITION BY "reminders"."remindersListID" ORDER BY "reminders"."priority" DESC ROWS BETWEEN 3 PRECEDING AND 1 FOLLOWING)
                FROM "reminders"
                """
            }
        }
    }
}
