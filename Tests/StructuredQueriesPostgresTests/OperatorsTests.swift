import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing



extension SnapshotTests {
    @Suite(
        "OperatorsTests",
        .snapshots(record: .never)
    )
    struct OperatorsTests {
        @Test func equality() {
            assertInlineSnapshot(of: Row.columns.c == Row.columns.c, as: .sql) {
                """
                ("rows"."c" = "rows"."c")
                """
            }
            assertInlineSnapshot(of: Row.columns.c == Row.columns.a, as: .sql) {
                """
                ("rows"."c" = "rows"."a")
                """
            }
            assertInlineSnapshot(of: Row.columns.c == nil, as: .sql) {
                """
                ("rows"."c" IS NULL)
                """
            }
            assertInlineSnapshot(of: Row.columns.a == Row.columns.c, as: .sql) {
                """
                ("rows"."a" = "rows"."c")
                """
            }
            assertInlineSnapshot(of: Row.columns.a == Row.columns.a, as: .sql) {
                """
                ("rows"."a" = "rows"."a")
                """
            }
            // These tests verify that NULL comparisons generate correct PostgreSQL syntax.
            // In PostgreSQL, IS NULL/IS NOT NULL must be used for NULL checks.
            assertInlineSnapshot(of: Row.columns.a == nil, as: .sql) {
                """
                ("rows"."a" IS NULL)
                """
            }
            assertInlineSnapshot(of: nil == Row.columns.c, as: .sql) {
                """
                ("rows"."c" IS NULL)
                """
            }
            assertInlineSnapshot(of: nil == Row.columns.a, as: .sql) {
                """
                ("rows"."a" IS NULL)
                """
            }
            assertInlineSnapshot(of: Row.columns.c != Row.columns.c, as: .sql) {
                """
                ("rows"."c" <> "rows"."c")
                """
            }
            assertInlineSnapshot(of: Row.columns.c != Row.columns.a, as: .sql) {
                """
                ("rows"."c" <> "rows"."a")
                """
            }
            assertInlineSnapshot(of: Row.columns.c != nil, as: .sql) {
                """
                ("rows"."c" IS NOT NULL)
                """
            }
            assertInlineSnapshot(of: Row.columns.a != Row.columns.c, as: .sql) {
                """
                ("rows"."a" <> "rows"."c")
                """
            }
            assertInlineSnapshot(of: Row.columns.a != Row.columns.a, as: .sql) {
                """
                ("rows"."a" <> "rows"."a")
                """
            }
            assertInlineSnapshot(of: Row.columns.a != nil, as: .sql) {
                """
                ("rows"."a" IS NOT NULL)
                """
            }
            assertInlineSnapshot(of: nil != Row.columns.c, as: .sql) {
                """
                ("rows"."c" IS NOT NULL)
                """
            }
            assertInlineSnapshot(of: nil != Row.columns.a, as: .sql) {
                """
                ("rows"."a" IS NOT NULL)
                """
            }
        }
        
        @available(*, deprecated)
        @Test func deprecatedEquality() {
            assertInlineSnapshot(of: Row.columns.c == nil, as: .sql) {
                """
                ("rows"."c" IS NULL)
                """
            }
            assertInlineSnapshot(of: Row.columns.c != nil, as: .sql) {
                """
                ("rows"."c" IS NOT NULL)
                """
            }
        }
        
        @Test func comparison() {
            assertInlineSnapshot(of: Row.columns.c < Row.columns.c, as: .sql) {
                """
                ("rows"."c" < "rows"."c")
                """
            }
            assertInlineSnapshot(of: Row.columns.c > Row.columns.c, as: .sql) {
                """
                ("rows"."c" > "rows"."c")
                """
            }
            assertInlineSnapshot(of: Row.columns.c <= Row.columns.c, as: .sql) {
                """
                ("rows"."c" <= "rows"."c")
                """
            }
            assertInlineSnapshot(of: Row.columns.c >= Row.columns.c, as: .sql) {
                """
                ("rows"."c" >= "rows"."c")
                """
            }
            assertInlineSnapshot(of: Row.columns.bool < Row.columns.bool, as: .sql) {
                """
                ("rows"."bool" < "rows"."bool")
                """
            }
        }
        
        @Test func logic() {
            assertInlineSnapshot(of: Row.columns.bool && Row.columns.bool, as: .sql) {
                """
                ("rows"."bool" AND "rows"."bool")
                """
            }
            assertInlineSnapshot(of: Row.columns.bool || Row.columns.bool, as: .sql) {
                """
                ("rows"."bool" OR "rows"."bool")
                """
            }
            assertInlineSnapshot(of: !Row.columns.bool, as: .sql) {
                """
                NOT ("rows"."bool")
                """
            }
            assertInlineSnapshot(of: Row.update { $0.bool.toggle() }, as: .sql) {
                """
                UPDATE "rows"
                SET "bool" = NOT ("rows"."bool")
                """
            }
        }
        
        @Test func arithmetic() {
            assertInlineSnapshot(of: Row.columns.c + Row.columns.c, as: .sql) {
                """
                ("rows"."c" + "rows"."c")
                """
            }
            assertInlineSnapshot(of: Row.columns.c - Row.columns.c, as: .sql) {
                """
                ("rows"."c" - "rows"."c")
                """
            }
            assertInlineSnapshot(of: Row.columns.c * Row.columns.c, as: .sql) {
                """
                ("rows"."c" * "rows"."c")
                """
            }
            assertInlineSnapshot(of: Row.columns.c / Row.columns.c, as: .sql) {
                """
                ("rows"."c" / "rows"."c")
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
            assertInlineSnapshot(of: Row.update { $0.c += 1 }, as: .sql) {
                """
                UPDATE "rows"
                SET "c" = ("rows"."c" + 1)
                """
            }
            assertInlineSnapshot(of: Row.update { $0.c -= 2 }, as: .sql) {
                """
                UPDATE "rows"
                SET "c" = ("rows"."c" - 2)
                """
            }
            assertInlineSnapshot(of: Row.update { $0.c *= 3 }, as: .sql) {
                """
                UPDATE "rows"
                SET "c" = ("rows"."c" * 3)
                """
            }
            assertInlineSnapshot(of: Row.update { $0.c /= 4 }, as: .sql) {
                """
                UPDATE "rows"
                SET "c" = ("rows"."c" / 4)
                """
            }
            assertInlineSnapshot(of: Row.update { $0.c = -$0.c }, as: .sql) {
                """
                UPDATE "rows"
                SET "c" = -("rows"."c")
                """
            }
            assertInlineSnapshot(of: Row.update { $0.c = +$0.c }, as: .sql) {
                """
                UPDATE "rows"
                SET "c" = +("rows"."c")
                """
            }
            assertInlineSnapshot(of: Row.update { $0.c.negate() }, as: .sql) {
                """
                UPDATE "rows"
                SET "c" = -("rows"."c")
                """
            }
        }
        
        @Test func bitwise() {
            assertInlineSnapshot(of: Row.columns.c % Row.columns.c, as: .sql) {
                """
                ("rows"."c" % "rows"."c")
                """
            }
            assertInlineSnapshot(of: Row.columns.c & Row.columns.c, as: .sql) {
                """
                ("rows"."c" & "rows"."c")
                """
            }
            assertInlineSnapshot(of: Row.columns.c | Row.columns.c, as: .sql) {
                """
                ("rows"."c" | "rows"."c")
                """
            }
            assertInlineSnapshot(of: Row.columns.c << Row.columns.c, as: .sql) {
                """
                ("rows"."c" << "rows"."c")
                """
            }
            assertInlineSnapshot(of: Row.columns.c >> Row.columns.c, as: .sql) {
                """
                ("rows"."c" >> "rows"."c")
                """
            }
            assertInlineSnapshot(of: ~Row.columns.c, as: .sql) {
                """
                ~("rows"."c")
                """
            }
            assertInlineSnapshot(of: Row.update { $0.c &= 2 }, as: .sql) {
                """
                UPDATE "rows"
                SET "c" = ("rows"."c" & 2)
                """
            }
            assertInlineSnapshot(of: Row.update { $0.c |= 3 }, as: .sql) {
                """
                UPDATE "rows"
                SET "c" = ("rows"."c" | 3)
                """
            }
            assertInlineSnapshot(of: Row.update { $0.c <<= 4 }, as: .sql) {
                """
                UPDATE "rows"
                SET "c" = ("rows"."c" << 4)
                """
            }
            assertInlineSnapshot(of: Row.update { $0.c >>= 5 }, as: .sql) {
                """
                UPDATE "rows"
                SET "c" = ("rows"."c" >> 5)
                """
            }
            assertInlineSnapshot(of: Row.update { $0.c = ~$0.c }, as: .sql) {
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
                ("rows"."c" IN (1, 2, 3))
                """
            }
            assertInlineSnapshot(
                of: Row.columns.c.in(Row.select(\.c)),
                as: .sql
            ) {
                """
                ("rows"."c" IN (SELECT "rows"."c"
                FROM "rows"))
                """
            }
            assertInlineSnapshot(
                of: [1, 2, 3].contains(Row.columns.c),
                as: .sql
            ) {
                """
                ("rows"."c" IN (1, 2, 3))
                """
            }
            assertInlineSnapshot(
                of: Row.select(\.c).contains(Row.columns.c),
                as: .sql
            ) {
                """
                ("rows"."c" IN (SELECT "rows"."c"
                FROM "rows"))
                """
            }
        }
        
        
        
        @Test func containsCollectionElement() {
            assertInlineSnapshot(
                of: Reminder.select { $0.id }.where { [1, 2].contains($0.id) },
                as: .sql
            ) {
                """
                SELECT "reminders"."id"
                FROM "reminders"
                WHERE ("reminders"."id" IN (1, 2))
                """
            }
        }
        
        @Test func moduloZero() {
            assertInlineSnapshot(
                of: Reminder.select { $0.id % 0 },
                as: .sql
            ) {
                """
                SELECT ("reminders"."id" % 0)
                FROM "reminders"
                """
            }
        }
        
        @Test func exists() {
            assertInlineSnapshot(
                of: Values(Reminder.exists()),
                as: .sql
            ) {
                """
                SELECT EXISTS (
                  SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt"
                  FROM "reminders"
                )
                """
            }
            
            assertInlineSnapshot(
                of: Values(Reminder.where { $0.id == 1 }.exists()),
                as: .sql
            ) {
                """
                SELECT EXISTS (
                  SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt"
                  FROM "reminders"
                  WHERE ("reminders"."id" = 1)
                )
                """
            }
            
            assertInlineSnapshot(
                of: Values(Reminder.where { $0.id == 100 }.exists()),
                as: .sql
            ) {
                """
                SELECT EXISTS (
                  SELECT "reminders"."id", "reminders"."assignedUserID", "reminders"."dueDate", "reminders"."isCompleted", "reminders"."isFlagged", "reminders"."notes", "reminders"."priority", "reminders"."remindersListID", "reminders"."title", "reminders"."updatedAt"
                  FROM "reminders"
                  WHERE ("reminders"."id" = 100)
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
