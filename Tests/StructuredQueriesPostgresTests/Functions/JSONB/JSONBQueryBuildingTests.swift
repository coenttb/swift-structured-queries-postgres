import Foundation
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

/// Tests for JSONB query building (SQL generation, not database execution)
/// These tests verify that JSONB types correctly generate SQL without executing queries
extension SnapshotTests.JSONB {
    @Suite("Query Building") struct QueryBuildingTests {

        @Test("JSONB type alias exists")
        func testJSONBTypeAlias() {
            // Test that array types have JSONB
            let _: [String].JSONB.Type = [String].JSONB.self
            let _: [Int].JSONB.Type = [Int].JSONB.self

            // Test that dictionary types have JSONB
            let _: [String: String].JSONB.Type = [String: String].JSONB.self
            let _: [String: Int].JSONB.Type = [String: Int].JSONB.self

            #expect(Bool(true))  // If we get here, the types exist
        }

        @Test("JSONB QueryBinding")
        func testJSONBBinding() {
            // Test array binding
            let arrayRep = [String].JSONB(queryOutput: ["feature1", "feature2"])
            let arrayBinding = arrayRep.queryBinding

            switch arrayBinding {
            case .jsonb(let data):
                let decoded = String(decoding: data, as: UTF8.self)
                #expect(decoded.contains("feature1"))
                #expect(decoded.contains("feature2"))
            default:
                Issue.record("Expected .jsonb binding, got \(arrayBinding)")
            }

            // Test dictionary binding
            let dictRep = [String: String].JSONB(queryOutput: ["key1": "value1", "key2": "value2"])
            let dictBinding = dictRep.queryBinding

            switch dictBinding {
            case .jsonb(let data):
                let decoded = String(decoding: data, as: UTF8.self)
                #expect(decoded.contains("key1"))
                #expect(decoded.contains("value1"))
            default:
                Issue.record("Expected .jsonb binding, got \(dictBinding)")
            }
        }

        @Test("Table with JSONB columns generates INSERT statement")
        func testTableWithJSONB() {
            // Test insert statement generation (no execution)
            let insertStatement = TestTable.insert {
                TestTable(
                    id: 1,
                    features: ["feature1", "feature2"],
                    metadata: ["key": "value"]
                )
            }

            // The statement should compile and be valid (type check only)
            _ = insertStatement
        }

        @Test("QueryFragment handles JSONB binding")
        func testQueryFragmentJSONB() {
            // Create a query fragment with JSONB binding
            let features = ["feature1", "feature2"]
            let jsonbRep = [String].JSONB(queryOutput: features)
            let binding = jsonbRep.queryBinding

            let fragment: QueryFragment = """
                    INSERT INTO test (data) VALUES (\(binding))
                """

            // Verify the fragment is created correctly (type check only)
            // The actual PostgresStatement conversion happens in swift-records
            _ = fragment
        }
    }
}

// Test table definition
@Table("test_jsonb")
private struct TestTable {
    let id: Int
    @Column(as: [String].JSONB.self)
    let features: [String]
    @Column(as: [String: String].JSONB.self)
    let metadata: [String: String]
}
