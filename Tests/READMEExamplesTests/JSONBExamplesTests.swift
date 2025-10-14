import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

/// Tests for JSONB examples shown in README.md
@Suite("README Examples - JSONB Operations")
struct JSONBExamplesTests {

    // MARK: - Test Model

    @Table
    struct User {
        let id: Int
        var name: String

        @Column(as: Data.self)
        var settings: Data
    }

    // MARK: - JSONB Containment

    @Test("README Example: JSONB contains (@>) operator")
    func jsonbContains() async {
        await assertSQL(
            of: User.where { $0.settings.contains(["theme": "dark"]) }
        ) {
            """
            SELECT "users"."id", "users"."name", "users"."settings"
            FROM "users"
            WHERE ("users"."settings" @> '{"theme":"dark"}'::jsonb)
            """
        }
    }

    // MARK: - JSONB Path Operators

    @Test("README Example: JSONB get text field (->>) operator")
    func jsonbGetTextField() async {
        await assertSQL(
            of: User.where { $0.settings.fieldAsText("theme") == "dark" }
        ) {
            """
            SELECT "users"."id", "users"."name", "users"."settings"
            FROM "users"
            WHERE (("users"."settings" ->> 'theme')) = ('dark')
            """
        }
    }

    // MARK: - JSONB Key Existence

    @Test("README Example: JSONB has key (?) operator")
    func jsonbHasKey() async {
        await assertSQL(
            of: User.where { $0.settings.hasKey("notifications") }
        ) {
            """
            SELECT "users"."id", "users"."name", "users"."settings"
            FROM "users"
            WHERE ("users"."settings" ? 'notifications')
            """
        }
    }
}
