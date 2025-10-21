import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

extension SnapshotTests {
    @Suite(
        "OperatorsTests"
    )
    struct OperatorsTests {
        @Test func equality() {
            assertInlineSnapshot(of: Row.columns.c == Row.columns.c, as: .sql) {
                """
                ("rows"."c") = ("rows"."c")
                """
            }
            assertInlineSnapshot(of: Row.columns.c == Row.columns.a, as: .sql) {
                """
                ("rows"."c") = ("rows"."a")
                """
            }
            assertInlineSnapshot(of: Row.columns.c == nil, as: .sql) {
                """
                ("rows"."c") IS NOT DISTINCT FROM (NULL)
                """
            }
            assertInlineSnapshot(of: Row.columns.a == Row.columns.c, as: .sql) {
                """
                ("rows"."a") = ("rows"."c")
                """
            }
            assertInlineSnapshot(of: Row.columns.a == Row.columns.a, as: .sql) {
                """
                ("rows"."a") = ("rows"."a")
                """
            }
            // These tests verify that NULL comparisons generate correct PostgreSQL syntax.
            // In PostgreSQL, IS NULL/IS NOT NULL must be used for NULL checks.
            assertInlineSnapshot(of: Row.columns.a == nil, as: .sql) {
                """
                ("rows"."a") IS NOT DISTINCT FROM (NULL)
                """
            }
            assertInlineSnapshot(of: nil == Row.columns.c, as: .sql) {
                """
                ("rows"."c") IS NOT DISTINCT FROM (NULL)
                """
            }
            assertInlineSnapshot(of: nil == Row.columns.a, as: .sql) {
                """
                ("rows"."a") IS NOT DISTINCT FROM (NULL)
                """
            }
            assertInlineSnapshot(of: Row.columns.c != Row.columns.c, as: .sql) {
                """
                ("rows"."c") <> ("rows"."c")
                """
            }
            assertInlineSnapshot(of: Row.columns.c != Row.columns.a, as: .sql) {
                """
                ("rows"."c") <> ("rows"."a")
                """
            }
            assertInlineSnapshot(of: Row.columns.c != nil, as: .sql) {
                """
                ("rows"."c") IS DISTINCT FROM (NULL)
                """
            }
            assertInlineSnapshot(of: Row.columns.a != Row.columns.c, as: .sql) {
                """
                ("rows"."a") <> ("rows"."c")
                """
            }
            assertInlineSnapshot(of: Row.columns.a != Row.columns.a, as: .sql) {
                """
                ("rows"."a") <> ("rows"."a")
                """
            }
            assertInlineSnapshot(of: Row.columns.a != nil, as: .sql) {
                """
                ("rows"."a") IS DISTINCT FROM (NULL)
                """
            }
            assertInlineSnapshot(of: nil != Row.columns.c, as: .sql) {
                """
                ("rows"."c") IS DISTINCT FROM (NULL)
                """
            }
            assertInlineSnapshot(of: nil != Row.columns.a, as: .sql) {
                """
                ("rows"."a") IS DISTINCT FROM (NULL)
                """
            }
        }

        @available(*, deprecated)
        @Test func deprecatedEquality() {
            assertInlineSnapshot(of: Row.columns.c == nil, as: .sql) {
                """
                ("rows"."c") IS NOT DISTINCT FROM (NULL)
                """
            }
            assertInlineSnapshot(of: Row.columns.c != nil, as: .sql) {
                """
                ("rows"."c") IS DISTINCT FROM (NULL)
                """
            }
        }

        @Test func comparison() {
            assertInlineSnapshot(of: Row.columns.c < Row.columns.c, as: .sql) {
                """
                ("rows"."c") < ("rows"."c")
                """
            }
            assertInlineSnapshot(of: Row.columns.c > Row.columns.c, as: .sql) {
                """
                ("rows"."c") > ("rows"."c")
                """
            }
            assertInlineSnapshot(of: Row.columns.c <= Row.columns.c, as: .sql) {
                """
                ("rows"."c") <= ("rows"."c")
                """
            }
            assertInlineSnapshot(of: Row.columns.c >= Row.columns.c, as: .sql) {
                """
                ("rows"."c") >= ("rows"."c")
                """
            }
            assertInlineSnapshot(of: Row.columns.bool < Row.columns.bool, as: .sql) {
                """
                ("rows"."bool") < ("rows"."bool")
                """
            }
        }

        @Test func comparisonWithOptionals() {
            // Optional > Non-optional
            assertInlineSnapshot(of: Row.columns.a > Row.columns.c, as: .sql) {
                """
                ("rows"."a") > ("rows"."c")
                """
            }
            assertInlineSnapshot(of: Row.columns.a < Row.columns.c, as: .sql) {
                """
                ("rows"."a") < ("rows"."c")
                """
            }
            assertInlineSnapshot(of: Row.columns.a >= Row.columns.c, as: .sql) {
                """
                ("rows"."a") >= ("rows"."c")
                """
            }
            assertInlineSnapshot(of: Row.columns.a <= Row.columns.c, as: .sql) {
                """
                ("rows"."a") <= ("rows"."c")
                """
            }

            // With literal values
            assertInlineSnapshot(of: Row.columns.a > 100, as: .sql) {
                """
                ("rows"."a") > (100)
                """
            }
            assertInlineSnapshot(of: Row.columns.b < 50, as: .sql) {
                """
                ("rows"."b") < (50)
                """
            }
            assertInlineSnapshot(of: Row.columns.a >= 0, as: .sql) {
                """
                ("rows"."a") >= (0)
                """
            }
            assertInlineSnapshot(of: Row.columns.b <= 1000, as: .sql) {
                """
                ("rows"."b") <= (1000)
                """
            }
        }

        @Test func logic() async {
            assertInlineSnapshot(of: Row.columns.bool && Row.columns.bool, as: .sql) {
                """
                ("rows"."bool") AND ("rows"."bool")
                """
            }
            assertInlineSnapshot(of: Row.columns.bool || Row.columns.bool, as: .sql) {
                """
                ("rows"."bool") OR ("rows"."bool")
                """
            }
            assertInlineSnapshot(of: !Row.columns.bool, as: .sql) {
                """
                NOT ("rows"."bool")
                """
            }
            await assertSQL(of: Row.update { $0.bool.toggle() }) {
                """
                UPDATE "rows"
                SET "bool" = NOT ("rows"."bool")
                """
            }
        }

        @Test func arithmetic() async {
            assertInlineSnapshot(of: Row.columns.c + Row.columns.c, as: .sql) {
                """
                ("rows"."c") + ("rows"."c")
                """
            }
            assertInlineSnapshot(of: Row.columns.c - Row.columns.c, as: .sql) {
                """
                ("rows"."c") - ("rows"."c")
                """
            }
            assertInlineSnapshot(of: Row.columns.c * Row.columns.c, as: .sql) {
                """
                ("rows"."c") * ("rows"."c")
                """
            }
            assertInlineSnapshot(of: Row.columns.c / Row.columns.c, as: .sql) {
                """
                ("rows"."c") / ("rows"."c")
                """
            }
            assertInlineSnapshot(of: -Row.columns.c, as: .sql) {
                """
                -("rows"."c")
                """
            }
            assertInlineSnapshot(of: +Row.columns.c, as: .sql) {
                """
                +("rows"."c")
                """
            }
            await assertSQL(of: Row.update { $0.c += 1 }) {
                """
                UPDATE "rows"
                SET "c" = ("rows"."c") + (1)
                """
            }
            await assertSQL(of: Row.update { $0.c -= 2 }) {
                """
                UPDATE "rows"
                SET "c" = ("rows"."c") - (2)
                """
            }
            await assertSQL(of: Row.update { $0.c *= 3 }) {
                """
                UPDATE "rows"
                SET "c" = ("rows"."c") * (3)
                """
            }
            await assertSQL(of: Row.update { $0.c /= 4 }) {
                """
                UPDATE "rows"
                SET "c" = ("rows"."c") / (4)
                """
            }
            await assertSQL(of: Row.update { $0.c = -$0.c }) {
                """
                UPDATE "rows"
                SET "c" = -("rows"."c")
                """
            }
            await assertSQL(of: Row.update { $0.c = +$0.c }) {
                """
                UPDATE "rows"
                SET "c" = +("rows"."c")
                """
            }
            await assertSQL(of: Row.update { $0.c.negate() }) {
                """
                UPDATE "rows"
                SET "c" = -("rows"."c")
                """
            }
        }

        @Test func bitwise() async {
            assertInlineSnapshot(of: Row.columns.c % Row.columns.c, as: .sql) {
                """
                ("rows"."c") % ("rows"."c")
                """
            }
            assertInlineSnapshot(of: Row.columns.c & Row.columns.c, as: .sql) {
                """
                ("rows"."c") & ("rows"."c")
                """
            }
            assertInlineSnapshot(of: Row.columns.c | Row.columns.c, as: .sql) {
                """
                ("rows"."c") | ("rows"."c")
                """
            }
            assertInlineSnapshot(of: Row.columns.c << Row.columns.c, as: .sql) {
                """
                ("rows"."c") << ("rows"."c")
                """
            }
            assertInlineSnapshot(of: Row.columns.c >> Row.columns.c, as: .sql) {
                """
                ("rows"."c") >> ("rows"."c")
                """
            }
            assertInlineSnapshot(of: ~Row.columns.c, as: .sql) {
                """
                ~("rows"."c")
                """
            }
            await assertSQL(of: Row.update { $0.c &= 2 }) {
                """
                UPDATE "rows"
                SET "c" = ("rows"."c") & (2)
                """
            }
            await assertSQL(of: Row.update { $0.c |= 3 }) {
                """
                UPDATE "rows"
                SET "c" = ("rows"."c") | (3)
                """
            }
            await assertSQL(of: Row.update { $0.c <<= 4 }) {
                """
                UPDATE "rows"
                SET "c" = ("rows"."c") << (4)
                """
            }
            await assertSQL(of: Row.update { $0.c >>= 5 }) {
                """
                UPDATE "rows"
                SET "c" = ("rows"."c") >> (5)
                """
            }
            await assertSQL(of: Row.update { $0.c = ~$0.c }) {
                """
                UPDATE "rows"
                SET "c" = ~("rows"."c")
                """
            }
        }

        @Test func collectionIn() async throws {
            assertInlineSnapshot(
                of: Row.columns.c.in([1, 2, 3]),
                as: .sql
            ) {
                """
                ("rows"."c") IN (1, 2, 3)
                """
            }
            await assertSQL(
                of: Row.where { $0.c.in(Row.select(\.c)) }
            ) {
                """
                SELECT "rows"."a", "rows"."b", "rows"."c", "rows"."bool", "rows"."string"
                FROM "rows"
                WHERE ("rows"."c") IN (SELECT "rows"."c"
                FROM "rows")
                """
            }
            assertInlineSnapshot(
                of: [1, 2, 3].contains(Row.columns.c),
                as: .sql
            ) {
                """
                ("rows"."c") IN (1, 2, 3)
                """
            }
            await assertSQL(
                of: Row.where { Row.select(\.c).contains($0.c) }
            ) {
                """
                SELECT "rows"."a", "rows"."b", "rows"."c", "rows"."bool", "rows"."string"
                FROM "rows"
                WHERE ("rows"."c") IN (SELECT "rows"."c"
                FROM "rows")
                """
            }
        }

        @Test func containsCollectionElement() async {
            await assertSQL(
                of: Reminder.select { $0.id }.where { [1, 2].contains($0.id) }
            ) {
                """
                SELECT "reminders"."id"
                FROM "reminders"
                WHERE ("reminders"."id") IN (1, 2)
                """
            }
        }

        @Test func moduloZero() async {
            await assertSQL(
                of: Reminder.select { $0.id % 0 }
            ) {
                """
                SELECT ("reminders"."id") % (0)
                FROM "reminders"
                """
            }
        }

        @Test func exists() async {
            await assertSQL(
                of: Values(Reminder.exists())
            ) {
                """
                SELECT EXISTS (
                  SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt"
                  FROM "reminders"
                )
                """
            }

            await assertSQL(
                of: Values(Reminder.where { $0.id == 1 }.exists())
            ) {
                """
                SELECT EXISTS (
                  SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt"
                  FROM "reminders"
                  WHERE ("reminders"."id") = (1)
                )
                """
            }

            await assertSQL(
                of: Values(Reminder.where { $0.id == 100 }.exists())
            ) {
                """
                SELECT EXISTS (
                  SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt"
                  FROM "reminders"
                  WHERE ("reminders"."id") = (100)
                )
                """
            }
        }

        @Table
        struct Row {
            var a: Int?
            var b: Int?
            var c: Int
            var bool: Bool
            var string: String
        }
    }
}
