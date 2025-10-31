import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

// Test table for conversion tests
@Table("test_users")
struct TestUserForConversion {
  let id: UUID
  let name: String
  let email: String
  let age: Int

  @Column(as: Data.self)
  let tags: Data
}

extension SnapshotTests.JSONB {
  @Suite("Conversion") struct ConversionTests {

    // MARK: - to_jsonb / to_json Tests

    @Test func toJsonbOnScalar() {
      let query = TestUserForConversion.select { $0.age.toJsonb() }

      assertInlineSnapshot(of: query, as: .sql) {
        """
        SELECT to_jsonb("test_users"."age")
        FROM "test_users"
        """
      }
    }

    @Test func toJsonbOnString() {
      let query = TestUserForConversion.select { $0.name.toJsonb() }

      assertInlineSnapshot(of: query, as: .sql) {
        """
        SELECT to_jsonb("test_users"."name")
        FROM "test_users"
        """
      }
    }

    @Test func toJsonOnScalar() {
      let query = TestUserForConversion.select { $0.age.toJson() }

      assertInlineSnapshot(of: query, as: .sql) {
        """
        SELECT to_json("test_users"."age")
        FROM "test_users"
        """
      }
    }

    @Test func toJsonbMultipleColumns() {
      let query = TestUserForConversion.select {
        ($0.name, $0.age.toJsonb(), $0.email.toJsonb())
      }

      assertInlineSnapshot(of: query, as: .sql) {
        """
        SELECT "test_users"."name", to_jsonb("test_users"."age"), to_jsonb("test_users"."email")
        FROM "test_users"
        """
      }
    }

    // MARK: - jsonb_build_array Tests

    @Test func jsonbBuildArraySimple() {
      let query = TestUserForConversion.select {
        JSONB.Creation.buildArray($0.name, $0.email, $0.age)
      }

      assertInlineSnapshot(of: query, as: .sql) {
        """
        SELECT jsonb_build_array("test_users"."name", "test_users"."email", "test_users"."age")
        FROM "test_users"
        """
      }
    }

    @Test func jsonBuildArraySimple() {
      let query = TestUserForConversion.select {
        JSONB.Creation.buildArray($0.name, $0.email, $0.age)
      }

      assertInlineSnapshot(of: query, as: .sql) {
        """
        SELECT jsonb_build_array("test_users"."name", "test_users"."email", "test_users"."age")
        FROM "test_users"
        """
      }
    }

    @Test func jsonbBuildArraySingleValue() {
      let query = TestUserForConversion.select {
        JSONB.Creation.buildArray($0.name)
      }

      assertInlineSnapshot(of: query, as: .sql) {
        """
        SELECT jsonb_build_array("test_users"."name")
        FROM "test_users"
        """
      }
    }

    @Test func jsonbBuildArrayEmpty() {
      let query = TestUserForConversion.select { _ in
        JSONB.Creation.buildArray()
      }

      assertInlineSnapshot(of: query, as: .sql) {
        """
        SELECT jsonb_build_array()
        FROM "test_users"
        """
      }
    }

    @Test func jsonbBuildArrayNested() {
      let query = TestUserForConversion.select {
        JSONB.Creation.buildArray(
          $0.name,
          JSONB.Creation.buildArray($0.email, $0.age)
        )
      }

      assertInlineSnapshot(of: query, as: .sql) {
        """
        SELECT jsonb_build_array("test_users"."name", jsonb_build_array("test_users"."email", "test_users"."age"))
        FROM "test_users"
        """
      }
    }

    // MARK: - array_to_json Tests

    @Test func arrayToJson() {
      let query = TestUserForConversion.select { columns in
        JSONB.Creation.arrayToJson(columns.tags)
      }

      assertInlineSnapshot(of: query, as: .sql) {
        """
        SELECT array_to_json("test_users"."tags")
        FROM "test_users"
        """
      }
    }

    @Test func arrayToJsonWithAlias() {
      let query = TestUserForConversion.select { columns in
        (columns.name, JSONB.Creation.arrayToJson(columns.tags))
      }

      assertInlineSnapshot(of: query, as: .sql) {
        """
        SELECT "test_users"."name", array_to_json("test_users"."tags")
        FROM "test_users"
        """
      }
    }

    // MARK: - row_to_json Tests

    @Test func rowToJson() {
      let query = TestUserForConversion.select { _ in
        JSONB.Creation.rowToJson(TestUserForConversion.self)
      }

      assertInlineSnapshot(of: query, as: .sql) {
        """
        SELECT row_to_json("test_users".*)
        FROM "test_users"
        """
      }
    }

    @Test func rowToJsonWithColumns() {
      let query = TestUserForConversion.select { columns in
        (columns.id, JSONB.Creation.rowToJson(TestUserForConversion.self))
      }

      assertInlineSnapshot(of: query, as: .sql) {
        """
        SELECT "test_users"."id", row_to_json("test_users".*)
        FROM "test_users"
        """
      }
    }

    // MARK: - json_object Tests

    @Test func jsonObjectSimple() {
      let query = TestUserForConversion.select { _ in
        JSONB.Creation.object(
          keys: ["name", "email"], values: ["Alice", "alice@example.com"])
      }

      assertInlineSnapshot(of: query, as: .sql) {
        """
        SELECT json_object('{name,email}', '{Alice,alice@example.com}')
        FROM "test_users"
        """
      }
    }

    @Test func jsonObjectSinglePair() {
      let query = TestUserForConversion.select { _ in
        JSONB.Creation.object(keys: ["status"], values: ["active"])
      }

      assertInlineSnapshot(of: query, as: .sql) {
        """
        SELECT json_object('{status}', '{active}')
        FROM "test_users"
        """
      }
    }

    @Test func jsonObjectMultiplePairs() {
      let query = TestUserForConversion.select { _ in
        JSONB.Creation.object(
          keys: ["name", "email", "role", "status"],
          values: ["Bob", "bob@example.com", "admin", "active"]
        )
      }

      assertInlineSnapshot(of: query, as: .sql) {
        """
        SELECT json_object('{name,email,role,status}', '{Bob,bob@example.com,admin,active}')
        FROM "test_users"
        """
      }
    }

    // MARK: - Combined Operations Tests

    @Test func toJsonbWithBuildArray() {
      let query = TestUserForConversion.select {
        JSONB.Creation.buildArray($0.name.toJsonb(), $0.age.toJsonb())
      }

      assertInlineSnapshot(of: query, as: .sql) {
        """
        SELECT jsonb_build_array(to_jsonb("test_users"."name"), to_jsonb("test_users"."age"))
        FROM "test_users"
        """
      }
    }

    @Test func buildArrayWithRowToJson() {
      let query = TestUserForConversion.select { columns in
        JSONB.Creation.buildArray(
          columns.name, JSONB.Creation.rowToJson(TestUserForConversion.self))
      }

      assertInlineSnapshot(of: query, as: .sql) {
        """
        SELECT jsonb_build_array("test_users"."name", row_to_json("test_users".*))
        FROM "test_users"
        """
      }
    }

    @Test func complexConversionQuery() {
      let query = TestUserForConversion.select { columns in
        (
          columns.id,
          JSONB.Creation.buildArray(columns.name, columns.email),
          columns.age.toJsonb(),
          JSONB.Creation.arrayToJson(columns.tags)
        )
      }

      assertInlineSnapshot(of: query, as: .sql) {
        """
        SELECT "test_users"."id", jsonb_build_array("test_users"."name", "test_users"."email"), to_jsonb("test_users"."age"), array_to_json("test_users"."tags")
        FROM "test_users"
        """
      }
    }
  }
}
