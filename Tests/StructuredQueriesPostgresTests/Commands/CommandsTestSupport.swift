import Foundation
import StructuredQueriesPostgres
import StructuredQueriesPostgresTestSupport
import Testing

// Commands test namespace
extension SnapshotTests {
    @Suite("Commands") struct Commands {
        @Suite("Select") struct Select {}
    }
}
