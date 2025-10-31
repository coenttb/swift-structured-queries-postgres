import Foundation
import StructuredQueriesPostgres

// Simple compile-time test to verify JSONB types are available
struct CompileTest {
  // Test that array types have JSONB
  typealias StringArrayJSONB = [String].JSONB
  typealias IntArrayJSONB = [Int].JSONB

  // Test that dictionary types have JSONB
  typealias StringDictJSONB = [String: String].JSONB
  typealias MixedDictJSONB = [String: Int].JSONB

  // Test optional support
  typealias OptionalArrayJSONB = [String].JSONB?
  typealias OptionalDictJSONB = [String: String].JSONB?

  // Test with @Table and @Column
  @Table("test_table")
  struct TestTable {
    let id: Int

    @Column(as: [String].JSONB.self)
    let features: [String]

    @Column(as: [String: String].JSONB.self)
    let metadata: [String: String]

    @Column(as: [Int].JSONB.self)
    let numbers: [Int]

    @Column(as: [String: Int].JSONB.self)
    let counts: [String: Int]
  }
}
