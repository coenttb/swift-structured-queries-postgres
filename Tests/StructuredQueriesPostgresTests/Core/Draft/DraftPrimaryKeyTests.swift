import Foundation
import InlineSnapshotTesting
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

// Simple test table with UUID primary key
@Table("test_records")
struct SimpleRecord: Codable, Equatable, Identifiable {
    let id: UUID
    let name: String
    let value: Int
}

extension SnapshotTests {
    @Suite struct DraftPrimaryKeyTests {

        @Test func verifyDraftInsertSQL() {
            // Test that Draft with NULL id generates correct SQL
            let draft = SimpleRecord.Draft(
                name: "Test",
                value: 42
            )

            // This test verifies what SQL is actually generated
            // It should help us see if NULL is being included
            let insertStatement = SimpleRecord.insert { draft }

            // Print the actual SQL for debugging
            let query = insertStatement.query
            print("Generated SQL: \(query)")

            // Check if the SQL contains NULL (it shouldn't for PostgreSQL)
            // Convert to SQL string format
            let sql = "\(query)"
            #expect(!sql.contains("NULL"))
        }

        @Test func verifyDraftInsertWithConflict() {
            // Test Draft insert with ON CONFLICT
            let draft = SimpleRecord.Draft(
                name: "Test",
                value: 42
            )

            // This uses the new PrimaryKeyedTable.insert method we added
            let insertStatement = SimpleRecord.insert {
                draft
            } onConflict: { columns in
                (columns.name,)
            } doUpdate: { row, excluded in
                row.value = excluded.value
            }

            // Print for debugging
            let conflictQuery = insertStatement.query
            print("Generated SQL with conflict: \(conflictQuery)")

            // With the current implementation, id column is included with DEFAULT
            // when there's any ON CONFLICT with NULL primary keys (conservative approach)
            let conflictSql = "\(conflictQuery)"
            #expect(conflictSql.contains("\"id\""))
            #expect(conflictSql.contains("DEFAULT"))
            #expect(!conflictSql.contains("NULL"))
        }

        @Test func verifyExplicitIdDraft() {
            // Test Draft with explicit ID
            let explicitId = UUID(uuidString: "123e4567-e89b-12d3-a456-426614174000")!
            let draft = SimpleRecord.Draft(
                id: explicitId,
                name: "Test",
                value: 42
            )

            let insertStatement = SimpleRecord.insert { draft }

            let explicitQuery = insertStatement.query
            print("Generated SQL with explicit ID: \(explicitQuery)")

            // With explicit ID, the SQL should contain the "id" column
            let explicitSql = "\(explicitQuery)"
            #expect(explicitSql.contains("\"id\""))
            // And it should contain the UUID value, not NULL
            #expect(explicitSql.contains("123e4567"))
        }
    }
}
