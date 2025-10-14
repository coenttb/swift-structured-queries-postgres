import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

/// Tests for JSONB examples shown in README.md
@Suite("README Examples - JSONB Operations")
struct JSONBExamplesTests {

    // MARK: - Test Models

    struct UserSettings: Codable, Equatable {
        var theme: String
        var notifications: Bool
        var language: String
    }

    @Table
    struct User {
        let id: Int
        var name: String
        var settings: UserSettings
        var metadata: [String: String]
    }

    // MARK: - JSONB Containment Operators

    @Test("README Example: JSONB contains (@>) operator")
    func jsonbContains() async {
        let searchSettings = UserSettings(
            theme: "dark",
            notifications: true,
            language: "en"
        )

        await assertSQL(
            of: User.where { $0.settings.contains(searchSettings) }
        ) {
            """
            SELECT "users"."id", "users"."name", "users"."settings", "users"."metadata"
            FROM "users"
            WHERE ("users"."settings") @> ('{"theme":"dark","notifications":true,"language":"en"}')
            """
        }
    }

    @Test("README Example: JSONB is contained by (<@) operator")
    func jsonbIsContainedBy() async {
        let supersetSettings = UserSettings(
            theme: "dark",
            notifications: true,
            language: "en"
        )

        await assertSQL(
            of: User.where { $0.settings.isContainedBy(supersetSettings) }
        ) {
            """
            SELECT "users"."id", "users"."name", "users"."settings", "users"."metadata"
            FROM "users"
            WHERE ("users"."settings") <@ ('{"theme":"dark","notifications":true,"language":"en"}')
            """
        }
    }

    @Test("README Example: JSONB has key (?) operator")
    func jsonbHasKey() async {
        await assertSQL(
            of: User.where { $0.metadata.hasKey("subscriptionTier") }
        ) {
            """
            SELECT "users"."id", "users"."name", "users"."settings", "users"."metadata"
            FROM "users"
            WHERE ("users"."metadata") ? ('subscriptionTier')
            """
        }
    }

    @Test("README Example: JSONB has any key (?|) operator")
    func jsonbHasAnyKey() async {
        await assertSQL(
            of: User.where { $0.metadata.hasAnyKey(["premium", "pro", "enterprise"]) }
        ) {
            """
            SELECT "users"."id", "users"."name", "users"."settings", "users"."metadata"
            FROM "users"
            WHERE ("users"."metadata") ?| (ARRAY['premium', 'pro', 'enterprise'])
            """
        }
    }

    @Test("README Example: JSONB has all keys (?&) operator")
    func jsonbHasAllKeys() async {
        await assertSQL(
            of: User.where { $0.metadata.hasAllKeys(["createdAt", "updatedAt"]) }
        ) {
            """
            SELECT "users"."id", "users"."name", "users"."settings", "users"."metadata"
            FROM "users"
            WHERE ("users"."metadata") ?& (ARRAY['createdAt', 'updatedAt'])
            """
        }
    }

    // MARK: - JSONB Path Operators

    @Test("README Example: JSONB get text field (->>) operator")
    func jsonbGetTextField() async {
        await assertSQL(
            of: User
                .select { $0.metadata.getText("subscriptionTier") }
                .where { $0.metadata.getText("status") == "active" }
        ) {
            """
            SELECT ("users"."metadata") ->> ('subscriptionTier')
            FROM "users"
            WHERE (("users"."metadata") ->> ('status')) = ('active')
            """
        }
    }

    @Test("README Example: JSONB get JSON object (->) operator")
    func jsonbGetJsonObject() async {
        await assertSQL(
            of: User.select { $0.metadata.get("preferences") }
        ) {
            """
            SELECT ("users"."metadata") -> ('preferences')
            FROM "users"
            """
        }
    }

    @Test("README Example: JSONB path extraction (#>) operator")
    func jsonbPathExtraction() async {
        await assertSQL(
            of: User.select { $0.metadata.getPath(["user", "profile", "avatar"]) }
        ) {
            """
            SELECT ("users"."metadata") #> (ARRAY['user', 'profile', 'avatar'])
            FROM "users"
            """
        }
    }

    @Test("README Example: JSONB text path extraction (#>>) operator")
    func jsonbTextPathExtraction() async {
        await assertSQL(
            of: User.select { $0.metadata.getTextPath(["user", "profile", "name"]) }
        ) {
            """
            SELECT ("users"."metadata") #>> (ARRAY['user', 'profile', 'name'])
            FROM "users"
            """
        }
    }

    // MARK: - JSONB Functions

    @Test("README Example: JSONB array length")
    func jsonbArrayLength() async {
        await assertSQL(
            of: User.select { $0.metadata.jsonbArrayLength() }
        ) {
            """
            SELECT jsonb_array_length("users"."metadata")
            FROM "users"
            """
        }
    }

    @Test("README Example: JSONB object keys")
    func jsonbObjectKeys() async {
        await assertSQL(
            of: User.select { $0.metadata.jsonbObjectKeys() }
        ) {
            """
            SELECT jsonb_object_keys("users"."metadata")
            FROM "users"
            """
        }
    }

    @Test("README Example: JSONB pretty print")
    func jsonbPretty() async {
        await assertSQL(
            of: User.select { $0.settings.jsonbPretty() }
        ) {
            """
            SELECT jsonb_pretty("users"."settings")
            FROM "users"
            """
        }
    }

    // MARK: - JSONB Aggregation

    @Test("README Example: JSONB aggregation with jsonb_agg")
    func jsonbAggregation() async {
        await assertSQL(
            of: User
                .select { $0.settings.jsonbAgg() }
        ) {
            """
            SELECT jsonb_agg("users"."settings")
            FROM "users"
            """
        }
    }

    @Test("README Example: JSONB object aggregation with jsonb_object_agg")
    func jsonbObjectAggregation() async {
        await assertSQL(
            of: User.select { jsonbObjectAgg($0.name, $0.settings) }
        ) {
            """
            SELECT jsonb_object_agg("users"."name", "users"."settings")
            FROM "users"
            """
        }
    }

    // MARK: - GIN Indexing

    @Test("README Example: Create GIN index for JSONB containment")
    func createGinIndex() async {
        await assertSQL(
            of: User.createGINIndex(on: \.settings)
        ) {
            """
            CREATE INDEX "users_settings_gin_idx" ON "users" USING GIN ("settings")
            """
        }
    }

    @Test("README Example: Create GIN index with jsonb_path_ops")
    func createGinIndexPathOps() async {
        await assertSQL(
            of: User.createGINIndex(on: \.settings, operatorClass: .jsonb_path_ops)
        ) {
            """
            CREATE INDEX "users_settings_gin_idx" ON "users" USING GIN ("settings" jsonb_path_ops)
            """
        }
    }

    @Test("README Example: Create named GIN index")
    func createNamedGinIndex() async {
        await assertSQL(
            of: User.createGINIndex(
                named: "idx_user_settings_gin",
                on: \.settings
            )
        ) {
            """
            CREATE INDEX "idx_user_settings_gin" ON "users" USING GIN ("settings")
            """
        }
    }
}
