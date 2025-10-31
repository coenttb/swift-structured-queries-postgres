import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

// Test table for index creation
@Table("test_users")
struct TestUserForIndexing {
  let id: UUID
  let name: String

  @Column(as: Data.self)
  let settings: Data

  @Column(as: Data.self)
  let metadata: Data
}

extension SnapshotTests.JSONB {
  @Suite("Indexing") struct IndexingTests {

    // MARK: - GIN Index Tests

    @Test func ginIndexCreationDefault() {
      let fragment = TestUserForIndexing.createGINIndex(on: \.settings)

      assertInlineSnapshot(of: SQLQueryExpression(fragment), as: .sql) {
        """
        CREATE INDEX "idx_test_users_settings_gin" ON "test_users" USING GIN ("settings")
        """
      }
    }

    @Test func ginIndexWithPathOps() {
      let fragment = TestUserForIndexing.createGINIndex(
        on: \.settings,
        operatorClass: .jsonb_path_ops
      )

      assertInlineSnapshot(of: SQLQueryExpression(fragment), as: .sql) {
        """
        CREATE INDEX "idx_test_users_settings_gin" ON "test_users" USING GIN ("settings" jsonb_path_ops)
        """
      }
    }

    @Test func ginIndexWithCustomName() {
      let fragment = TestUserForIndexing.createGINIndex(
        name: "custom_settings_idx",
        on: \.settings,
        operatorClass: .jsonb_path_ops
      )

      assertInlineSnapshot(of: SQLQueryExpression(fragment), as: .sql) {
        """
        CREATE INDEX "custom_settings_idx" ON "test_users" USING GIN ("settings" jsonb_path_ops)
        """
      }
    }

    @Test func ginIndexOnMetadataColumn() {
      let fragment = TestUserForIndexing.createGINIndex(
        on: \.metadata,
        operatorClass: .jsonb_ops
      )

      assertInlineSnapshot(of: SQLQueryExpression(fragment), as: .sql) {
        """
        CREATE INDEX "idx_test_users_metadata_gin" ON "test_users" USING GIN ("metadata")
        """
      }
    }

    // MARK: - GIN Path Index Tests

    @Test func ginIndexOnPath() {
      let fragment = TestUserForIndexing.createGINIndexPath(
        on: \.metadata,
        path: ["stats", "visits"]
      )

      assertInlineSnapshot(of: SQLQueryExpression(fragment), as: .sql) {
        """
        CREATE INDEX "idx_test_users_metadata_stats_visits_gin" ON "test_users" USING GIN (("metadata" #> '{stats,visits}'))
        """
      }
    }

    @Test func ginIndexOnPathWithPathOps() {
      let fragment = TestUserForIndexing.createGINIndexPath(
        on: \.metadata,
        path: ["user", "address", "city"],
        operatorClass: .jsonb_path_ops
      )

      assertInlineSnapshot(of: SQLQueryExpression(fragment), as: .sql) {
        """
        CREATE INDEX "idx_test_users_metadata_user_address_city_gin" ON "test_users" USING GIN (("metadata" #> '{user,address,city}') jsonb_path_ops)
        """
      }
    }

    @Test func ginIndexOnPathWithCustomName() {
      let fragment = TestUserForIndexing.createGINIndexPath(
        name: "custom_path_idx",
        on: \.settings,
        path: ["theme"]
      )

      assertInlineSnapshot(of: SQLQueryExpression(fragment), as: .sql) {
        """
        CREATE INDEX "custom_path_idx" ON "test_users" USING GIN (("settings" #> '{theme}'))
        """
      }
    }

    @Test func ginIndexOnNestedPath() {
      let fragment = TestUserForIndexing.createGINIndexPath(
        on: \.metadata,
        path: ["preferences", "ui", "theme", "color"]
      )

      assertInlineSnapshot(of: SQLQueryExpression(fragment), as: .sql) {
        """
        CREATE INDEX "idx_test_users_metadata_preferences_ui_theme_color_gin" ON "test_users" USING GIN (("metadata" #> '{preferences,ui,theme,color}'))
        """
      }
    }

    // MARK: - B-tree Index Tests

    @Test func btreeIndexCreation() {
      let fragment = TestUserForIndexing.createBTreeIndex(on: \.settings)

      assertInlineSnapshot(of: SQLQueryExpression(fragment), as: .sql) {
        """
        CREATE INDEX "idx_test_users_settings_btree" ON "test_users" USING BTREE ("settings")
        """
      }
    }

    @Test func btreeIndexWithCustomName() {
      let fragment = TestUserForIndexing.createBTreeIndex(
        name: "custom_btree_idx",
        on: \.metadata
      )

      assertInlineSnapshot(of: SQLQueryExpression(fragment), as: .sql) {
        """
        CREATE INDEX "custom_btree_idx" ON "test_users" USING BTREE ("metadata")
        """
      }
    }

    // MARK: - Drop Index Tests

    @Test func dropIndexDefault() {
      let fragment = TestUserForIndexing.dropIndex(name: "idx_test_users_settings_gin")

      assertInlineSnapshot(of: SQLQueryExpression(fragment), as: .sql) {
        """
        DROP INDEX IF EXISTS "idx_test_users_settings_gin"
        """
      }
    }

    @Test func dropIndexWithoutIfExists() {
      let fragment = TestUserForIndexing.dropIndex(
        name: "idx_test_users_settings_gin",
        ifExists: false
      )

      assertInlineSnapshot(of: SQLQueryExpression(fragment), as: .sql) {
        """
        DROP INDEX "idx_test_users_settings_gin"
        """
      }
    }

    // MARK: - Multiple Indexes

    @Test func multipleIndexesOnSameColumn() {
      // Can create both GIN and B-tree on same column for different query patterns
      let ginFragment = TestUserForIndexing.createGINIndex(
        name: "settings_gin",
        on: \.settings,
        operatorClass: .jsonb_path_ops
      )

      let btreeFragment = TestUserForIndexing.createBTreeIndex(
        name: "settings_btree",
        on: \.settings
      )

      assertInlineSnapshot(of: SQLQueryExpression(ginFragment), as: .sql) {
        """
        CREATE INDEX "settings_gin" ON "test_users" USING GIN ("settings" jsonb_path_ops)
        """
      }

      assertInlineSnapshot(of: SQLQueryExpression(btreeFragment), as: .sql) {
        """
        CREATE INDEX "settings_btree" ON "test_users" USING BTREE ("settings")
        """
      }
    }

    @Test func multiplePathIndexes() {
      let visitsIndex = TestUserForIndexing.createGINIndexPath(
        name: "idx_visits",
        on: \.metadata,
        path: ["stats", "visits"]
      )

      let postsIndex = TestUserForIndexing.createGINIndexPath(
        name: "idx_posts",
        on: \.metadata,
        path: ["stats", "posts"]
      )

      assertInlineSnapshot(of: SQLQueryExpression(visitsIndex), as: .sql) {
        """
        CREATE INDEX "idx_visits" ON "test_users" USING GIN (("metadata" #> '{stats,visits}'))
        """
      }

      assertInlineSnapshot(of: SQLQueryExpression(postsIndex), as: .sql) {
        """
        CREATE INDEX "idx_posts" ON "test_users" USING GIN (("metadata" #> '{stats,posts}'))
        """
      }
    }
  }
}
