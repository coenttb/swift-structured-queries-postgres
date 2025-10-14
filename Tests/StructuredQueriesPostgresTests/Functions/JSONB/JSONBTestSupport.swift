import Foundation
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

// JSONB test namespace
extension SnapshotTests {
    @Suite("JSONB") struct JSONB {}
}

// Shared test table with JSONB columns
@Table("test_users")
struct TestUser {
    let id: UUID
    let name: String

    @Column(as: Data.self)  // JSONB column
    let settings: Data

    @Column(as: Data.self)  // JSONB column
    let metadata: Data

    @Column(as: Data?.self)  // Optional JSONB column
    let preferences: Data?

    @Column(as: Data.self)  // JSONB array column
    let tags: Data
}
